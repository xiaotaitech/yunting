#!/usr/bin/env node
// Phase 0 链路验证（openspec tasks.md 第 0 组）。
// 这是整个项目的前提验证：授权 → 列目录 → 取 dlink → 带 UA 下载 → Range → 测速。
// 跑不通这一条，客户端做得再好也没有意义。
import fs from 'node:fs';
import path from 'node:path';
import { stdout } from 'node:process';
import { config, requireCredentials } from './config.mjs';
import {
  deviceCodeStart, deviceCodePoll, refreshToken, userInfo, listDir,
  fileMetas, withToken, PAN_UA, redact, redactUrl,
} from './baidu.mjs';

requireCredentials();

const TOKEN_FILE = path.join(config.root, '.token.json');
const AUDIO_EXT = ['.mp3', '.m4a', '.m4b', '.aac', '.flac', '.ogg', '.wav', '.wma', '.opus'];
const isAudio = (name) => AUDIO_EXT.includes(path.extname(name).toLowerCase());

const results = [];
function record(step, ok, detail) {
  results.push({ step, ok, detail });
  console.log(`  ${ok ? 'PASS' : 'FAIL'}  ${step}${detail ? ` — ${detail}` : ''}`);
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const fmtBytes = (n) => (n > 1 << 30 ? `${(n / (1 << 30)).toFixed(2)} GB`
  : n > 1 << 20 ? `${(n / (1 << 20)).toFixed(1)} MB` : `${(n / 1024).toFixed(0)} KB`);

// ------------------------------------------------------------ 授权

async function loadToken() {
  if (!fs.existsSync(TOKEN_FILE)) return null;
  try {
    const t = JSON.parse(fs.readFileSync(TOKEN_FILE, 'utf8'));
    if (t.expires_at && t.expires_at - Date.now() > 60_000) return t;
    if (t.refresh_token) {
      console.log('本地令牌已过期，正在刷新…');
      const fresh = await refreshToken(config.appKey, config.secretKey, t.refresh_token);
      return saveToken(fresh);
    }
  } catch { /* 落盘令牌损坏时直接重新授权 */ }
  return null;
}

function saveToken(token) {
  const t = { ...token, expires_at: Date.now() + (token.expires_in ?? 0) * 1000 };
  fs.writeFileSync(TOKEN_FILE, JSON.stringify(t, null, 2));
  return t;
}

async function authorize() {
  const cached = await loadToken();
  if (cached) {
    record('0.3a 复用本地令牌', true, `access_token=${redact(cached.access_token)}`);
    return cached;
  }
  const d = await deviceCodeStart(config.appKey);
  console.log('\n请在浏览器打开下面的地址完成授权：');
  console.log(`  ${d.verification_url}`);
  console.log(`  用户码：${d.user_code}`);
  if (d.qrcode_url) console.log(`  或扫码：${d.qrcode_url}`);
  console.log('\n等待授权中…（授权后本工具会自动继续）');

  const deadline = Date.now() + (d.expires_in ?? 300) * 1000;
  let interval = (d.interval ?? 5) * 1000;
  while (Date.now() < deadline) {
    await sleep(interval);
    const r = await deviceCodePoll(config.appKey, config.secretKey, d.device_code);
    if (r.status === 'ok') {
      record('0.3a 设备码授权', true, `scope=${r.token.scope}`);
      return saveToken(r.token);
    }
    if (r.status === 'slow_down') interval += 2000;
    if (r.status === 'denied') throw new Error('用户拒绝了授权');
    if (r.status === 'expired') throw new Error('设备码已过期，请重新运行');
    stdout.write('.');
  }
  throw new Error('等待授权超时');
}

// ------------------------------------------------------------ 找一个音频文件

/** 广度优先找第一个音频文件所在的目录，深度受限以免遍历整个网盘。 */
async function findAudioFolder(token, startDir, maxDepth = 3) {
  const queue = [{ dir: startDir, depth: 0 }];
  const visited = new Set();
  while (queue.length) {
    const { dir, depth } = queue.shift();
    if (visited.has(dir) || depth > maxDepth) continue;
    visited.add(dir);
    let listing;
    try {
      listing = await listDir(token.access_token, dir);
    } catch {
      continue;
    }
    const entries = listing.list || [];
    const audios = entries.filter((e) => e.isdir === 0 && isAudio(e.server_filename));
    if (audios.length) return { dir, audios, all: entries };
    for (const e of entries) {
      if (e.isdir === 1) queue.push({ dir: e.path, depth: depth + 1 });
    }
  }
  return null;
}

/**
 * Git Bash / MSYS 会把以 `/` 开头的命令行参数当成 Unix 路径，
 * 自动改写成 Windows 路径——`/我的资源/x` 会变成
 * `C:/Program Files/Git/我的资源/x`，然后百度回一个 errno=-7，
 * 看上去像是权限问题，其实是参数在进程之前就被改掉了。
 * 与其让人对着 errno 猜，不如识别出来直接说怎么办。
 */
function checkPathArg(arg) {
  if (!arg) return arg;
  const mangled = /^[A-Za-z]:[\\/]/.test(arg) || arg.includes('Program Files');
  if (!mangled) return arg;

  const guess = arg.replace(/^.*?Program Files[\\/]Git/i, '').replace(/\\/g, '/');
  console.error(
    '\n路径被 Git Bash 改写了：\n'
    + `  你传入的： ${arg}\n`
    + `  原本应是： ${guess || '/...'}\n\n`
    + '这是 MSYS 的路径转换，不是百度的问题。加个前缀即可：\n'
    + `  MSYS_NO_PATHCONV=1 npm run verify -- "${guess || '/你的目录'}"\n\n`
    + '（PowerShell 与 cmd 没有这个问题，可以直接传。）\n');
  process.exit(1);
}

// ------------------------------------------------------------ 主流程

async function main() {
  console.log('\n=== 百度网盘听书 App · Phase 0 链路验证 ===\n');

  const token = await authorize();

  // --- 用户信息
  try {
    const u = await userInfo(token.access_token);
    record('0.3b 读取用户信息', true, `${u.baidu_name || u.netdisk_name}（vip_type=${u.vip_type}）`);
    if (Number(u.vip_type) === 0) {
      console.log('        提示：非会员账号，下载带宽受限，测速结果会偏低（design.md D6）');
    }
  } catch (e) {
    record('0.3b 读取用户信息', false, e.message);
  }

  // --- 列目录
  let target;
  try {
    const root = await listDir(token.access_token, '/');
    record('0.3c 列出根目录', true, `${(root.list || []).length} 个条目`);
    const argDir = checkPathArg(process.argv[2]);
    if (argDir) {
      const listing = await listDir(token.access_token, argDir);
      const audios = (listing.list || []).filter((e) => e.isdir === 0 && isAudio(e.server_filename));
      if (!audios.length) throw new Error(`指定目录 ${argDir} 下没有音频文件`);
      target = { dir: argDir, audios };
    } else {
      console.log('        正在查找含音频文件的目录…');
      target = await findAudioFolder(token, '/');
    }
    if (!target) {
      record('0.3d 定位音频文件', false, '网盘里没找到音频文件；可传入目录：npm run verify -- "/有声书/某本书"');
      return report();
    }
    record('0.3d 定位音频文件', true, `${target.dir}（${target.audios.length} 个音频）`);
  } catch (e) {
    record('0.3c 列出目录', false, e.message);
    return report();
  }

  // 挑最大的一个文件来验证「>20MB 必须带 UA」这条约束
  const pick = target.audios.slice().sort((a, b) => b.size - a.size)[0];
  console.log(`\n  测试文件：${pick.server_filename}（${fmtBytes(pick.size)}）`);
  if (pick.size < 20 * 1024 * 1024) {
    console.log('        注意：该文件小于 20MB，不足以验证大文件的 UA 强制要求');
  }

  // --- 取 dlink
  let dlink;
  try {
    const metas = await fileMetas(token.access_token, [pick.fs_id]);
    dlink = metas.list?.[0]?.dlink;
    if (!dlink) throw new Error('filemetas 未返回 dlink（检查应用是否已开通下载权限）');
    record('0.3e 取得 dlink', true, `${redactUrl(dlink).slice(0, 70)}…`);
  } catch (e) {
    record('0.3e 取得 dlink', false, e.message);
    return report();
  }

  const url = withToken(dlink, token.access_token);

  // --- 关键验证：带 UA vs 不带 UA
  try {
    const res = await fetch(url, { headers: { 'User-Agent': PAN_UA }, redirect: 'follow' });
    const len = res.headers.get('content-length');
    record('0.3f 带 User-Agent: pan.baidu.com 下载', res.ok,
      `HTTP ${res.status}${len ? ` · 长度 ${fmtBytes(Number(len))}` : ''}${res.redirected ? ' · 发生过 302 跳转' : ''}`);
    await res.body?.cancel();
  } catch (e) {
    record('0.3f 带 UA 下载', false, e.message);
  }

  // 对照组：拿浏览器 UA 请求同一个 dlink。
  // 网上普遍说「>20MB 不带 pan.baidu.com 的 UA 会被拒」，但那是二手信息。
  // 这一步就是用来证伪或证实它的——结论以实测为准，不要预设。
  const bigEnough = pick.size > 20 * 1024 * 1024;
  try {
    const res = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' }, redirect: 'follow' });
    let note;
    if (!res.ok) {
      note = `HTTP ${res.status} 被拒 → 证实 UA 是硬性要求`;
    } else if (bigEnough) {
      note = `HTTP ${res.status} 放行（${fmtBytes(pick.size)} > 20MB）`
        + ' → 本次实测未见 UA 限制；代码仍带 UA 作为防御';
    } else {
      note = `HTTP ${res.status} 放行，但文件仅 ${fmtBytes(pick.size)}，`
        + '未达常说的 20MB 门槛，这一条没验出结论';
    }
    record('0.3g 不带指定 UA 的对照组', true, note);
    await res.body?.cancel();
  } catch (e) {
    record('0.3g 不带指定 UA 的对照组', true, `请求失败：${e.message}（等同于被拒）`);
  }

  // --- Range 支持（seek 与断点续传的前提）
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': PAN_UA, Range: 'bytes=1024-2047' },
      redirect: 'follow',
    });
    const buf = Buffer.from(await res.arrayBuffer());
    const ok = res.status === 206 && buf.length === 1024;
    record('0.4 HTTP Range 断点续传', ok,
      `HTTP ${res.status} · 收到 ${buf.length} 字节 · content-range=${res.headers.get('content-range') || '无'}`);
  } catch (e) {
    record('0.4 HTTP Range 断点续传', false, e.message);
  }

  // --- 测速：决定默认预缓冲窗口与「建议下载」阈值
  try {
    const started = Date.now();
    const res = await fetch(url, { headers: { 'User-Agent': PAN_UA }, redirect: 'follow' });
    let got = 0;
    const reader = res.body.getReader();
    while (Date.now() - started < 6000) {
      const { done, value } = await reader.read();
      if (done) break;
      got += value.length;
    }
    await reader.cancel();
    const secs = (Date.now() - started) / 1000;
    const kbps = got / 1024 / secs;
    record('0.5 实测下行速率', true, `${kbps.toFixed(0)} KB/s（约 ${(kbps * 8).toFixed(0)} kbps）`);
    // 阈值按实际需求算，别拍脑袋：128kbps 的有声书 = 16 KB/s，
    // 留 1.5 倍余量应付抖动就是 24 KB/s。原来写的 40 KB/s 太严，
    // 会把 38 KB/s（已是需求的两倍多）误判成「速率偏低」。
    const needKbps = 128 / 8; // 16 KB/s
    const ratio = kbps / needKbps;
    console.log(`        结论：${ratio >= 1.5
      ? `是 128kbps 有声书所需带宽的 ${ratio.toFixed(1)} 倍，流播优先可行`
      : ratio >= 1
        ? '刚够 128kbps 流播，余量不多，弱网时会缓冲'
        : '不足以流播 128kbps，建议以「先下载后听」为主（design.md D6）'}`);
  } catch (e) {
    record('0.5 实测下行速率', false, e.message);
  }

  report();
}

function report() {
  console.log('\n=== 结论 ===');
  const failed = results.filter((r) => !r.ok);
  for (const r of results) console.log(`  ${r.ok ? 'PASS' : 'FAIL'}  ${r.step}`);
  if (failed.length === 0) {
    console.log('\n链路全通。tasks.md 第 0 组前置验证可以勾掉，客户端联调无阻塞。\n');
  } else {
    console.log(`\n有 ${failed.length} 项未通过，需要先解决：`);
    for (const r of failed) console.log(`  - ${r.step}：${r.detail}`);
    console.log();
  }
}

main().catch((err) => {
  console.error(`\n验证中断：${err.message}\n`);
  process.exit(1);
});
