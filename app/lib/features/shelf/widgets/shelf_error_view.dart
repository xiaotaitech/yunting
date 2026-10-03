import 'package:flutter/material.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class ShelfErrorView extends StatelessWidget {
  const ShelfErrorView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: Text(context.l10n.actionRetry),
            ),
          ],
        ),
      ),
    );
  }
}
