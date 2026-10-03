import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yun_audiobook/app/routes.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/player/playback_controller.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 续播入口。首页续听卡片与书架条目上的播放键共用这一条路径——
/// 分成两份的话，两个入口迟早会对同一种异常给出两种反应，
/// 而异常正是用户最容易撞见的地方。
Future<void> resumeSeries(
  BuildContext context,
  WidgetRef ref,
  Series series,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  final result =
      await ref.read(playbackControllerProvider.notifier).resume(series);
  if (!context.mounted) return;
  switch (result) {
    case OpenStarted() || OpenAlreadyPlaying():
      await context.push(Routes.player);
    case OpenNotReady(:final reason):
      messenger.showSnackBar(SnackBar(content: Text(l.notReady(reason))));
  }
}
