import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../app/services.dart';
import '../domain/models.dart';
import '../playback/audiobook_handler.dart';
import '../playback/sleep_timer.dart';
import 'widgets/book_cover.dart';
import 'widgets/format.dart';

/// 播放页（audio-playback 规格）。
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

  @override
  void initState() {
    super.initState();

    // 反复缓冲时提示改用离线下载，并直接给出一键下载入口
    // （规格「速率不足提示」）
    ref.read(servicesProvider).handler.hints.listen((message) {
      if (!mounted) return;
      final services = ref.read(servicesProvider);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '下载本书',
          onPressed: () async {
            final book = services.handler.currentBook;
            if (book == null) return;
            // 先取 messenger，避免跨 await 后再碰 context
            final messenger = ScaffoldMessenger.of(context);
            final chapters = await services.library.chapters(book.id);
            await services.downloads.enqueueBook(chapters);
            messenger.showSnackBar(
              SnackBar(content: Text('已加入下载队列（${chapters.length} 章）')),
            );
          },
        ),
      ));
    });

    // 恢复失败达到上限时给出可重试的提示（规格「连续失败后报错」）
    ref.read(servicesProvider).handler.failures.listen((f) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(f.message),
        action: f.canRetry
            ? SnackBarAction(
                label: '重试',
                onPressed: () => ref.read(servicesProvider).handler.retry())
            : null,
        duration: const Duration(seconds: 6),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(servicesProvider).handler;
    // 用 mediaItem 流驱动，换章时页面会自己刷新；
    // 直接读 handler 字段是非响应式的，自动续播后标题会停在上一章。
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) =>
          _buildBody(context, handler, snapshot.data),
    );
  }

  Widget _buildBody(
      BuildContext context, AudiobookHandler handler, MediaItem? item) {
    final theme = Theme.of(context);
    final chapter = handler.currentChapter;

    if (item == null || chapter == null) {
      return const Scaffold(body: Center(child: Text('还没有正在播放的书')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.album ?? '',
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          children: [
            // 封面撑到可用宽度的六成多。原来固定 200px 吊在一大片空白正中，
            // 上下留白远大于内容本身，整屏没有重心。上限 300 防止在平板或
            // 横屏上糊成一整块。
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final side = math.min(
                      math.min(box.maxWidth * 0.64, box.maxHeight),
                      300.0,
                    );
                    return BookCover(
                      title: item.album ?? item.title,
                      coverFsId: handler.currentBook?.coverFsId,
                      width: side,
                      height: side,
                      radius: 18,
                    );
                  },
                ),
              ),
            ),
            Text(
              item.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '第 ${handler.currentIndex + 1} 章 / 共 ${handler.currentChapters.length} 章',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
                // 「已离线」原来只是句灰色小字，混在章节计数里根本看不见。
                // 它是「这章断网也能听」的承诺，值得一个标识。
                if (chapter.isCached) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.offline_pin,
                      size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 3),
                  Text('已离线',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.primary)),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _PositionBar(handler: handler),

            const SizedBox(height: 8),
            _TransportControls(handler: handler),
            const SizedBox(height: 16),

            // 倍速 / 定时 / 章节。原来是三个 TextButton.icon，视觉重量比主
            // 控制行低一档，把常用动作显示成了附属功能。改成图标在上、文字
            // 在下的等宽三格，与播放键同级（帆书那排也是这么处理的）。
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<double>(
                    stream: handler.player.speedStream,
                    builder: (context, snap) => _PlayerAction(
                      icon: Icons.speed,
                      label: formatSpeed(snap.data ?? 1.0),
                      onTap: () => _pickSpeed(handler),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<SleepTimerState>(
                    stream: handler.sleepTimer.changes,
                    initialData: handler.sleepTimer.state,
                    builder: (context, snap) {
                      final s = snap.data ?? SleepTimerState.off;
                      return _PlayerAction(
                        icon:
                            s.isActive ? Icons.bedtime : Icons.bedtime_outlined,
                        label: _sleepLabel(s),
                        // 定时开着的时候必须看得出来，否则用户不知道
                        // 会不会突然停
                        highlighted: s.isActive,
                        onTap: () => _pickSleepTimer(handler),
                      );
                    },
                  ),
                ),
                Expanded(
                  // 播放页直达章节列表。切章是听书时的高频动作，原来只能退回
                  // 书籍详情页（返回 → 找章节 → 点），两层跳转太重。
                  child: _PlayerAction(
                    icon: Icons.playlist_play,
                    label: '章节',
                    onTap: () => _pickChapter(handler),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _sleepLabel(SleepTimerState s) {
    switch (s.mode) {
      case SleepTimerMode.off:
        return '定时';
      case SleepTimerMode.duration:
        return formatDuration(s.remaining ?? Duration.zero);
      case SleepTimerMode.endOfChapter:
        return '本章后停';
    }
  }

  Future<void> _pickChapter(AudiobookHandler handler) async {
    final chapters = handler.currentChapters;
    if (chapters.isEmpty) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      // 不开 isScrollControlled 时弹窗最高只有屏高 9/16，几十章的书
      // 够不到 _ChapterSheet 自己的七成上限，白留一截空间。
      isScrollControlled: true,
      builder: (_) => _ChapterSheet(
        chapters: chapters,
        currentIndex: handler.currentIndex,
      ),
    );
    if (picked == null || picked == handler.currentIndex) return;
    await handler.playChapterAt(picked);
  }

  Future<void> _pickSpeed(AudiobookHandler handler) async {
    final current = handler.player.speed;
    final picked = await showModalBottomSheet<double>(
      context: context,
      // 9 个速度档在小屏上撑得下底部弹窗（实测 540x1140 溢出 153px），
      // 必须可滚动 + 限高，否则底部选项直接被切掉、够不着。
      isScrollControlled: true,
      builder: (ctx) => _SheetShell(
        title: '播放速度',
        children: [
            for (final s in _speeds)
              ListTile(
                title: Text(formatSpeed(s)),
                trailing: (s - current).abs() < 0.01
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
        ],
      ),
    );
    if (picked != null) await handler.setSpeed(picked);
  }

  Future<void> _pickSleepTimer(AudiobookHandler handler) async {
    final timer = handler.sleepTimer;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SheetShell(
        title: '睡眠定时',
        children: [
            for (final minutes in [10, 20, 30, 45, 60, 90])
              ListTile(
                title: Text('$minutes 分钟后停止'),
                onTap: () {
                  timer.startDuration(Duration(minutes: minutes));
                  Navigator.pop(ctx);
                },
              ),
            ListTile(
              title: const Text('播完本章后停止'),
              onTap: () {
                timer.startEndOfChapter();
                Navigator.pop(ctx);
              },
            ),
            if (timer.state.isActive)
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('取消定时'),
                onTap: () {
                  timer.cancel();
                  Navigator.pop(ctx);
                },
              ),
        ],
      ),
    );
  }
}

