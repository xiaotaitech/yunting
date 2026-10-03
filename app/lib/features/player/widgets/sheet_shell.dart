import 'package:flutter/material.dart';

/// 底部选择弹窗的外壳。
///
/// 选项一多就会撑破小屏（实测 540x1140 上 9 个速度档溢出 153px，
/// 底部几档直接被切掉、点不到）。这里统一限高 + 可滚动，
/// 以后往里加选项也不用担心。
class SheetShell extends StatelessWidget {
  const SheetShell({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        // 最多占屏幕七成，剩下的留给背景，让人知道点空白能关掉
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, children: children),
            ),
          ],
        ),
      ),
    );
  }
}
