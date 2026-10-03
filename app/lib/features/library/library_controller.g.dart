// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 书架变更的唯一入口。每个改动之后都标记待同步——
/// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。

@ProviderFor(LibraryController)
final libraryControllerProvider = LibraryControllerProvider._();

/// 书架变更的唯一入口。每个改动之后都标记待同步——
/// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。
final class LibraryControllerProvider
    extends $NotifierProvider<LibraryController, void> {
  /// 书架变更的唯一入口。每个改动之后都标记待同步——
  /// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。
  LibraryControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'libraryControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$libraryControllerHash();

  @$internal
  @override
  LibraryController create() => LibraryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$libraryControllerHash() => r'98fa76da246873c6453276e36b26f5c7715f9bfa';

/// 书架变更的唯一入口。每个改动之后都标记待同步——
/// 原来 `markDirty` 散落在界面里手动调，漏一处就少同步一次。

abstract class _$LibraryController extends $Notifier<void> {
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
