import 'package:flutter/material.dart';

/// 播放页底部的次级动作（倍速 / 定时 / 章节）。
///
/// 图标在上、文字在下的等宽格子，而不是 `TextButton.icon`：后者的视觉
/// 重量明显低于主控制行，把三个常用动作显示成了附属功能。
class PlayerAction extends StatelessWidget {
  const PlayerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 睡眠定时启用时置位：这个状态必须一眼可见。
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        highlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: highlighted ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
