import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/services.dart';
import '../domain/models.dart';
import 'player_screen.dart';

/// 所有"开始听"的入口（书架、续听卡片、书籍详情、历史）共用这一条路径。
///
/// 立刻进播放页，取地址和加载在后台进行，播放页显示"准备中"。原来是等
/// 加载完、再 `await play()` 之后才跳转——而 just_audio 的 play() 要到暂停才返回，
/// 于是点了播放要么干等几秒没反应，要么声音出来了页面却不动。
/// 加载失败由播放页的 failures 提示接住，带重试。
Future<void> openPlayer(
  BuildContext context,
  WidgetRef ref,
  Book book,
  List<Chapter> chapters, {
  int? chapterIndex,
  Duration? position,
}) async {
  final services = ref.read(servicesProvider);
  final navigator = Navigator.of(context);
  unawaited(services.handler
      .start(book, chapters, chapterIndex: chapterIndex, position: position));
  await navigator.push(MaterialPageRoute(builder: (_) => const PlayerScreen()));
  // 从播放页退回来时书架的进度、续听卡片、历史都可能变了
  ref.invalidate(shelfProvider);
  ref.invalidate(historyProvider);
  ref.invalidate(bookProvider(book.id));
  ref.invalidate(chaptersProvider(book.id));
}
