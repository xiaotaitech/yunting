import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/features/history/history_drawer.dart';
import 'package:yun_audiobook/features/player/widgets/mini_player.dart';
import 'package:yun_audiobook/features/update/update_dialog.dart';

/// 外层 Scaffold：书架左上角的菜单键经它打开抽屉。
final shellScaffoldKey = GlobalKey<ScaffoldState>(debugLabel: 'shell');

/// 主界面外壳：左侧抽屉 + 底部迷你播放条（local-first-drawer-ui）。
///
/// 参考 Claude App：没有底部导航，一级入口收进抽屉，最近收听像会话列表
/// 一样常驻在那里。抽屉挂在外层，打开时连播放条一起盖住。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.atRoot, required this.child, super.key});

  /// 是否在书架根页。只有这时才允许从左边缘滑出抽屉——
  /// 其它页面的左边缘是系统返回手势。
  final bool atRoot;
  final Widget child;

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
  Widget build(BuildContext context) => Scaffold(
        key: shellScaffoldKey,
        drawer: const HistoryDrawer(),
        drawerEnableOpenDragGesture: widget.atRoot,
        body: SafeArea(bottom: false, child: widget.child),
        bottomNavigationBar: const MiniPlayer(),
      );
}
