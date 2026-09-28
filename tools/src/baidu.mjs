// 百度 OAuth 与网盘接口的薄封装。
// 设计约束（见 openspec design.md D3/D8）：
//   - scope 固定 basic,netdisk，传错接口会返回 errno=-6
//   - 一切对 dlink 的请求必须带 User-Agent: pan.baidu.com，且跟随 302 后仍要保留该 UA
//   - 只访问「当前授权用户本人」的文件，不提供任何分享类能力
//
// 官方文档：
//   接入流程   https://pan.baidu.com/union/doc/pkuo3snyp
//   设备码模式 https://pan.baidu.com/union/doc/fl1x114ti

export const OAUTH_BASE = 'https://openapi.baidu.com/oauth/2.0';
export const PAN_BASE = 'https://pan.baidu.com/rest/2.0';
export const SCOPE = 'basic,netdisk';
export const PAN_UA = 'pan.baidu.com';

/** 令牌与 dlink 一律脱敏后才允许进日志。 */
export function redact(value) {
  if (typeof value !== 'string' || value.length === 0) return value;
  if (value.length <= 8) return '***';
  return `${value.slice(0, 4)}***${value.slice(-4)}`;
}

export function redactUrl(url) {
  return String(url)
    .replace(/(access_token=)[^&]+/gi, (_, k) => k + '***')
    .replace(/(sign=)[^&]+/gi, (_, k) => k + '***');
}

class BaiduError extends Error {
  constructor(kind, message, detail) {
    super(message);
    this.name = 'BaiduError';
    this.kind = kind; // auth_expired | scope_invalid | rate_limited | not_found | network | api
    this.detail = detail;
  }
}
export { BaiduError };

/** 把百度的 errno / OAuth error 映射成上层能分流处理的类别（design.md D3）。 */
export function classifyErrno(errno) {
  switch (Number(errno)) {
    case 0: return null;
    case -6: return new BaiduError('scope_invalid', 'errno=-6：授权无效或 scope 不是 basic,netdisk，需要重新授权', errno);
    case 111:
      return new BaiduError('auth_expired', 'errno=111：access_token 失效，需要刷新令牌', errno);
    // -9 是「文件或目录不存在」，不是令牌问题。
    // 之前把它归到 auth_expired，结果路径写错时会去白刷一次 token，
    // 刷完照样失败，最后报给用户「授权失效请重新登录」——完全指错方向。
    case -9:
      return new BaiduError('not_found', 'errno=-9：文件或目录不存在', errno);
    case -7:
      return new BaiduError('not_found', 'errno=-7：文件或目录名错误，或无权访问', errno);
    case 31034:
    case 31045:
      return new BaiduError('rate_limited', `errno=${errno}：请求过于频繁或接口受限，请退避后重试`, errno);
    case 31066:
    case 31062:
      return new BaiduError('not_found', `errno=${errno}：文件不存在或路径非法`, errno);
    default:
      return new BaiduError('api', `百度接口返回 errno=${errno}`, errno);
  }
}

async function getJson(url, { timeoutMs = 20000 } = {}) {
  const ac = new AbortController();
  const timer = setTimeout(() => ac.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      signal: ac.signal,
      headers: { 'User-Agent': PAN_UA },
    });
    const text = await res.text();
    let json;
    try {
      json = JSON.parse(text);
    } catch {
      throw new BaiduError('api', `响应不是 JSON（HTTP ${res.status}）：${text.slice(0, 200)}`);
    }
    return json;
  } catch (err) {
    if (err instanceof BaiduError) throw err;
    throw new BaiduError('network', `请求失败：${err.message}`, redactUrl(url));
  } finally {
    clearTimeout(timer);
  }
}

function assertOk(json) {
  if (json.error || json.error_code) {
    throw new BaiduError('api', `${json.error || json.error_code}: ${json.error_description || json.error_msg || ''}`);
  }
  const e = classifyErrno(json.errno ?? 0);
  if (e) throw e;
  return json;
}

// ---------------------------------------------------------------- OAuth

/** 设备码流程第一步：拿 user_code 让用户去浏览器授权。不需要回调域名。 */
export async function deviceCodeStart(appKey) {
  const url = `${OAUTH_BASE}/device/code?response_type=device_code&client_id=${encodeURIComponent(appKey)}&scope=${encodeURIComponent(SCOPE)}`;
  return assertOk(await getJson(url));
}

