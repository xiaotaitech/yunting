import 'package:flutter/material.dart';

/// 空态的统一外观：图标 + 一句结论 + 一句怎么办。
///
/// 抽出来是因为原来两处空态长得不一样：书架是「图标 + 标题 + 说明」三级，
/// 离线页只有一行居中小字。同一个 App 里两种空态，看着像两个人做的。
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon, required this.title, super.key,
    this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.hintColor, height: 1.5),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
