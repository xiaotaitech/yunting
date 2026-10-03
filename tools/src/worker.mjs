// oauth-proxy.mjs 的 Cloudflare Workers 版本：同样的端点与职责边界，公网可达。
//   - SecretKey 存在 Worker Secret 里（wrangler secret put BAIDU_SECRET_KEY），绝不下发
//   - 不接触任何文件元数据，日志只记方法与路径
import {
  deviceCodeStart, deviceCodePoll, exchangeCode, refreshToken,
  authorizeUrl, redact, BaiduError,
} from './baidu.mjs';

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
};

const json = (status, body) => new Response(JSON.stringify(body), {
  status,
  headers: { 'Content-Type': 'application/json; charset=utf-8', 'Cache-Control': 'no-store', ...CORS },
});

async function readBody(req) {
  const raw = await req.text();
  if (raw.length > 64 * 1024) throw new Error('请求体过大');
  return raw ? JSON.parse(raw) : {};
}

function tokenResponse(token) {
  return {
    access_token: token.access_token,
    refresh_token: token.refresh_token,
    expires_in: token.expires_in,
    scope: token.scope,
  };
}

function errorResponse(err) {
  if (err instanceof BaiduError) {
    const status = err.kind === 'auth_expired' || err.kind === 'scope_invalid' ? 401
      : err.kind === 'rate_limited' ? 429 : 502;
    return json(status, { error: err.kind, message: err.message });
  }
  return json(400, { error: 'bad_request', message: err.message });
}

const routes = {
  'GET /health': async (_req, env) => json(200, { ok: true, appKey: redact(env.BAIDU_APP_KEY) }),

  'POST /oauth/device/start': async (_req, env) => {
    const d = await deviceCodeStart(env.BAIDU_APP_KEY);
    return json(200, {
      device_code: d.device_code,
      user_code: d.user_code,
      verification_url: d.verification_url,
      qrcode_url: d.qrcode_url,
      expires_in: d.expires_in,
      interval: d.interval,
    });
  },

  'POST /oauth/device/poll': async (req, env) => {
    const { device_code } = await readBody(req);
    if (!device_code) throw new Error('缺少 device_code');
    const r = await deviceCodePoll(env.BAIDU_APP_KEY, env.BAIDU_SECRET_KEY, device_code);
    if (r.status === 'ok') return json(200, { status: 'ok', ...tokenResponse(r.token) });
    return json(200, { status: r.status });
  },

  'GET /oauth/authorize-url': async (req, env) => {
    const redirectUri = new URL(req.url).searchParams.get('redirect_uri') || 'oob';
    return json(200, { url: authorizeUrl(env.BAIDU_APP_KEY, redirectUri) });
  },

  'POST /oauth/exchange': async (req, env) => {
    const { code, redirect_uri } = await readBody(req);
    if (!code) throw new Error('缺少 code');
    const token = await exchangeCode(env.BAIDU_APP_KEY, env.BAIDU_SECRET_KEY, code, redirect_uri || 'oob');
    return json(200, tokenResponse(token));
  },

  'POST /oauth/refresh': async (req, env) => {
    const body = await readBody(req);
    if (!body.refresh_token) throw new Error('缺少 refresh_token');
    const token = await refreshToken(env.BAIDU_APP_KEY, env.BAIDU_SECRET_KEY, body.refresh_token);
    return json(200, tokenResponse(token));
  },
};

export default {
  async fetch(req, env) {
    const { pathname } = new URL(req.url);
    console.log(`${req.method} ${pathname}`);
    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
    if (!env.BAIDU_APP_KEY || !env.BAIDU_SECRET_KEY) {
      return json(500, { error: 'misconfigured', message: '缺少 BAIDU_APP_KEY / BAIDU_SECRET_KEY' });
    }
    const handler = routes[`${req.method} ${pathname}`];
    if (!handler) return json(404, { error: 'not_found' });
    try {
      return await handler(req, env);
    } catch (err) {
      console.error(`[error] ${pathname}: ${err.message}`);
      return errorResponse(err);
    }
  },
};
