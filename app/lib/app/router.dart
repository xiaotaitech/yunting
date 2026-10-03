import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/main_shell.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/core/config.dart';
import 'package:yun_audiobook/data/auth/auth_repository.dart';
import 'package:yun_audiobook/features/account/login_page.dart';
import 'package:yun_audiobook/features/account/mine_page.dart';
import 'package:yun_audiobook/features/help/help_page.dart';
import 'package:yun_audiobook/features/history/history_page.dart';
import 'package:yun_audiobook/features/library/browse_page.dart';
import 'package:yun_audiobook/features/library/series_detail_page.dart';
import 'package:yun_audiobook/features/offline/offline_page.dart';
import 'package:yun_audiobook/features/player/player_page.dart';
import 'package:yun_audiobook/features/shelf/shelf_page.dart';

part 'router.g.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 应用路由（refactor-app-foundation D1）。
///
/// 底部三栏用 StatefulShellRoute.indexedStack：三个分支常驻，切栏不重建，
/// 书架、历史的滚动位置不丢（原来 IndexedStack 的行为）。
/// 播放页与帮助挂在根导航器上，盖住底栏与迷你播放条。
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final auth = ref.watch(authRepositoryProvider);
  final authChanges = _StreamListenable(auth.stateChanges);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.shelf,
    refreshListenable: authChanges,
    redirect: (context, state) {
      // 演示模式没有百度账号可授权，直接进主界面
      if (AppConfig.demoMode) return null;
      final atLogin = state.matchedLocation == Routes.login;
      // 帮助页登录前也要能看（授权遇到问题时就是去那里找答案）
      if (state.matchedLocation.startsWith('/help')) return null;
      return switch (auth.currentState) {
        AuthState.signedIn => atLogin ? Routes.shelf : null,
        AuthState.signedOut => atLogin ? null : Routes.login,
        // bootstrap 已经 restore 过，unknown 只在极短的窗口里出现
        AuthState.unknown => null,
      };
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: Routes.player,
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, __) => const MaterialPage(
          fullscreenDialog: true,
          child: PlayerPage(),
        ),
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            HelpPage(section: state.uri.queryParameters['section']),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.shelf,
                builder: (_, __) => const ShelfPage(),
                routes: [
                  GoRoute(
                    path: 'series/:id',
                    builder: (_, state) =>
                        SeriesDetailPage(seriesId: state.pathParameters['id']!),
                  ),
                  GoRoute(
                    path: 'browse',
                    builder: (_, state) => BrowsePage(
                      path: state.uri.queryParameters['path'] ?? '/',
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.history,
                builder: (_, __) => const HistoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.mine,
                builder: (_, __) => const MinePage(),
                routes: [
                  GoRoute(
                    path: 'offline',
                    builder: (_, __) => const OfflinePage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// 把授权状态流适配成 go_router 要的 Listenable，状态一变就重新跑 redirect。
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _sub;

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }
}
