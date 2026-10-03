import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';

part 'account_controller.g.dart';

/// keepAlive：这是无状态的命令入口，没有人 watch 它。自动释放的话，
/// 方法里第一个 await 之后 provider 就已被回收，再 ref.read 会直接抛错
/// （真机上「加入书架」就这样静默失败过）。
@Riverpod(keepAlive: true)
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
