import 'package:flutter/material.dart';
import 'package:yun_audiobook/domain/entities.dart';
import 'package:yun_audiobook/features/common/error_text.dart';
import 'package:yun_audiobook/features/common/format.dart';
import 'package:yun_audiobook/features/common/widgets/series_cover.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

class SeriesHeader extends StatelessWidget {
  const SeriesHeader({required this.series, required this.episodes, super.key});

  final Series series;
  final List<Episode> episodes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final unit = l.unit(series.kind);
    final cached = episodes.where((e) => e.isCached).length;
    final total = episodes.fold<int>(0, (a, e) => a + e.size);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SeriesCover(
            title: series.title,
            coverFsId: series.coverFsId,
            width: 84,
            height: 112,
            radius: 12,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(series.title, style: theme.textTheme.titleLarge),
                if (series.author != null)
                  Text(
                    series.author!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.hintColor),
                  ),
                const SizedBox(height: 8),
                Text(
                  l.detailSummary(episodes.length, unit, formatBytes(total)),
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  l.detailOfflineCount(cached, episodes.length, unit),
                  style: theme.textTheme.bodySmall,
                ),
                if (series.sourceMissing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l.detailSourceMissing,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
