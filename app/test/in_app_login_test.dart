import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/auth/token_store.dart';

import 'support/memory_storage.dart';

const _authorize = 'https://openapi.baidu.com/oauth/2.0/authorize'
    '?response_type=code&client_id=k&redirect_uri=oob&display=mobile';

void main() {
  group('回跳地址识别', () {
    test('带 code 的回跳', () {
      final r = parseBaiduCallback(
        Uri.parse('https://openapi.baidu.com/oauth/2.0/login_success?code=abc'),
      );
      expect(r, isA<OAuthCode>().having((c) => c.code, 'code', 'abc'));
    });

    test('http 的回跳也认（百度有时不升级到 https）', () {
      final r = parseBaiduCallback(
        Uri.parse('http://openapi.baidu.com/oauth/2.0/login_success?code=x'),
      );
      expect(r, isA<OAuthCode>());
    });

    test('拒绝授权', () {
      final r = parseBaiduCallback(
        Uri.parse(
          'https://openapi.baidu.com/oauth/2.0/login_success'
          '?error=access_denied&error_description=user%20denied',
        ),
      );
      expect(r,
          isA<OAuthDenied>().having((d) => d.reason, 'reason', 'user denied'));
    });

    test('授权页、登录页等其它地址不拦', () {
      expect(parseBaiduCallback(Uri.parse(_authorize)), isNull);
      expect(
        parseBaiduCallback(Uri.parse('https://wappass.baidu.com/passport')),
        isNull,
      );
      // 别的域名上同名路径不能当成回跳
      expect(
        parseBaiduCallback(
          Uri.parse('https://evil.test/oauth/2.0/login_success?code=x'),
        ),
        isNull,
      );
    });
  });

  group('App 内登录', () {
    late TokenStore store;
    late List<String> calls;

    AuthRepository repo({int exchangeStatus = 200}) => AuthRepository(
          store: store,
          proxyBase: 'http://fake-proxy.test',
          client: MockClient((req) async {
            calls.add('${req.method} ${req.url.path}');
            if (req.url.path == '/oauth/authorize-url') {
              return http.Response(jsonEncode({'url': _authorize}), 200);
            }
            if (req.url.path == '/oauth/exchange') {
              expect(jsonDecode(req.body), {'code': 'the-code'});
              return http.Response(
                jsonEncode({
                  'access_token': 'at',
                  'refresh_token': 'rt',
                  'expires_in': 3600,
                  'scope': 'basic,netdisk',
                }),
                exchangeStatus,
              );
            }
            return http.Response('{}', 404);
          }),
        );

    setUp(() {
      store = TokenStore(MemoryStorage());
      calls = [];
    });

    test('授权页地址由代理给出', () async {
      expect((await repo().authorizeUrl()).toString(), _authorize);
    });

    test('code 换令牌：存下令牌并切到已登录', () async {
      final auth = repo();
      await auth.restore();
      expect(auth.currentState, AuthState.signedOut);
      await auth.exchangeCode('the-code');
      expect(auth.currentState, AuthState.signedIn);
      expect(await auth.accessToken(), 'at');
      expect((await store.read())!.refreshToken, 'rt');
      expect(calls, ['POST /oauth/exchange']);
    });

    test('code 无效（代理 401）：给出可读错误，不登录', () async {
      final auth = repo(exchangeStatus: 401);
      await auth.restore();
      await expectLater(
        auth.exchangeCode('the-code'),
        throwsA(isA<DriveException>()),
      );
      expect(auth.currentState, AuthState.signedOut);
    });
  });
}
