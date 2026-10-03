// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AccountController)
final accountControllerProvider = AccountControllerProvider._();

final class AccountControllerProvider
    extends $NotifierProvider<AccountController, void> {
  AccountControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'accountControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$accountControllerHash();

  @$internal
  @override
  AccountController create() => AccountController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$accountControllerHash() => r'4878b1183e0cabe9d4fe68625e1feb28a5b3dfb3';

abstract class _$AccountController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// 来电等打断结束后是否自动继续。只存在内存里，与原来一致。

@ProviderFor(ResumeAfterInterruption)
final resumeAfterInterruptionProvider = ResumeAfterInterruptionProvider._();

/// 来电等打断结束后是否自动继续。只存在内存里，与原来一致。
final class ResumeAfterInterruptionProvider
    extends $NotifierProvider<ResumeAfterInterruption, bool> {
  /// 来电等打断结束后是否自动继续。只存在内存里，与原来一致。
  ResumeAfterInterruptionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'resumeAfterInterruptionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$resumeAfterInterruptionHash();

  @$internal
  @override
  ResumeAfterInterruption create() => ResumeAfterInterruption();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$resumeAfterInterruptionHash() =>
    r'4da24757a472d849276dfad55ae9d964618eccd4';

/// 来电等打断结束后是否自动继续。只存在内存里，与原来一致。

abstract class _$ResumeAfterInterruption extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