class _PositionBar extends StatelessWidget {
  const _PositionBar({required this.handler});

  final AudiobookHandler handler;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: handler.player.positionStream,
      builder: (context, posSnap) {
        final position = posSnap.data ?? Duration.zero;
        final duration = handler.player.duration ?? Duration.zero;
        final max = duration.inMilliseconds.toDouble();
        final value = position.inMilliseconds
            .clamp(0, duration.inMilliseconds)
            .toDouble();

        final theme = Theme.of(context);
        // 默认 Slider 的 thumb 半径 10，在一条听书进度上像个旋钮。
        // 收细轨道、缩小圆点。时间用等宽数字，免得秒数跳动时整行左右抖。
        final timeStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        );

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Slider(
                value: max == 0 ? 0 : value,
                max: max == 0 ? 1 : max,
                onChanged: max == 0
                    ? null
                    : (v) => handler.seek(Duration(milliseconds: v.round())),
              ),
            ),
            Padding(
              // 与 Slider 自带的左右内边距对齐，免得时间比轨道更靠外
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDuration(position), style: timeStyle),
                  Text(formatDuration(duration), style: timeStyle),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.handler});

  final AudiobookHandler handler;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlayerState>(
      stream: handler.player.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final playing = state?.playing ?? false;
        final loading = state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_previous),
              onPressed: handler.skipToPrevious,
            ),
            IconButton(
              iconSize: 32,
              tooltip: '快退 15 秒',
              icon: const _SkipIcon(forward: false),
              onPressed: handler.rewind15,
            ),
            SizedBox(
              width: 72,
              height: 72,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : IconButton.filled(
                      iconSize: 44,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: playing ? handler.pause : handler.play,
                    ),
            ),
            IconButton(
              iconSize: 32,
              tooltip: '快进 15 秒',
              icon: const _SkipIcon(forward: true),
              onPressed: handler.forward15,
            ),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_next),
              onPressed: handler.skipToNext,
            ),
          ],
        );
      },
    );
  }
}

