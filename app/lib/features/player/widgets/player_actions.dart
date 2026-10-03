import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/player/widgets/chapter_sheet.dart';
import 'package:yun_audiobook/features/player/widgets/player_action.dart';
import 'package:yun_audiobook/features/player/widgets/sheet_shell.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';
import 'package:yun_audiobook/playback/sleep_timer.dart';

/// 倍速 / 定时 / 章节。原来是三个 TextButton.icon，视觉重量比主
/// 控制行低一档，把常用动作显示成了附属功能。改成图标在上、文字
/// 在下的等宽三格，与播放键同级（帆书那排也是这么处理的）。
class PlayerActions extends ConsumerWidget {
  const PlayerActions({required this.kind, super.key});

  final SeriesKind kind;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.read(playbackSessionProvider);
    final speed = ref.watch(
      playbackProvider.select((s) => s.value?.engine.speed ?? 1.0),
    );
    return Row(
      children: [
        Expanded(
          child: PlayerAction(
            icon: Icons.speed,
            label: formatSpeed(speed),
            onTap: () => _pickSpeed(context, session),
          ),
        ),
        Expanded(
          child: StreamBuilder<SleepTimerState>(
            stream: session.sleepTimer.changes,
            initialData: session.sleepTimer.state,
            builder: (context, snap) {
              final s = snap.data ?? SleepTimerState.off;
              return PlayerAction(
                icon: s.isActive ? Icons.bedtime : Icons.bedtime_outlined,
                label: _sleepLabel(l, s),
                // 定时开着的时候必须看得出来，否则用户不知道
                // 会不会突然停
                highlighted: s.isActive,
                onTap: () => _pickSleepTimer(context, session),
              );
            },
          ),
        ),
        Expanded(
          // 播放页直达章节列表。切章是听书时的高频动作，原来只能退回
          // 书籍详情页（返回 → 找章节 → 点），两层跳转太重。
          child: PlayerAction(
            icon: Icons.playlist_play,
            label: l.playerEpisodes(kind.name),
            onTap: () => _pickChapter(context, session),
          ),
        ),
      ],
    );
  }

  String _sleepLabel(AppLocalizations l, SleepTimerState s) {
    switch (s.mode) {
      case SleepTimerMode.off:
        return l.playerSleepLabel;
      case SleepTimerMode.duration:
        return formatDuration(s.remaining ?? Duration.zero);
      case SleepTimerMode.endOfChapter:
        return l.playerSleepEndOfEpisodeShort(l.unit(kind));
    }
  }

  Future<void> _pickChapter(
    BuildContext context,
    PlaybackSession session,
  ) async {
    final snap = session.current;
    if (snap.episodes.isEmpty) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      // 不开 isScrollControlled 时弹窗最高只有屏高 9/16，几十章的书
      // 够不到 ChapterSheet 自己的七成上限，白留一截空间。
      isScrollControlled: true,
      builder: (_) => ChapterSheet(
        kind: kind,
        episodes: snap.episodes,
        currentIndex: snap.index,
      ),
    );
    if (picked == null || picked == snap.index) return;
    await session.playAt(picked);
  }

  Future<void> _pickSpeed(BuildContext context, PlaybackSession session) async {
    final current = session.current.engine.speed;
    final title = context.l10n.playerSpeedTitle;
    final picked = await showModalBottomSheet<double>(
      context: context,
      // 9 个速度档在小屏上撑得下底部弹窗（实测 540x1140 溢出 153px），
      // 必须可滚动 + 限高，否则底部选项直接被切掉、够不着。
      isScrollControlled: true,
      builder: (ctx) => SheetShell(
        title: title,
        children: [
          for (final s in _speeds)
            ListTile(
              title: Text(formatSpeed(s)),
              trailing:
                  (s - current).abs() < 0.01 ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(ctx, s),
            ),
        ],
      ),
    );
    if (picked != null) await session.setSpeed(picked);
  }

  Future<void> _pickSleepTimer(
    BuildContext context,
    PlaybackSession session,
  ) async {
    final timer = session.sleepTimer;
    final l = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SheetShell(
        title: l.playerSleepTitle,
        children: [
          for (final minutes in [10, 20, 30, 45, 60, 90])
            ListTile(
              title: Text(l.playerSleepMinutes(minutes)),
              onTap: () {
                timer.startDuration(Duration(minutes: minutes));
                Navigator.pop(ctx);
              },
            ),
          ListTile(
            title: Text(l.playerSleepEndOfEpisode(l.unit(kind))),
            onTap: () {
              timer.startEndOfChapter();
              Navigator.pop(ctx);
            },
          ),
          if (timer.state.isActive)
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l.playerSleepCancel),
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
