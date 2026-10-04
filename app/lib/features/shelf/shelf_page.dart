import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/library/library_controller.dart';
import 'package:yun_audiobook/features/shelf/widgets/continue_card.dart';
import 'package:yun_audiobook/features/shelf/widgets/empty_shelf.dart';
import 'package:yun_audiobook/features/shelf/widgets/shelf_error_view.dart';
import 'package:yun_audiobook/features/shelf/widgets/shelf_tile.dart';
import 'package:yun_audiobook/features/shelf/widgets/sync_button.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 书架（library-catalog 规格「书架管理」）。
///
/// 列表下方是「继续收听」卡片（listening-progress 规格「首页续听入口」）：
/// 打开 App 最常见的诉求就是接着上次听，不该让用户先在一列同构卡片里
/// 认出那本书。放在下方而不是顶部，是因为那里离拇指更近。
class ShelfPage extends ConsumerStatefulWidget {
  const ShelfPage({super.key});

  @override
  ConsumerState<ShelfPage> createState() => _ShelfPageState();
}

class _ShelfPageState extends ConsumerState<ShelfPage> {
  /// 书架管理模式（批量移出）。长按任意一本或点「管理」进入。
  bool _managing = false;
  final Set<String> _selected = {};

  void _enter([String? firstId]) => setState(() {
        _managing = true;
        if (firstId != null) _selected.add(firstId);
      });

  void _exit() => setState(() {
        _managing = false;
        _selected.clear();
      });

  void _toggle(String id) => setState(() {
        if (!_selected.remove(id)) _selected.add(id);
      });

  Future<void> _removeSelected(List<Series> shelf) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final chosen = shelf.where((s) => _selected.contains(s.id)).toList();
    if (chosen.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shelfRemoveTitle(chosen.length)),
        content: Text(l.shelfRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.shelfRemoveConfirm),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final library = ref.read(libraryControllerProvider.notifier);
    await library.removeMany(chosen);
    _exit();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l.shelfRemoved(chosen.length)),
        // 比清缓存的等待（LibraryController.undoWindow）短，撤销时缓存一定还在
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l.shelfUndo,
          onPressed: () => library.undoRemove(chosen),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shelf = ref.watch(shelfProvider);
    final list = shelf.value ?? const <Series>[];
    // 书被别处移走（比如另一台设备同步过来）时，选中集合里别留着它
    _selected.removeWhere((id) => !list.any((s) => s.id == id));
    final allSelected = list.isNotEmpty && _selected.length == list.length;

    return PopScope(
      // 管理模式下返回键先退出管理，而不是离开书架
      canPop: !_managing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _managing) _exit();
      },
      child: Scaffold(
        appBar: _managing
            ? AppBar(
                leading: IconButton(
                  tooltip: l.shelfManageDone,
                  icon: const Icon(Icons.close),
                  onPressed: _exit,
                ),
                title: Text(l.shelfSelectedCount(_selected.length)),
                actions: [
                  TextButton(
                    onPressed: () => setState(() {
                      allSelected
                          ? _selected.clear()
                          : _selected.addAll(list.map((s) => s.id));
                    }),
                    child: Text(
                        allSelected ? l.shelfSelectNone : l.shelfSelectAll),
                  ),
                ],
              )
            : AppBar(
                title: Text(l.navShelf),
                actions: [
                  if (list.isNotEmpty)
                    IconButton(
                      tooltip: l.shelfManage,
                      icon: const Icon(Icons.checklist),
                      onPressed: _enter,
                    ),
                  const SyncButton(),
                ],
              ),
        floatingActionButton: _managing
            ? null
            : FloatingActionButton.extended(
                onPressed: () => context.push(Routes.addSeries),
                icon: const Icon(Icons.add),
                label: Text(l.shelfAdd),
              ),
        bottomNavigationBar: _managing
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed:
                        _selected.isEmpty ? null : () => _removeSelected(list),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l.shelfRemoveAction(_selected.length)),
                  ),
                ),
              )
            : null,
        body: shelf.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ShelfErrorView(
            message: l.anyError(e),
            onRetry: () => ref.invalidate(shelfProvider),
          ),
          data: (list) => list.isEmpty
              ? const EmptyShelf()
              : RefreshIndicator(
                  // 等新数据回来再收起转圈；只 invalidate 不等的话，
                  // 下拉的圈一闪就没了，看不出刷没刷
                  onRefresh: () => ref.refresh(shelfProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
                    children: [
                      for (final series in list)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ShelfTile(
                            series: series,
                            selecting: _managing,
                            selected: _selected.contains(series.id),
                            onToggle: () => _toggle(series.id),
                            onLongPress: () => _enter(series.id),
                          ),
                        ),
                      // 续听卡片放在书架下面：手够得着的地方。管理模式下不显示
                      if (!_managing) const ContinueListeningCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
