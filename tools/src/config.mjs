import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');

/** 极简 .env 读取，避免为一个键值文件引入依赖。 */
function loadDotEnv() {
  const file = path.join(root, '.env');
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = /^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/.exec(line);
    if (!m) continue;
    const value = m[2].replace(/^["']|["']$/g, '');
    if (!(m[1] in process.env)) process.env[m[1]] = value;
  }
}
loadDotEnv();

export const config = {
  appKey: process.env.BAIDU_APP_KEY || '',
  secretKey: process.env.BAIDU_SECRET_KEY || '',
  port: Number(process.env.PROXY_PORT || 8787),
  host: process.env.PROXY_HOST || '0.0.0.0',
  root,
};

export function requireCredentials() {
  if (!config.appKey || !config.secretKey
      || config.appKey.startsWith('your_') || config.secretKey.startsWith('your_')) {
    console.error(
      '\n缺少百度网盘开放平台凭证。\n'
      + '  1. 打开 https://pan.baidu.com/union/console\n'
      + '     登录百度账号 → 实名认证 → 创建应用（软件类别）→ 等审核通过\n'
      + '     在应用详情页记下 AppKey 与 SecretKey\n'
      + '  2. 复制 tools/.env.example 为 tools/.env\n'
      + '  3. 填入 BAIDU_APP_KEY 与 BAIDU_SECRET_KEY\n'
      + '\n  还没申请到？先用演示模式试完整流程：./run-emulator.sh demo\n');
    process.exit(1);
  }
}