/**
 * 设备码流程第二步：轮询换取令牌。
 * 返回 { status: 'pending' | 'slow_down' | 'ok' | 'denied' | 'expired', token? }
 */
export async function deviceCodePoll(appKey, secretKey, deviceCode) {
  const url = `${OAUTH_BASE}/token?grant_type=device_token&code=${encodeURIComponent(deviceCode)}`
    + `&client_id=${encodeURIComponent(appKey)}&client_secret=${encodeURIComponent(secretKey)}`;
  const json = await getJson(url);
  if (json.access_token) return { status: 'ok', token: normalizeToken(json) };
  switch (json.error) {
    case 'authorization_pending': return { status: 'pending' };
    case 'slow_down': return { status: 'slow_down' };
    case 'authorization_declined': return { status: 'denied' };
    // 文档写的是 expired_token，但百度实际回的是 invalid_grant
    // （"invalid code , expired or revoked"）。只认文档那个会走到 default，
    // 把一个再正常不过的"码过期了"变成一串英文原始错误抛给用户。
    case 'expired_token':
    case 'invalid_grant':
      return { status: 'expired' };
    default:
      throw new BaiduError('api', `设备码轮询失败：${json.error || 'unknown'} ${json.error_description || ''}`);
  }
}

/** 授权码流程：code -> token。redirectUri 必须与开放平台控制台配置一致。 */
export async function exchangeCode(appKey, secretKey, code, redirectUri) {
  const url = `${OAUTH_BASE}/token?grant_type=authorization_code&code=${encodeURIComponent(code)}`
    + `&client_id=${encodeURIComponent(appKey)}&client_secret=${encodeURIComponent(secretKey)}`
    + `&redirect_uri=${encodeURIComponent(redirectUri)}`;
  return normalizeToken(assertOk(await getJson(url)));
}

export async function refreshToken(appKey, secretKey, refresh) {
  const url = `${OAUTH_BASE}/token?grant_type=refresh_token&refresh_token=${encodeURIComponent(refresh)}`
    + `&client_id=${encodeURIComponent(appKey)}&client_secret=${encodeURIComponent(secretKey)}`;
  return normalizeToken(assertOk(await getJson(url)));
}

export function authorizeUrl(appKey, redirectUri, { display = 'mobile' } = {}) {
  return `${OAUTH_BASE}/authorize?response_type=code&client_id=${encodeURIComponent(appKey)}`
    + `&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${encodeURIComponent(SCOPE)}&display=${display}`;
}

function normalizeToken(json) {
  return {
    access_token: json.access_token,
    refresh_token: json.refresh_token,
    expires_in: json.expires_in,
    scope: json.scope,
  };
}

// ---------------------------------------------------------------- 网盘

export async function userInfo(accessToken) {
  return assertOk(await getJson(`${PAN_BASE}/xpan/nas?method=uinfo&access_token=${encodeURIComponent(accessToken)}`));
}

/** 列目录。只列当前授权用户本人的文件。 */
export async function listDir(accessToken, dir = '/', { start = 0, limit = 1000, order = 'name' } = {}) {
  const url = `${PAN_BASE}/xpan/file?method=list&access_token=${encodeURIComponent(accessToken)}`
    + `&dir=${encodeURIComponent(dir)}&order=${order}&start=${start}&limit=${limit}&web=1`;
  return assertOk(await getJson(url));
}

/** 取文件元信息并要 dlink。dlink 有时效，绝不持久化（design.md D3）。 */
export async function fileMetas(accessToken, fsIds, { dlink = true, thumb = true } = {}) {
  const url = `${PAN_BASE}/xpan/multimedia?method=filemetas&access_token=${encodeURIComponent(accessToken)}`
    + `&fsids=${encodeURIComponent(JSON.stringify(fsIds.map(Number)))}`
    + `&dlink=${dlink ? 1 : 0}&thumb=${thumb ? 1 : 0}&extra=1`;
  return assertOk(await getJson(url));
}

export function withToken(dlink, accessToken) {
  return `${dlink}${dlink.includes('?') ? '&' : '?'}access_token=${encodeURIComponent(accessToken)}`;
}

/** 按规格要求发起 dlink 请求：强制 UA、跟随 302、可选 Range。 */
export async function fetchDlink(dlink, accessToken, { range, method = 'GET' } = {}) {
  const headers = { 'User-Agent': PAN_UA };
  if (range) headers.Range = range;
  return fetch(withToken(dlink, accessToken), { method, headers, redirect: 'follow' });
}
