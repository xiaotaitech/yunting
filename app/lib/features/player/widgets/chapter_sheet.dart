import 'package:flutter/material.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 播放页的章节列表弹窗。
///
/// 没有复用 SheetShell：它接的是 children，底层 ListView 没法定位到指定项，
/// 而这里必须打开就落在当前章上——34 章的书让人从头翻毫无道理。
/// 固定行高 + initialScrollOffset 换算偏移是最省事的做法。
class ChapterSheet extends StatefulWidget {
  const ChapterSheet({
    required this.kind,
    required this.episodes,
    required this.currentIndex,
    super.key,
  });

  final SeriesKind kind;
  final List<Episode> episodes;
  final int currentIndex;

  @override
  State<ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<ChapterSheet> {
  /// 与下面 itemExtent 保持一致，定位偏移靠它换算。
  static const _rowHeight = 60.0;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    // 当前章往上留两行，让人看得见前后文；超出范围 ListView 会自己夹回去。
    _controller = ScrollController(
      initialScrollOffset:
          ((widget.currentIndex - 2) * _rowHeight).clamp(0.0, double.infinity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l.playerEpisodesTitle(
                  widget.kind.name,
                  widget.episodes.length,
                  l.unit(widget.kind),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                controller: _controller,
                itemExtent: _rowHeight,
                itemCount: widget.episodes.length,
                itemBuilder: (context, i) => _EpisodeTile(
                  index: i,
                  episode: widget.episodes[i],
                  isCurrent: i == widget.currentIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({
    required this.index,
    required this.episode,
    required this.isCurrent,
  });

  final int index;
  final Episode episode;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      // 序号样式与书籍详情页的章节列表一致，两处观感不能打架
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11,
            color: isCurrent ? theme.colorScheme.onPrimary : null,
          ),
        ),
      ),
      title: Text(
        episode.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (episode.isCached)
            Icon(Icons.offline_pin, size: 18, color: theme.hintColor),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(
                Icons.volume_up,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
      onTap: () => Navigator.of(context).pop(index),
    );
  }
}
