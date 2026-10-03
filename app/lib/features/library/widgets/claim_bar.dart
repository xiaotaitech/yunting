import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class ClaimBar extends ConsumerStatefulWidget {
  const ClaimBar({
    required this.path,
    required this.audioCount,
    required this.subFolderCount,
    super.key,
  });

  final String path;
  final int audioCount;
  final int subFolderCount;

  @override
  ConsumerState<ClaimBar> createState() => _ClaimBarState();
}

class _ClaimBarState extends ConsumerState<ClaimBar> {
  bool _busy = false;

  /// 本目录没有音频但有子目录时，仍允许认领——
  /// 子目录会被展开成连续章节（规格「含子目录的书」）。
  bool get _canClaim =>
      widget.path != '/' &&
      (widget.audioCount > 0 || widget.subFolderCount > 0);

  /// 子目录多到不像「卷/季」，更像一个装了很多本书的书库。
  ///
  /// 真实网盘里「一个目录放一整年的书」非常常见（实测遇到过 34 个子目录的），
  /// 那种目录合成一本书毫无意义——序号在目录名上、每个子目录是完全不同的一本书。
  /// 得让用户看清楚规模再决定，而不是拿一句「可以合成一本书」把人往坑里引。
  static const int _libraryThreshold = 4;
  bool get _looksLikeLibrary =>
      widget.audioCount == 0 && widget.subFolderCount >= _libraryThreshold;

  String _hint(AppLocalizations l) {
    if (widget.audioCount > 0) return l.browseHintAudio(widget.audioCount);
    if (_looksLikeLibrary) return l.browseHintLibrary(widget.subFolderCount);
    if (widget.subFolderCount > 0) {
      return l.browseHintFolders(widget.subFolderCount);
    }
    return l.browseHintNone;
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final before = ref.read(seriesAtFolderProvider(widget.path)).value;
      final series =
          await ref.read(libraryControllerProvider.notifier).claim(widget.path);
      if (!mounted) return;
      if (before != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l.browseAlreadyOnShelf(series.title))),
        );
        return;
      }
      // 直接回到书架：原来只退一层，从「我的有声书/三体」加完书还得连按几次返回，
      // 按多了就退出了应用
      context.go(Routes.shelf);
      messenger.showSnackBar(SnackBar(
        content: Text(l.browseAdded(
            series.title, series.episodeCount, l.unit(series.kind),),),
      ),);
    } on DriveException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.driveError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    // 已经在书架上的文件夹：按钮照样亮着、点了才说"已在书架中"不如
    // 直接说明，并给一个进书的入口。
    final existing = ref.watch(seriesAtFolderProvider(widget.path)).value;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: existing != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(l.browseAlreadyOnShelf(existing.title),
                        style: theme.textTheme.bodySmall,),
                  ),
                  FilledButton.tonal(
                    onPressed: () => context.push(Routes.series(existing.id)),
                    child: Text(l.browseView),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Text(
                      _hint(l),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            _looksLikeLibrary ? theme.colorScheme.error : null,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: _canClaim && !_busy ? _claim : null,
                    child: Text(_busy
                        ? l.browseBusy
                        : _looksLikeLibrary
                            ? l.browseClaimAnyway
                            : l.browseClaim,),
                  ),
                ],
              ),
      ),
    );
  }
}
