import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';

part 'account_controller.g.dart';

@riverpod
class AccountController extends _$AccountController {
  @override
  void build() {}

  /// 退出登录。必须一并清掉地址缓存——旧令牌拼出的地址已无意义
  /// （netdisk-auth 规格「用户主动退出登录」）。书架与进度保留在本机。
  Future<void> signOut() async {
    ref.read(servicesProvider).resolver.clear();
    await ref.read(playbackSessionProvider).stop();
    await ref.read(authRepositoryProvider).signOut();
  }
}

/// 来电等打断结束后是否自动继续。只存在内存里，与原来一致。
@riverpod
class ResumeAfterInterruption extends _$ResumeAfterInterruption {
  @override
  bool build() => ref.watch(audioBridgeProvider).resumeAfterInterruption;

  void set({required bool value}) {
    ref.read(audioBridgeProvider).resumeAfterInterruption = value;
    state = value;
  }
}
