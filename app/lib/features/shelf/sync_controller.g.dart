// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 手动同步。状态是「是否正在同步」，同步按钮据此转圈。

@ProviderFor(SyncController)
final syncControllerProvider = SyncControllerProvider._();

/// 手动同步。状态是「是否正在同步」，同步按钮据此转圈。
final class SyncControllerProvider
    extends $NotifierProvider<SyncController, bool> {
  /// 手动同步。状态是「是否正在同步」，同步按钮据此转圈。
  SyncControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'syncControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$syncControllerHash();

  @$internal
  @override
  SyncController create() => SyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$syncControllerHash() => r'a0c07279448e7406e30db4ccc9c7fb29185b9b23';

/// 手动同步。状态是「是否正在同步」，同步按钮据此转圈。

abstract class _$SyncController extends $Notifier<bool> {
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
