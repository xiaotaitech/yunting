import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/data/drive/cloud_drive_source.dart';
import 'package:yun_audiobook/domain/media_files.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/library/widgets/claim_bar.dart';
import 'package:yun_audiobook/features/library/widgets/drive_entry_tile.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 网盘目录浏览与「加入书架」（library-catalog 规格）。
///
/// 这里刻意只有「浏览我自己的网盘」一条路径：
/// 没有分享链接导入，没有第三方资源搜索（design.md D8）。
class BrowsePage extends ConsumerWidget {
  const BrowsePage({required this.path, super.key});

  final String path;

  String _displayName(AppLocalizations l) {
    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? l.browseRootName : parts.last;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final listing = ref.watch(browseProvider(path));

    return Scaffold(
      appBar: AppBar(title: Text(_displayName(l))),
      body: listing.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.anyError(e), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(browseProvider(path)),
                  child: Text(l.actionRetry),
                ),
              ],
            ),
          ),
        ),
        data: (entries) => _Listing(path: path, entries: entries),
      ),
    );
  }
}

class _Listing extends StatelessWidget {
  const _Listing({required this.path, required this.entries});

  final String path;
  final List<DriveEntry> entries;

  @override
  Widget build(BuildContext context) {
    final audio = entries.where(isMediaEntry).toList();
    final subFolderCount = entries.where((e) => e.isDirectory).length;

    return Column(
      children: [
        ClaimBar(
          path: path,
          audioCount: audio.length,
          subFolderCount: subFolderCount,
        ),
        Expanded(
          child: entries.isEmpty
              ? const _EmptyFolder()
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => DriveEntryTile(
                    entry: entries[i],
                    onOpenFolder: () =>
                        context.push(Routes.browse(entries[i].path)),
                  ),
                ),
        ),
      ],
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
          Text(context.l10n.browseEmptyFolder,
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),),
        ],
      ),
    );
  }
}
