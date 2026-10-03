import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';

part 'sync_controller.g.dart';

/// 手动同步。状态是「是否正在同步」，同步按钮据此转圈。
///
/// keepAlive：同步要几秒，期间用户可能离开页面；自动释放的话 await 之后
/// 再写 state 会抛错，转圈也会卡住。
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  @override
  bool build() => false;

  /// 返回是否成功。正在同步时直接返回 false，不叠加。
  Future<bool> syncNow() async {
    if (state) return false;
    state = true;
    try {
      return await ref.read(librarySyncProvider).syncNow();
    } finally {
      state = false;
    }
  }
}
