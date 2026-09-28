#!/usr/bin/env node
// 唯一的服务端组件（openspec design.md D2）。
// 职责边界：只代理「凭证」，不代理「数据」。
//   - SecretKey 只存在于本进程的环境变量里，绝不下发给客户端
//   - 不接触任何文件元数据、不缓存任何音频、日志不记录用户文件路径
import http from 'node:http';
import { config, requireCredentials } from './config.mjs';
import {
  deviceCodeStart, deviceCodePoll, exchangeCode, refreshToken,
  authorizeUrl, redact, BaiduError,
} from './baidu.mjs';

requireCredentials();

const json = (res, status, body) => {
  const payload = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(payload),
    'Cache-Control': 'no-store',
  });
  res.end(payload);
};

async function readBody(req) {
  const chunks = [];
  let size = 0;
  for await (const c of req) {
    size += c.length;
    if (size > 64 * 1024) throw new Error('请求体过大');
    chunks.push(c);
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  return raw ? JSON.parse(raw) : {};
}

/** 令牌响应统一收口，确保 SecretKey / AppKey 不会随响应外泄。 */
function tokenResponse(token) {
  return {
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    expires_in: token.expires_in,
    scope: token.scope,
  };
}

function errorResponse(res, err) {
  if (err instanceof BaiduError) {
    const status = err.kind === 'auth_expired' || err.kind === 'scope_invalid' ? 401
      : err.kind === 'rate_limited' ? 429 : 502;
    return json(res, status, { error: err.kind, message: err.message });
  }
  return json(res, 400, { error: 'bad_request', message: err.message });
}

const routes = {
  'GET /health': async (_req, res) => json(res, 200, { ok: true, appKey: redact(config.appKey) }),

  // 设备码流程：不需要回调域名，最适合移动端与本地联调
  'POST /oauth/device/start': async (_req, res) => {
    const d = await deviceCodeStart(config.appKey);
    console.log(`[device/start] user_code=${d.user_code} 待用户在 ${d.verification_url} 授权`);
    json(res, 200, {
      device_code: d.device_code,
      user_code: d.user_code,
      verification_url: d.verification_url,
      qrcode_url: d.qrcode_url,
      expires_in: d.expires_in,
      interval: d.interval,
    });
  },

  'POST /oauth/device/poll': async (req, res) => {
    const { device_code } = await readBody(req);
    if (!device_code) throw new Error('缺少 device_code');
    const r = await deviceCodePoll(config.appKey, config.secretKey, device_code);
    if (r.status === 'ok') {
      console.log(`[device/poll] 授权成功 access_token=${redact(r.token.access_token)}`);
      return json(res, 200, { status: 'ok', ...tokenResponse(r.token) });
    }
    json(res, 200, { status: r.status });
  },

  // 授权码流程（备用）：需要在开放平台配置回调地址
  'GET /oauth/authorize-url': async (req, res) => {
    const u = new URL(req.url, 'http://localhost');
    const redirectUri = u.searchParams.get('redirect_uri') || 'oob';
    json(res, 200, { url: authorizeUrl(config.appKey, redirectUri) });
  },

  'POST /oauth/exchange': async (req, res) => {
    const { code, redirect_uri } = await readBody(req);
    if (!code) throw new Error('缺少 code');
    const token = await exchangeCode(config.appKey, config.secretKey, code, redirect_uri || 'oob');
    console.log(`[exchange] 授权成功 access_token=${redact(token.access_token)}`);
    json(res, 200, tokenResponse(token));
  },

  'POST /oauth/refresh': async (req, res) => {
    const body = await readBody(req);
    if (!body.refresh_token) throw new Error('缺少 refresh_token');
    const token = await refreshToken(config.appKey, config.secretKey, body.refresh_token);
    console.log(`[refresh] 刷新成功 access_token=${redact(token.access_token)}`);
    json(res, 200, tokenResponse(token));
  },
};

const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, 'http://localhost').pathname;
  // 只记录方法与路径，绝不记录 query（可能含令牌）与请求体
  console.log(`${req.method} ${pathname}`);

  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    });
    return res.end();
  }
  res.setHeader('Access-Control-Allow-Origin', '*');

  const handler = routes[`${req.method} ${pathname}`];
  if (!handler) return json(res, 404, { error: 'not_found' });
  try {
    await handler(req, res);
  } catch (err) {
    console.error(`[error] ${pathname}: ${err.message}`);
    errorResponse(res, err);
  }
});

server.listen(config.port, config.host, () => {
  console.log(`\nOAuth 代理已启动：http://${config.host}:${config.port}`);
  console.log(`AppKey=${redact(config.appKey)}（SecretKey 仅在本进程内使用，不会下发）`);
  console.log('端点：GET /health · POST /oauth/device/start · POST /oauth/device/poll · POST /oauth/exchange · POST /oauth/refresh\n');
});
