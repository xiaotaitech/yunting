import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/library/widgets/episode_list.dart';
import 'package:yun_audiobook/features/library/widgets/reorderable_episodes.dart';
import 'package:yun_audiobook/features/library/widgets/series_dialogs.dart';
import 'package:yun_audiobook/features/library/widgets/series_header.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 合集详情：条目列表、下载、编辑信息、手动排序。
class SeriesDetailPage extends ConsumerStatefulWidget {
  const SeriesDetailPage({required this.seriesId, super.key});

  final String seriesId;

  @override
  ConsumerState<SeriesDetailPage> createState() => _SeriesDetailPageState();
}

class _SeriesDetailPageState extends ConsumerState<SeriesDetailPage> {
  bool _reordering = false;
  bool _refreshing = false;
  bool _autoRefreshed = false;

  LibraryController get _library =>
      ref.read(libraryControllerProvider.notifier);

  /// 从网盘同步回来的书只有元数据和进度，条目要重新从网盘解析。
  /// 第一次打开时自动补齐，别让用户自己去菜单里点「刷新章节」。
  Future<void> _autoRefreshIfEmpty(
    Series series,
    List<Episode> episodes,
  ) async {
    if (_autoRefreshed || episodes.isNotEmpty || series.sourceMissing) return;
    _autoRefreshed = true;
    await _library.refresh(series);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final episodes = ref.watch(episodesProvider(widget.seriesId));

    // 合集走 provider（库的 watch 流）：当前章的高亮、书架上的进度都会自动跟着变
    final series = ref.watch(seriesProvider(widget.seriesId)).value;
    if (series == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(series.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: _reordering ? l.detailReorderDone : l.detailReorder,
            icon: Icon(_reordering ? Icons.check : Icons.swap_vert),
            onPressed: () => setState(() => _reordering = !_reordering),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(v, series),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l.detailMenuEdit)),
              PopupMenuItem(value: 'cover', child: Text(l.detailMenuCover)),
              PopupMenuItem(value: 'refresh', child: Text(l.detailMenuRefresh)),
              // 纯视频的课程、本机书都没有要离线的内容，下载与清缓存都不出现
              if (series.kind != SeriesKind.course && !series.isLocal) ...[
                PopupMenuItem(
                  value: 'download',
                  child: Text(l.detailMenuDownload),
                ),
                PopupMenuItem(value: 'clear', child: Text(l.detailMenuClear)),
              ],
              PopupMenuItem(value: 'remove', child: Text(l.detailMenuRemove)),
            ],
          ),
        ],
      ),
      body: episodes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.anyError(e))),
        data: (list) {
          unawaited(_autoRefreshIfEmpty(series, list));
          return Column(
            children: [
              SeriesHeader(series: series, episodes: list),
              if (_refreshing)
                const LinearProgressIndicator(minHeight: 1)
              else
                const Divider(height: 1),
              Expanded(
                child: _reordering
                    ? ReorderableEpisodes(series: series, episodes: list)
                    : EpisodeList(series: series, episodes: list),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onMenu(String value, Series series) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;

    switch (value) {
      case 'cover':
        // 系统照片选择器，不需要权限；取消就什么都不变
        if (await _library.pickCover(series)) {
          messenger.showSnackBar(SnackBar(content: Text(l.detailCoverChanged)));
        }
      case 'edit':
        final edited = await editSeriesDialog(context, series);
        if (edited == null) return;
        await _library.edit(series, title: edited.title, author: edited.author);
      case 'refresh':
        // 刷新要重新列一遍网盘目录，慢的时候好几秒，得让人看到在干活
        setState(() => _refreshing = true);
        try {
          await _library.refresh(series);
          messenger.showSnackBar(SnackBar(content: Text(l.detailRefreshed)));
        } on Object catch (_) {
          messenger
              .showSnackBar(SnackBar(content: Text(l.detailRefreshFailed)));
        } finally {
          if (mounted) setState(() => _refreshing = false);
        }
      case 'download':
        await _library.downloadAll(series);
        final count = ref.read(episodesProvider(series.id)).value?.length ?? 0;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l.detailDownloadQueued(count, l.unit(series.kind))),
          ),
        );
      case 'clear':
        await _library.clearCache(series);
        messenger.showSnackBar(SnackBar(content: Text(l.detailCacheCleared)));
      case 'remove':
        if (!await confirmRemoveSeries(context)) return;
        await _library.remove(series);
        if (mounted) context.pop();
    }
  }
}
