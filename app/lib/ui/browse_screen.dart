import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../core/errors.dart';
import '../data/drive/cloud_drive_source.dart';
import '../domain/library_repository.dart';
import 'widgets/format.dart';

/// 网盘目录浏览与「加入书架」（library-catalog 规格）。
///
/// 这里刻意只有「浏览我自己的网盘」一条路径：
/// 没有分享链接导入，没有第三方资源搜索（design.md D8）。
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key, required this.path});

  final String path;

  String get _displayName {
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? '我的网盘' : parts.last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(browseProvider(path));

    return Scaffold(
      appBar: AppBar(title: Text(_displayName)),
      body: listing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e is DriveException ? e.userMessage : '$e',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(browseProvider(path)),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (entries) {
          final audio = entries.where(LibraryRepository.isAudio).toList();
          final subFolderCount = entries.where((e) => e.isDirectory).length;

          return Column(
            children: [
              _ClaimBar(
                path: path,
                audioCount: audio.length,
                subFolderCount: subFolderCount,
              ),
              Expanded(
                child: entries.isEmpty
                    ? const _EmptyFolder()
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (_, i) =>
                            _EntryTile(entry: entries[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClaimBar extends ConsumerStatefulWidget {
  const _ClaimBar({
    required this.path,
    required this.audioCount,
    required this.subFolderCount,
  });

  final String path;
  final int audioCount;
  final int subFolderCount;

  @override
  ConsumerState<_ClaimBar> createState() => _ClaimBarState();
}

class _ClaimBarState extends ConsumerState<_ClaimBar> {
  bool _busy = false;

  /// 本目录没有音频但有子目录时，仍允许认领——
  /// 子目录会被展开成连续章节（规格「含子目录的书」）。
  bool get _canClaim =>
      widget.path != '/' && (widget.audioCount > 0 || widget.subFolderCount > 0);

  /// 子目录多到不像「卷/季」，更像一个装了很多本书的书库。
  ///
  /// 真实网盘里「一个目录放一整年的书」非常常见（实测遇到过 34 个子目录的），
  /// 那种目录合成一本书毫无意义——序号在目录名上、每个子目录是完全不同的一本书。
  /// 得让用户看清楚规模再决定，而不是拿一句「可以合成一本书」把人往坑里引。
  static const int _libraryThreshold = 4;
  bool get _looksLikeLibrary =>
      widget.audioCount == 0 && widget.subFolderCount >= _libraryThreshold;

  String get _hint {
    if (widget.audioCount > 0) {
      return '本文件夹有 ${widget.audioCount} 个音频文件';
    }
    if (_looksLikeLibrary) {
      return '这里有 ${widget.subFolderCount} 个子文件夹，看起来是个书库。'
          '建议点进去逐本添加——合成一本会把它们串成一长串。';
    }
    if (widget.subFolderCount > 0) {
      return '本文件夹没有音频，${widget.subFolderCount} 个子文件夹可以合成一本书';
    }
    return '本文件夹没有可识别的音频文件';
  }

  Future<void> _claim() async {
    setState(() => _busy = true);
    final services = ref.read(servicesProvider);
    try {
      final before = await services.dao.bookByFolder(widget.path);
      final book = await services.library.claimFolder(widget.path);
      services.sync.markDirty();
      ref.invalidate(shelfProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(before != null
            ? '《${book.title}》已在书架中'
            : '已加入书架：《${book.title}》（${book.chapterCount} 章）'),
      ));
      if (before == null && mounted) Navigator.of(context).pop();
    } on DriveException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _looksLikeLibrary ? theme.colorScheme.error : null,
                ),
              ),
            ),
            FilledButton.tonal(
              onPressed: _canClaim && !_busy ? _claim : null,
              child: Text(_busy
                  ? '处理中…'
                  : _looksLikeLibrary
                      ? '仍要合成一本'
                      : '加入书架'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});

  final DriveEntry entry;

  @override
  Widget build(BuildContext context) {
    final isAudio = LibraryRepository.isAudio(entry);
    return ListTile(
      leading: Icon(entry.isDirectory
          ? Icons.folder
          : isAudio
              ? Icons.audiotrack
              : Icons.insert_drive_file_outlined),
      title: Text(entry.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: entry.isDirectory ? null : Text(formatBytes(entry.size)),
      trailing: entry.isDirectory ? const Icon(Icons.chevron_right) : null,
      enabled: entry.isDirectory || isAudio,
      onTap: entry.isDirectory
          ? () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BrowseScreen(path: entry.path),
              ))
          : null,
    );
  }
}

class _EmptyFolder extends StatelessWidget {
  const _EmptyFolder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 56, color: theme.hintColor),
          const SizedBox(height: 12),
          Text('这个文件夹是空的',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor)),
        ],
      ),
    );
  }
}
