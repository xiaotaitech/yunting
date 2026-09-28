#!/usr/bin/env node
// 找出网盘里最大的几个音频文件。
//
// 用途很具体：Phase 0 的 UA 对照测试需要一个 >20MB 的文件才有意义——
// 小文件百度不带 UA 也放行，验不出「UA 是硬性要求」这条结论。
import fs from 'node:fs';
import path from 'node:path';
import { config, requireCredentials } from './config.mjs';
import { refreshToken, listDir } from './baidu.mjs';

requireCredentials();

const TOKEN_FILE = path.join(config.root, '.token.json');
const AUDIO_EXT = ['.mp3', '.m4a', '.m4b', '.aac', '.flac', '.ogg', '.wav', '.wma', '.opus'];
const isAudio = (name) => AUDIO_EXT.includes(path.extname(name).toLowerCase());
const fmt = (n) => (n > 1 << 20 ? `${(n / (1 << 20)).toFixed(1)} MB` : `${(n / 1024).toFixed(0)} KB`);

async function loadToken() {
  if (!fs.existsSync(TOKEN_FILE)) {
    console.error('没有 .token.json，请先跑 npm run verify 完成一次授权');
    process.exit(1);
  }
  const t = JSON.parse(fs.readFileSync(TOKEN_FILE, 'utf8'));
  if (t.expires_at && t.expires_at - Date.now() > 60_000) return t;
  console.log('令牌已过期，正在刷新…');
  const fresh = await refreshToken(config.appKey, config.secretKey, t.refresh_token);
  const saved = { ...fresh, expires_at: Date.now() + (fresh.expires_in ?? 0) * 1000 };
  fs.writeFileSync(TOKEN_FILE, JSON.stringify(saved, null, 2));
  return saved;
}

/** 广度优先遍历，深度与请求数都设上限，避免把整个网盘扫一遍。 */
async function scan(token, { maxDepth = 4, maxRequests = 120 } = {}) {
  const found = [];
  const queue = [{ dir: '/', depth: 0 }];
  const seen = new Set();
  let requests = 0;

  while (queue.length && requests < maxRequests) {
    const { dir, depth } = queue.shift();
    if (seen.has(dir) || depth > maxDepth) continue;
    seen.add(dir);

    let listing;
    try {
      listing = await listDir(token.access_token, dir);
      requests++;
    } catch {
      continue;
    }

    for (const e of listing.list || []) {
      if (e.isdir === 1) {
        queue.push({ dir: e.path, depth: depth + 1 });
      } else if (isAudio(e.server_filename)) {
        found.push({ path: e.path, dir, size: e.size, name: e.server_filename });
      }
    }
    process.stdout.write(`\r  已扫 ${requests} 个目录，找到 ${found.length} 个音频…`);
  }
  process.stdout.write('\n');
  return found;
}

const token = await loadToken();
console.log('正在扫描网盘中的音频文件…');
const files = await scan(token);

if (!files.length) {
  console.log('没找到音频文件。');
  process.exit(0);
}

files.sort((a, b) => b.size - a.size);
const big = files.filter((f) => f.size > 20 * 1024 * 1024);

console.log(`\n共 ${files.length} 个音频，其中 ${big.length} 个超过 20MB。\n`);
console.log('最大的几个：');
for (const f of files.slice(0, 8)) {
  const mark = f.size > 20 * 1024 * 1024 ? ' ← 可用于 UA 测试' : '';
  console.log(`  ${fmt(f.size).padStart(9)}  ${f.path}${mark}`);
}

if (big.length) {
  console.log(`\n用这个目录跑 UA 对照测试：\n  npm run verify -- "${big[0].dir}"`);
} else {
  console.log('\n网盘里没有超过 20MB 的音频，无法验证「大文件必须带 UA」这条。');
}
