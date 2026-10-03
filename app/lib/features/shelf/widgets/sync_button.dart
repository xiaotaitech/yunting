import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/shelf/sync_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 书架右上角的同步按钮。同步要走网盘，慢的时候好几秒：
/// 进行中换成转圈并禁用，免得连点出好几次同步、以为没反应。
class SyncButton extends ConsumerWidget {
  const SyncButton({super.key});

  Future<void> _sync(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final ok = await ref.read(syncControllerProvider.notifier).syncNow();
    // 同步的重点恰恰是「拉回了新东西」：报同步之后书架上的数量。
    final books =
        await ref.read(libraryControllerProvider.notifier).shelfOnce();
    messenger.showSnackBar(SnackBar(
      content: Text(ok ? l.shelfSyncDone(books.length) : l.shelfSyncFailed),
    ),);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final syncing = ref.watch(syncControllerProvider);
    return IconButton(
      tooltip: syncing ? l.shelfSyncing : l.shelfSync,
      onPressed: syncing ? null : () => _sync(context, ref),
      icon: syncing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
    );
  }
}
