import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../core/config.dart';
import '../data/auth/auth_repository.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'mine_screen.dart';
import 'shelf_screen.dart';
import 'update_dialog.dart';
import 'widgets/mini_player.dart';

/// 根据授权状态在登录页与主界面之间切换。
class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 演示模式没有百度账号可授权，直接进主界面
    if (AppConfig.demoMode) return const _MainShell();

    final services = ref.watch(servicesProvider);
    // bootstrap 阶段已经 restore 过，这里直接用同步快照做初值，
    // 之后由 stateChanges 推动切换。不要在 build 里再触发一次异步恢复。
    final state =
        ref.watch(authStateProvider).value ?? services.auth.currentState;

    switch (state) {
      case AuthState.unknown:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AuthState.signedIn:
        return const _MainShell();
      case AuthState.signedOut:
        return const LoginScreen();
    }
  }
}

class _MainShell extends ConsumerStatefulWidget {
  const _MainShell();

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  int _tab = 0;
  Timer? _updateCheck;

  // 一级入口只放常去的三处。离线管理是维护页（设配额、按书清缓存），
  // 而下载动作本来就在书籍详情页，所以它收在「我的」里。
  static const _pages = [ShelfScreen(), HistoryScreen(), MineScreen()];

  @override
  void initState() {
    super.initState();
    // 启动后静默检查一次新版本；等首屏和续播都安顿下来再查，不和它们抢网络
    _updateCheck = Timer(const Duration(seconds: 3), () {
      if (mounted) checkUpdateOnLaunch(context, ref);
    });
  }

  @override
  void dispose() {
    _updateCheck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 让三个页面常驻：原来切一次标签就重建一次，
      // 书架、历史的滚动位置每次都回到顶部。数据仍在切换时按需刷新（见下）。
      body: SafeArea(child: IndexedStack(index: _tab, children: _pages)),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) {
              setState(() => _tab = i);
              // 播放中每 5 秒就会写一笔历史，但列表不自动跟着跳。
              // 切到历史页时重取一次，这样看到的总是最新的。
              if (_pages[i] is HistoryScreen) ref.invalidate(historyProvider);
              // 同理：书架顶部的续听卡片读的是 last_played_at，也是那 5 秒
              // 一次的上报在写。从迷你播放条或历史页开始听之后回到书架，
              // 不重取的话卡片还停在上一本书上。
              if (_pages[i] is ShelfScreen) ref.invalidate(shelfProvider);
            },
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: '书架'),
              NavigationDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: '历史'),
              NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: '我的'),
            ],
          ),
        ],
      ),
    );
  }
}
