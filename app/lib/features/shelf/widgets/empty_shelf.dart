import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/features/common/widgets/empty_state.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class EmptyShelf extends StatelessWidget {
  const EmptyShelf({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return EmptyState(
      icon: Icons.library_books_outlined,
      title: l.shelfEmptyTitle,
      description: l.shelfEmptyDescription,
      action: FilledButton.icon(
        onPressed: () => context.push(Routes.addSeries),
        icon: const Icon(Icons.add),
        label: Text(l.shelfAdd),
      ),
    );
  }
}
