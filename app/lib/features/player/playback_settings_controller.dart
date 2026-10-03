import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';

part 'playback_settings_controller.g.dart';

/// 播放相关的本地设置。keepAlive 的理由同其它命令式 controller。
@Riverpod(keepAlive: true)
class PlaybackSettingsController extends _$PlaybackSettingsController {
  @override
  void build() {}

  /// 只影响之后取流的视频；正在播的这一课不中断。
  Future<void> setVideoQuality(String quality) => ref
      .read(databaseProvider)
      .settingsDao
      .write(SettingsDao.videoQualityKey, quality);
}
