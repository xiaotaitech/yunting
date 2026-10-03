import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/features/player/widgets/mini_player.dart';
import 'package:yun_audiobook/features/update/update_dialog.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 主界面外壳：底部三栏 + 迷你播放条。
///
/// 一级入口只放常去的三处。离线管理是维护页（设配额、按书清缓存），
/// 而下载动作本来就在详情页，所以它收在「我的」里。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  Timer? _updateCheck;

  @override
  void initState() {
    super.initState();
    // 启动后静默检查一次新版本；等首屏和续播都安顿下来再查，不和它们抢网络
    _updateCheck = Timer(const Duration(seconds: 3), () {
      if (mounted) unawaited(checkUpdateOnLaunch(context, ref));
    });
  }

  @override
  void dispose() {
    _updateCheck?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: SafeArea(child: widget.shell),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
            selectedIndex: widget.shell.currentIndex,
            // 再点一次当前栏回到该栏的根页面
            onDestinationSelected: (i) => widget.shell
                .goBranch(i, initialLocation: i == widget.shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book),
                label: l.navShelf,
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: l.navHistory,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: l.navMine,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
