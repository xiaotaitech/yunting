// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 所有「开始听」的入口（书架、续听卡片、详情、历史、离线）共用这一条路径。
/// 原来这段判断在三个页面里各写一份，迟早会对同一种异常给出三种反应。

@ProviderFor(PlaybackController)
final playbackControllerProvider = PlaybackControllerProvider._();

/// 所有「开始听」的入口（书架、续听卡片、详情、历史、离线）共用这一条路径。
/// 原来这段判断在三个页面里各写一份，迟早会对同一种异常给出三种反应。
final class PlaybackControllerProvider
    extends $NotifierProvider<PlaybackController, void> {
  /// 所有「开始听」的入口（书架、续听卡片、详情、历史、离线）共用这一条路径。
  /// 原来这段判断在三个页面里各写一份，迟早会对同一种异常给出三种反应。
  PlaybackControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'playbackControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$playbackControllerHash();

  @$internal
  @override
  PlaybackController create() => PlaybackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$playbackControllerHash() =>
    r'432df4b22bf75dda267e6e0e00dcef9429849201';

/// 所有「开始听」的入口（书架、续听卡片、详情、历史、离线）共用这一条路径。
/// 原来这段判断在三个页面里各写一份，迟早会对同一种异常给出三种反应。

abstract class _$PlaybackController extends $Notifier<void> {
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
