import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class EpisodeList extends ConsumerStatefulWidget {
  const EpisodeList({required this.series, required this.episodes, super.key});

  final Series series;
  final List<Episode> episodes;

  @override
  ConsumerState<EpisodeList> createState() => _EpisodeListState();
}

class _EpisodeListState extends ConsumerState<EpisodeList> {
  /// 打开就落在当前章附近：几十章的书，让人每次从第一章往下翻毫无道理。
  /// 行高不固定（标题可能两行），按单行估算，偏差几十像素无所谓。
  late final _scroll = ScrollController(
    initialScrollOffset: ((widget.series.currentEpisodeIndex - 2) * 72.0)
        .clamp(0.0, double.infinity),
  );

  Series get series => widget.series;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final episodes = widget.episodes;
    final scheme = Theme.of(context).colorScheme;

    // 下载进度写库，episodesProvider 自动推新值，这里不再自己订阅下载事件。
    return ListView.builder(
      controller: _scroll,
      itemCount: episodes.length,
      itemBuilder: (context, i) {
        final e = episodes[i];
        final isCurrent = i == series.currentEpisodeIndex;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                isCurrent ? scheme.primary : scheme.surfaceContainerHighest,
            child: Text('${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? scheme.onPrimary : null,
                ),),
          ),
          title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(_subtitle(context.l10n, e)),
          trailing: _trailing(context, e),
          onTap: () => _play(context, i),
        );
      },
    );
  }

  String _subtitle(AppLocalizations l, Episode e) {
    switch (e.cacheState) {
      case CacheState.cached:
        return l.detailCachedSize(formatBytes(e.downloadedBytes));
      case CacheState.downloading:
        final pct = e.size == 0 ? 0 : (e.downloadedBytes * 100 ~/ e.size);
        return l.detailDownloading(pct);
      case CacheState.queued:
        return l.detailQueued;
      case CacheState.failed:
        return l.detailFailed;
      case CacheState.none:
        return formatBytes(e.size);
    }
  }

  Widget _trailing(BuildContext context, Episode e) {
    final l = context.l10n;
    final controller = ref.read(libraryControllerProvider.notifier);
    switch (e.cacheState) {
      case CacheState.cached:
        return IconButton(
          icon: const Icon(Icons.offline_pin, color: Colors.green),
          tooltip: l.detailCachedTooltip,
          onPressed: null,
        );
      case CacheState.downloading:
      case CacheState.queued:
        return IconButton(
          icon: const Icon(Icons.close),
          tooltip: l.detailCancelDownload,
          onPressed: () => controller.cancelDownload(e),
        );
      case CacheState.none:
      case CacheState.failed:
        return IconButton(
          icon: const Icon(Icons.download_outlined),
          tooltip: l.detailDownloadEpisode(l.unit(series.kind)),
          onPressed: () => controller.download(e),
        );
    }
  }

  Future<void> _play(BuildContext context, int index) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    // 点当前章就从断点接着听，点别的章从头开始；点的正是在播的那一章
    // 直接回播放页——这些判断都在 playEpisode 里。
    final result = await ref
        .read(playbackControllerProvider.notifier)
        .playEpisode(series, index);
    if (!context.mounted) return;
    switch (result) {
      case OpenStarted() || OpenAlreadyPlaying():
        await context.push(Routes.player);
      case OpenNotReady(:final reason):
        messenger.showSnackBar(SnackBar(content: Text(l.notReady(reason))));
    }
  }
}
