import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/domain/local_media.dart';
import 'package:yun_audiobook/domain/media_folders.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/empty_state.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 添加书籍：直接列出网盘里所有装着音频的文件夹，可按关键字筛选。
///
/// 原来只能从根目录一层层点进去找，书放得深就要点五六下。现在一进来
/// 就是全部候选，刚传上去的排最前面；搜「三体」连「三体/卷一」也能找到。
/// 「按目录浏览」仍保留，给要把多个子文件夹合成一本的情况用。
class AddSeriesPage extends ConsumerStatefulWidget {
  const AddSeriesPage({super.key});

  @override
  ConsumerState<AddSeriesPage> createState() => _AddSeriesPageState();
}

class _AddSeriesPageState extends ConsumerState<AddSeriesPage> {
  final _query = TextEditingController();

  /// 有声书（含音频的文件夹）还是课程（含视频的文件夹）。
  MediaKind _kind = MediaKind.audio;

  /// 从网盘加，还是从这台手机里加（add-local-media）。
  bool _device = false;

  Future<void> _grant() async {
    await ref.read(servicesProvider).localMedia.requestPermission(_kind);
    ref
      ..invalidate(localMediaPermissionProvider(_kind))
      ..invalidate(localMediaFoldersProvider(_kind));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final folders = _device
        ? ref.watch(localMediaFoldersProvider(_kind))
        : ref.watch(mediaFoldersProvider(_kind));
    final granted = !_device ||
        (ref.watch(localMediaPermissionProvider(_kind)).value ?? true);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.shelfAdd),
        actions: [
          // 按目录逐层浏览只对网盘有意义
          if (!_device)
            TextButton.icon(
              onPressed: () => context.push(Routes.browse('/')),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l.addBrowseByFolder),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(168),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.cloud_outlined),
                        label: Text(l.addOriginNetdisk),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.smartphone_outlined),
                        label: Text(l.addOriginDevice),
                      ),
                    ],
                    selected: {_device},
                    onSelectionChanged: (s) =>
                        setState(() => _device = s.first),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<MediaKind>(
                    segments: [
                      ButtonSegment(
                        value: MediaKind.audio,
                        icon: const Icon(Icons.headphones_outlined),
                        label: Text(l.addKindAudiobook),
                      ),
                      ButtonSegment(
                        value: MediaKind.video,
                        icon: const Icon(Icons.ondemand_video_outlined),
                        label: Text(l.addKindCourse),
                      ),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                ),
                const SizedBox(height: 8),
                SearchBar(
                  controller: _query,
                  hintText: _device ? l.addSearchHintDevice : l.addSearchHint,
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (_) => setState(() {}),
                  trailing: [
                    if (_query.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: l.addSearchClear,
                        onPressed: () => setState(_query.clear),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: !granted
          ? EmptyState(
              icon: Icons.lock_open_outlined,
              title: l.addDevicePermissionTitle,
              description: _kind == MediaKind.video
                  ? l.addDevicePermissionVideo
                  : l.addDevicePermissionAudio,
              action: FilledButton(onPressed: _grant, child: Text(l.addGrant)),
            )
          : folders.when(
              // 刷新时保留旧列表，不要整页闪成转圈
              skipLoadingOnRefresh: true,
              loading: () => _Scanning(
                label: _kind == MediaKind.video
                    ? l.addScanningCourses
                    : l.addScanning,
              ),
              error: (e, _) => EmptyState(
                icon: Icons.cloud_off_outlined,
                title: l.addScanFailed,
                description: l.anyError(e),
                action: FilledButton(
                  onPressed: () => ref.invalidate(
                    _device
                        ? localMediaFoldersProvider(_kind)
                        : mediaFoldersProvider(_kind),
                  ),
                  child: Text(l.actionRetry),
                ),
              ),
              data: (all) => RefreshIndicator(
                onRefresh: () => _device
                    ? ref.refresh(localMediaFoldersProvider(_kind).future)
                    : ref.refresh(mediaFoldersProvider(_kind).future),
                child: _FolderList(
                  kind: _kind,
                  all: all,
                  visible: filterFolders(all, _query.text),
                  query: _query.text,
                ),
              ),
            ),
    );
  }
}

class _Scanning extends StatelessWidget {
  const _Scanning({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      );
}

class _FolderList extends ConsumerWidget {
  const _FolderList({
    required this.kind,
    required this.all,
    required this.visible,
    required this.query,
  });

  final MediaKind kind;
  final List<MediaFolder> all;
  final List<MediaFolder> visible;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // 书架上的文件夹集合：行尾显示「已在书架」而不是加号
    final shelf = ref.watch(shelfProvider).value ?? const <Series>[];
    final onShelf = {for (final s in shelf) s.folderPath};

    if (visible.isEmpty) {
      // 下拉刷新要求可滚动，空状态也放进 ListView
      return ListView(
        children: [
          const SizedBox(height: 80),
          EmptyState(
            icon: Icons.search_off,
            title: all.isEmpty
                ? (kind == MediaKind.video
                    ? l.addNoVideoAnywhere
                    : l.addNoAudioAnywhere)
                : l.addNoMatch(query),
            description: all.isEmpty ? null : l.addNoMatchHint,
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: visible.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(
              query.isEmpty
                  ? (kind == MediaKind.video
                      ? l.addCourseFolderCount(all.length)
                      : l.addFolderCount(all.length))
                  : l.addMatchCount(visible.length),
              style: Theme.of(context).textTheme.labelMedium,
            ),
          );
        }
        final f = visible[i - 1];
        return _FolderTile(
          folder: f,
          kind: kind,
          onShelf: onShelf.contains(f.path),
        );
      },
    );
  }
}

class _FolderTile extends ConsumerStatefulWidget {
  const _FolderTile({
    required this.folder,
    required this.kind,
    required this.onShelf,
  });

  final MediaFolder folder;
  final MediaKind kind;
  final bool onShelf;

  @override
  ConsumerState<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends ConsumerState<_FolderTile> {
  bool _busy = false;

  /// 一键加入，但留在本页：加书往往是一次加好几本，
  /// 每加一本就被弹回书架反而更麻烦。
  Future<void> _add() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final s = await ref
          .read(libraryControllerProvider.notifier)
          .claim(widget.folder.path);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l.browseAdded(s.title, s.episodeCount, l.unit(s.kind))),
        ),
      );
    } on DriveException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.driveError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final f = widget.folder;
    return ListTile(
      leading: Icon(
        widget.kind == MediaKind.video
            ? Icons.video_library_outlined
            : Icons.library_music_outlined,
      ),
      title: Text(f.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${widget.kind == MediaKind.video ? l.addVideoCount(f.mediaCount) : l.addAudioCount(f.mediaCount)} · ${formatBytes(f.totalBytes)}\n'
        '${displayPath(f.parentPath)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: true,
      // 点行进入该文件夹预览（可看到全部文件、决定要不要加）
      onTap: () => context.push(Routes.browse(f.path)),
      trailing: widget.onShelf
          ? Text(
              l.addOnShelf,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            )
          : _busy
              ? const SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  tooltip: l.browseClaim,
                  onPressed: _add,
                ),
    );
  }
}
