import 'package:yun_audiobook/core/errors.dart';
import 'package:yun_audiobook/domain/continue_listening.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/l10n/l10n.dart';
import 'package:yun_audiobook/playback/playback_session.dart';

/// 领域错误 / 枚举 → 面向用户的文案。core 与 domain 里不放用户文案。
extension ErrorTextX on AppLocalizations {
  String driveError(DriveException e) => switch (e.kind) {
        DriveErrorKind.authExpired || DriveErrorKind.authInvalid => errorAuth,
        DriveErrorKind.rateLimited => errorRateLimited,
        DriveErrorKind.notFound => errorNotFound,
        DriveErrorKind.noMedia => errorNoMedia,
        DriveErrorKind.network => errorNetwork,
        DriveErrorKind.linkExpired => errorLinkExpired,
        DriveErrorKind.storageFull => errorStorageFull,
        // 其他接口错误没有更好的说法，给出技术描述，至少能拿去排障
        DriveErrorKind.api => e.message,
      };

  /// 任意异常的兜底文案。
  String anyError(Object e) =>
      e is DriveException ? driveError(e) : e.toString();

  String playbackFailure(PlaybackFailure f) => f.kind == null
      ? errorPlaybackExhausted
      : driveError(DriveException(f.kind!, ''));

  String playbackHint(PlaybackHint h) => switch (h) {
        PlaybackHint.slowNetwork => hintSlowNetwork,
      };

  String notReady(NotReadyReason r) => switch (r) {
        NotReadyReason.sourceMissing => notReadySourceMissing,
        NotReadyReason.episodesPending => notReadyEpisodesPending,
        NotReadyReason.episodeGone => notReadyEpisodeGone,
      };

  /// 「章」或「课」。
  String unit(SeriesKind kind) => unitEpisode(kind.name);
}
