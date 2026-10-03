import 'package:flutter/material.dart';
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
    );
  }
}
