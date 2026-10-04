import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/empty_state.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/history/history_controller.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 播放历史（play-history）。
///
/// 只读本机记录，按天分组。点一条跳回那一章的断点继续听。
class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if ((history.value ?? const []).isNotEmpty)
            IconButton(
              tooltip: l.historyClearTooltip,
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.anyError(e))),
        data: (entries) => entries.isEmpty
            ? EmptyState(
                icon: Icons.history,
                title: l.historyEmptyTitle,
                description: l.historyEmptyDescription,
              )
            : _HistoryList(entries: entries),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.historyClearTitle),
        content: Text(l.historyClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.historyClearConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(historyControllerProvider.notifier).clear();
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<PlayHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        // 与上一条不同一天时插一个日期小标题
        final showHeader = i == 0 ||
            formatHistoryDay(l, entries[i - 1].lastAt) !=
                formatHistoryDay(l, entry.lastAt);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader) _DayHeader(at: entry.lastAt),
            _HistoryTile(entry: entry),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.at});

  final DateTime at;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        formatHistoryDay(context.l10n, at),
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.entry});

  final PlayHistoryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodySmall?.copyWith(color: theme.hintColor);

    return ListTile(
      // 历史条目只快照了网盘封面 id；本机封面（自动取的 / 手动选的）按合集现查
      leading: Consumer(
        builder: (context, ref, _) => SeriesCover(
          title: entry.seriesTitle,
          coverFsId: entry.coverFsId,
          localPath:
              ref.watch(seriesProvider(entry.seriesId)).value?.coverLocalPath,
          width: 40,
          height: 54,
          radius: 6,
        ),
      ),
      title: Text(
        entry.episodeTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              entry.seriesTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hint,
            ),
          ),
          Text(' · ', style: hint),
          Text(
            entry.finished
                ? l.historyFinished
                : formatListened(l, entry.listenedMs),
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  entry.finished ? theme.colorScheme.primary : theme.hintColor,
            ),
          ),
        ],
      ),
      trailing: Text(
        formatClock(entry.lastAt),
        style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
      ),
      onTap: () => _resume(context, ref),
    );
  }

  /// 跳回那一章接着听。
  ///
  /// 历史里的章节序号是当时的；书可能已被移出书架，也可能刷新后章节变少，
  /// 所以跳转前要重新取书并校验（范围校验在 playEpisode 里），
  /// 而不是直接拿序号去索引。
  Future<void> _resume(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    // 从书架里找，而不是 seriesProvider——后者不过滤软删除，
    // 移出书架的书照样能查到，那就会让历史点进去播一本已经删掉的书。
    // onShelf 只认 deleted = 0 的。
    final series = await ref
        .read(libraryControllerProvider.notifier)
        .onShelf(entry.seriesId);
    if (series == null) {
      messenger.showSnackBar(SnackBar(content: Text(l.historyNotOnShelf)));
      return;
    }

    // 原来先 openBook 加载书的断点那一章、再 playChapterAt 加载历史这一章，
    // 同一次点击取两次地址、加载两次音源
    // 听完的那一章从头放：断点就在章末，接着放会立刻跳到下一章
    final result =
        await ref.read(playbackControllerProvider.notifier).playEpisode(
              series,
              entry.episodeIndex,
              position: entry.finished
                  ? Duration.zero
                  : Duration(milliseconds: entry.lastPositionMs),
            );
    switch (result) {
      case OpenStarted() || OpenAlreadyPlaying():
        unawaited(router.push<void>(Routes.player));
      case OpenNotReady(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(l.notReady(reason))));
    }
  }
}
