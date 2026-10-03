import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
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
class ShelfPage extends ConsumerWidget {
  const ShelfPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final shelf = ref.watch(shelfProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navShelf),
        actions: const [SyncButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.addSeries),
        icon: const Icon(Icons.add),
        label: Text(l.shelfAdd),
      ),
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
                        child: ShelfTile(series: series),
                      ),
                    // 续听卡片放在书架下面：手够得着的地方
                    const ContinueListeningCard(),
                  ],
                ),
              ),
      ),
    );
  }
}
