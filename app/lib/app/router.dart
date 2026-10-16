
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/main_shell.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/features/account/login_page.dart';
import 'package:yun_audiobook/features/account/mine_page.dart';
import 'package:yun_audiobook/features/help/help_page.dart';
import 'package:yun_audiobook/features/library/add_series_page.dart';
import 'package:yun_audiobook/features/library/browse_page.dart';
import 'package:yun_audiobook/features/library/series_detail_page.dart';
import 'package:yun_audiobook/features/offline/offline_page.dart';
import 'package:yun_audiobook/features/player/player_page.dart';
import 'package:yun_audiobook/features/shelf/shelf_page.dart';

part 'router.g.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// 应用路由（refactor-app-foundation D1）。
///
/// 播放页与帮助挂在根导航器上，盖住迷你播放条。
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.shelf,
    routes: [
      // 本地优先：没登录也能用本地书架，登录页只在要用网盘时按需打开，
      // 登录成功后自己关掉（见 LoginPage）。
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
      // 主屏只有书架一个根页面，其它页面压在它上面（local-first-drawer-ui）。
      // ShellRoute 只为让迷你播放条与抽屉盖在这些页面外面。
      ShellRoute(
        builder: (_, state, child) =>
            MainShell(atRoot: state.uri.path == Routes.shelf, child: child),
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
                path: 'add',
                builder: (_, __) => const AddSeriesPage(),
              ),
              GoRoute(
                path: 'browse',
                builder: (_, state) => BrowsePage(
                  path: state.uri.queryParameters['path'] ?? '/',
                ),
              ),
            ],
          ),
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
  );
}
