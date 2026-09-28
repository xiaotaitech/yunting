#!/usr/bin/env node
// 排查：App 在读 ID3 标签时对 dlink 发 Range 请求，百度回 403，
// 但 verify 里的 Range 测试是 206 成功的。差别到底在哪？
//
// 逐个变量对比：Range 大小、是否先完整 GET 过、UA、是否跟随重定向。
import fs from 'node:fs';
import path from 'node:path';
import { config, requireCredentials } from './config.mjs';
import { listDir, fileMetas, withToken, PAN_UA } from './baidu.mjs';

requireCredentials();

const token = JSON.parse(
  fs.readFileSync(path.join(config.root, '.token.json'), 'utf8'));

const dir = process.argv[2];
if (!dir) {
  console.error('用法：node src/probe-range.mjs "/某个含音频的目录"');
  process.exit(1);
}

const listing = await listDir(token.access_token, dir);
const audio = (listing.list || []).find(
  (e) => e.isdir === 0 && /\.(mp3|m4a|flac)$/i.test(e.server_filename));
if (!audio) {
  console.error('该目录下没有音频文件');
  process.exit(1);
}
console.log(`测试文件：${audio.server_filename}（${(audio.size / 1048576).toFixed(1)} MB）\n`);

/** 每次都重新取一个全新的 dlink，排除"链接被用过"这个变量。 */
async function freshDlink() {
  const metas = await fileMetas(token.access_token, [audio.fs_id]);
  return withToken(metas.list[0].dlink, token.access_token);
}

async function attempt(label, { range, ua = PAN_UA, warmup = false }) {
  const url = await freshDlink();
  try {
    if (warmup) {
      // 先完整 GET 一下（只读几个字节就断开），模拟 verify 的顺序
      const w = await fetch(url, { headers: { 'User-Agent': ua }, redirect: 'follow' });
      await w.body?.cancel();
    }
    const headers = { 'User-Agent': ua };
    if (range) headers.Range = range;
    const res = await fetch(url, { headers, redirect: 'follow' });
    const len = res.headers.get('content-length');
    console.log(`  ${res.status === 200 || res.status === 206 ? 'OK  ' : 'FAIL'} ${label}`);
    console.log(`       HTTP ${res.status}`
      + `${len ? ` · ${len} 字节` : ''}`
      + `${res.headers.get('content-range') ? ` · ${res.headers.get('content-range')}` : ''}`);
    await res.body?.cancel();
    return res.status;
  } catch (e) {
    console.log(`  FAIL ${label}\n       异常：${e.message}`);
    return -1;
  }
}

console.log('逐项对比（每次都用全新的 dlink）：\n');

await attempt('无 Range，完整 GET', {});
await attempt('Range: bytes=1024-2047（verify 用的）', { range: 'bytes=1024-2047' });
await attempt('Range: bytes=0-65535（App 读 ID3 用的）', { range: 'bytes=0-65535' });
await attempt('Range: bytes=0-1023', { range: 'bytes=0-1023' });
await attempt('Range: bytes=0-65535 + 先完整 GET 过', { range: 'bytes=0-65535', warmup: true });
await attempt('Range: bytes=0-65535 + 浏览器 UA', { range: 'bytes=0-65535', ua: 'Mozilla/5.0' });

console.log('\n如果只有 bytes=0-... 失败，说明百度不接受从 0 开始的 Range；');
console.log('如果都成功，那问题在 Dart 侧（http 包的重定向或 header 处理）。');
