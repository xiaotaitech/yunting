import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';

/// 手动拖动调整章节顺序（规格「手动调整顺序」）。
class ReorderableEpisodes extends ConsumerStatefulWidget {
  const ReorderableEpisodes({
    required this.series,
    required this.episodes,
    super.key,
  });

  final Series series;
  final List<Episode> episodes;

  @override
  ConsumerState<ReorderableEpisodes> createState() =>
      _ReorderableEpisodesState();
}

class _ReorderableEpisodesState extends ConsumerState<ReorderableEpisodes> {
  late final List<Episode> _items = [...widget.episodes];

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: _items.length,
      // onReorderItem 已经替我们修正过移除后的下标，不用再手动减一
      onReorderItem: (oldIndex, newIndex) async {
        setState(() {
          final item = _items.removeAt(oldIndex);
          _items.insert(newIndex, item);
        });
        await ref
            .read(libraryControllerProvider.notifier)
            .reorder(widget.series, _items);
      },
      itemBuilder: (context, i) => ListTile(
        key: ValueKey(_items[i].id),
        leading: const Icon(Icons.drag_handle),
        title:
            Text(_items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          _items[i].fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