/// 底部选择弹窗的外壳。
///
/// 选项一多就会撑破小屏（实测 540x1140 上 9 个速度档溢出 153px，
/// 底部几档直接被切掉、点不到）。这里统一限高 + 可滚动，
/// 以后往里加选项也不用担心。
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        // 最多占屏幕七成，剩下的留给背景，让人知道点空白能关掉
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child:
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView(shrinkWrap: true, children: children),
            ),
          ],
        ),
      ),
    );
  }
}


/// 快退/快进 15 秒的图标。
///
/// Material 只有 replay_5 / replay_10 / replay_30，没有 15 秒那一款。
/// 之前拿 replay_10 顶着，结果按钮上印着「10」、按下去跳 15 秒
/// （规格 audio-playback 要求 15 秒），真机上一眼就能看出对不上。
/// 改成不带数字的圆形箭头叠一个「15」；快进方向做水平镜像，两边对称。
class _SkipIcon extends StatelessWidget {
  const _SkipIcon({required this.forward});

  final bool forward;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = iconTheme.size ?? 24;
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.scale(
          scaleX: forward ? -1 : 1,
          child: const Icon(Icons.replay),
        ),
        // 数字压在圆环中间，比例照着 replay_10 的观感来。
        Padding(
          padding: EdgeInsets.only(top: size * 0.06),
          child: Text(
            '15',
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w600,
              color: iconTheme.color,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// 播放页的章节列表弹窗。
///
/// 没有复用 [_SheetShell]：它接的是 children，底层 ListView 没法定位到指定项，
/// 而这里必须打开就落在当前章上——34 章的书让人从头翻毫无道理。
/// 固定行高 + initialScrollOffset 换算偏移是最省事的做法。
class _ChapterSheet extends StatefulWidget {
  const _ChapterSheet({required this.chapters, required this.currentIndex});

  final List<Chapter> chapters;
  final int currentIndex;

  @override
  State<_ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<_ChapterSheet> {
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
    final theme = Theme.of(context);
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
              child: Text('章节 · 共 ${widget.chapters.length} 章',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView.builder(
                controller: _controller,
                itemExtent: _rowHeight,
                itemCount: widget.chapters.length,
                itemBuilder: (context, i) {
                  final c = widget.chapters[i];
                  final isCurrent = i == widget.currentIndex;
                  return ListTile(
                    // 序号样式与书籍详情页的章节列表一致，两处观感不能打架
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Text('${i + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isCurrent ? theme.colorScheme.onPrimary : null,
                          )),
                    ),
                    title: Text(c.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (c.isCached)
                          Icon(Icons.offline_pin,
                              size: 18, color: theme.hintColor),
                        if (isCurrent)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.volume_up,
                                size: 18, color: theme.colorScheme.primary),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(i),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 播放页底部的次级动作（倍速 / 定时 / 章节）。
///
/// 图标在上、文字在下的等宽格子，而不是 `TextButton.icon`：后者的视觉
/// 重量明显低于主控制行，把三个常用动作显示成了附属功能。
class _PlayerAction extends StatelessWidget {
  const _PlayerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 睡眠定时启用时置位：这个状态必须一眼可见。
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        highlighted ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: highlighted ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
