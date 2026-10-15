import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/brand_mark.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/features/history/history_controller.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 左侧抽屉（local-first-drawer-ui）：参考 Claude App 的会话列表。
///
/// 上面是动作（添加书籍、离线管理），中间是最近收听（play-history，
/// 只读本机记录、按天分组，点一条跳回那一章的断点），底部是「我的」。
class HistoryDrawer extends ConsumerWidget {
  const HistoryDrawer({super.key});

  /// 先关抽屉再跳转：否则返回时抽屉还开着。
  static void _go(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push<void>(location));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final history = ref.watch(historyProvider);
    final entries = history.value ?? const <PlayHistoryEntry>[];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const BrandMarkView(size: 28),
                  const SizedBox(width: 10),
                  Text(l.appName, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => _go(context, Routes.addSeries),
                icon: const Icon(Icons.add),
                label: Text(l.shelfAdd),
              ),
            ),
            const SizedBox(height: 4),
            _NavRow(
              icon: Icons.download_outlined,
              label: l.mineOffline,
              onTap: () => _go(context, Routes.offline),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.drawerRecent,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (entries.isNotEmpty)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l.historyClearTooltip,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      onPressed: () => _confirmClear(context, ref),
                    ),
                ],
              ),
            ),
            Expanded(
              child: history.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => _Hint(l.anyError(e)),
                data: (entries) => entries.isEmpty
                    ? _Hint(l.historyEmptyDescription)
                    : _HistoryList(entries: entries),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  foregroundColor: theme.colorScheme.onPrimaryContainer,
                  child: const Icon(Icons.person, size: 18),
                ),
                title: Text(l.navMine),
                trailing: const Icon(Icons.settings_outlined, size: 20),
                onTap: () => _go(context, Routes.mine),
              ),
            ),
          ],
        ),
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

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          dense: true,
          leading: Icon(icon, size: 22),
          title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          onTap: onTap,
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Text(
        text,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});

  final List<PlayHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
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
            if (showHeader) _DayHeader(at: entry.lastAt, first: i == 0),
            _HistoryTile(entry: entry),
          ],
        );
      },
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.at, required this.first});

  final DateTime at;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, first ? 4 : 14, 16, 4),
      child: Text(
        formatHistoryDay(context.l10n, at),
        style: theme.textTheme.labelSmall?.copyWith(
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
    final hint = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      // 历史条目只快照了网盘封面 id；本机封面（自动取的 / 手动选的）按合集现查
      leading: SeriesCover(
        title: entry.seriesTitle,
        coverFsId: entry.coverFsId,
        localPath:
            ref.watch(seriesProvider(entry.seriesId)).value?.coverLocalPath,
        width: 32,
        height: 42,
        radius: 5,
      ),
      title: Text(
        entry.episodeTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        '${entry.seriesTitle} · '
        '${entry.finished ? l.historyFinished : formatListened(l, entry.listenedMs)}'
        ' · ${formatClock(entry.lastAt)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: hint,
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
    final navigator = Navigator.of(context);

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
        navigator.pop();
        unawaited(router.push<void>(Routes.player));
      case OpenNotReady(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(l.notReady(reason))));
    }
  }
}
