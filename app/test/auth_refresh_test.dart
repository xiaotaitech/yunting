import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/data/auth/token_store.dart';

/// 内存版安全存储，替代平台通道。
class MemoryStorage implements FlutterSecureStorage {
  final Map<String, String> _map = {};

  @override
  Future<String?> read({required String key, dynamic iOptions, dynamic aOptions,
      dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions,}) async =>
      _map[key];

  @override
  Future<void> write({required String key, required String? value, dynamic iOptions,
      dynamic aOptions, dynamic lOptions, dynamic webOptions, dynamic mOptions,
      dynamic wOptions,}) async {
    if (value == null) {
      _map.remove(key);
    } else {
      _map[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, dynamic iOptions, dynamic aOptions,
      dynamic lOptions, dynamic webOptions, dynamic mOptions, dynamic wOptions,}) async {
    _map.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 可控的假 OAuth 代理：数出被调用了几次刷新，并能模拟各种失败。
class FakeProxy extends http.BaseClient {
  FakeProxy({
    this.refreshFails = false,
    this.upstreamError,
    this.delay = Duration.zero,
  });

  final bool refreshFails;

  /// 非 401 的上游失败（例如 AppKey 配错时代理转出来的 502 + 具体原因）。
  final String? upstreamError;

  final Duration delay;
  int refreshCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await Future<void>.delayed(delay);
    if (upstreamError != null) {
      return _json(502, {'error': 'api', 'message': upstreamError});
    }
    if (request.url.path.endsWith('/oauth/refresh')) {
      refreshCalls++;
      if (refreshFails) {
        return _json(401, {'error': 'invalid_grant'});
      }
      return _json(200, {
        'access_token': 'fresh-token-$refreshCalls',
        'refresh_token': 'refresh-$refreshCalls',
        'expires_in': 3600,
        'scope': 'basic,netdisk',
      });
    }
    return _json(404, {'error': 'not_found'});
  }

  http.StreamedResponse _json(int status, Map<String, dynamic> body) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(Stream.value(bytes), status,
        headers: {'content-type': 'application/json'},);
  }
}

/// 注入假代理地址，使测试走的是真实的刷新逻辑而不是"未配置"分支。
Future<AuthRepository> repoWithExpiredToken(FakeProxy proxy) async {
  final store = TokenStore(MemoryStorage());
  await store.write(AuthToken(
    accessToken: 'stale-token',
    refreshToken: 'old-refresh',
    // 已经过期，任何一次取 token 都会触发刷新
    expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
    scope: 'basic,netdisk',
  ),);
  return AuthRepository(
    store: store,
    client: proxy,
    proxyBase: 'http://fake-proxy.test',
  );
}

void main() {
  group('令牌刷新', () {
    test('过期令牌会触发一次刷新并返回新令牌', () async {
      final proxy = FakeProxy();
      final repo = await repoWithExpiredToken(proxy);

      expect(await repo.accessToken(), 'fresh-token-1');
      expect(proxy.refreshCalls, 1);
    });

    test('刷新后的令牌被持久化，下次不再重复刷新', () async {
      final proxy = FakeProxy();
      final repo = await repoWithExpiredToken(proxy);

      await repo.accessToken();
      await repo.accessToken();

      expect(proxy.refreshCalls, 1, reason: '新令牌未过期，不该再刷一次');
    });

    test('并发请求撞上过期时只发起一次刷新（去重）', () async {
      final proxy = FakeProxy(delay: const Duration(milliseconds: 50));
      final repo = await repoWithExpiredToken(proxy);

      final results = await Future.wait([
        repo.accessToken(),
        repo.accessToken(),
        repo.accessToken(),
        repo.accessToken(),
      ]);

      expect(proxy.refreshCalls, 1, reason: '四个并发请求只应触发一次刷新');
      expect(results.toSet().length, 1, reason: '四个请求应拿到同一个新令牌');
    });

    test('refresh_token 失效时抛出「需要重新授权」并清掉本地凭证', () async {
      final proxy = FakeProxy(refreshFails: true);
      final repo = await repoWithExpiredToken(proxy);

      await expectLater(
        repo.accessToken(),
        throwsA(isA<DriveException>().having(
            (e) => e.kind, 'kind', DriveErrorKind.authInvalid,),),
      );
      // 凭证已被清除，再取一次应当是"尚未授权"
      await expectLater(repo.accessToken(), throwsA(isA<DriveException>()));
    });
  });

  group('错误分类', () {
    test('errno=-6 归为授权无效，应重新授权而不是重试', () {
      final e = DriveException.fromErrno(-6);
      expect(e.kind, DriveErrorKind.authInvalid);
      expect(e.isAuthProblem, isTrue);
      expect(e.isRetryable, isFalse);
    });

    test('errno=111 归为令牌过期，应刷新后重放', () {
      final e = DriveException.fromErrno(111);
      expect(e.kind, DriveErrorKind.authExpired);
      expect(e.isAuthProblem, isTrue);
    });

    test('HTTP 403/410 归为链接失效，应重新解析地址并可重试', () {
      for (final status in [403, 410]) {
        final e = DriveException.fromStatus(status);
        expect(e.kind, DriveErrorKind.linkExpired);
        expect(e.isRetryable, isTrue,
            reason: 'dlink 过期必须能被自动恢复流程重试',);
      }
    });

    test('限流可重试，文件不存在不可重试', () {
      expect(DriveException.fromErrno(31034).isRetryable, isTrue);
      expect(DriveException.fromErrno(31066).isRetryable, isFalse);
    });
  });

  group('代理错误信息', () {
    // 在模拟器上实测发现的：AppKey 配错时代理明确回了
    // "invalid_client: unknown client id"，而 App 只显示「HTTP 502」，
    // 把唯一有用的排查线索丢了。
    test('把代理返回的具体原因带给用户，而不是只报状态码', () async {
      final proxy =
          FakeProxy(upstreamError: 'invalid_client: unknown client id');
      final repo = await repoWithExpiredToken(proxy);

      await expectLater(
        repo.accessToken(),
        throwsA(isA<DriveException>()
            .having((e) => e.message, 'message', contains('unknown client id')),),
      );
    });

    test('响应体给不出原因时才退回状态码', () async {
      final proxy = FakeProxy(upstreamError: '');
      final repo = await repoWithExpiredToken(proxy);

      await expectLater(
        repo.accessToken(),
        throwsA(isA<DriveException>()
            .having((e) => e.message, 'message', contains('502')),),
      );
    });
  });
}
