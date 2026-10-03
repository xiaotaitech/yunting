import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yun_audiobook/features/help/help_markdown.dart';
import 'package:yun_audiobook/l10n/l10n.dart';

/// 帮助各节的锚点：更新弹窗等处按锚点直接跳到对应章节。
abstract final class HelpSections {
  static const install = '安装与更新';
  static const privacy = '隐私';
}

/// 使用帮助（app-help 规格）：内容来自 assets/help.md。
/// [section] 为要跳到的标题。
class HelpPage extends StatefulWidget {
  const HelpPage({super.key, this.section});

  final String? section;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  late final Future<List<HelpLine>> _lines =
      rootBundle.loadString('assets/help.md').then(HelpLine.parse);

  final GlobalKey _sectionKey = GlobalKey();
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.helpTitle)),
      body: FutureBuilder<List<HelpLine>>(
        future: _lines,
        builder: (context, snap) {
          final lines = snap.data;
          if (lines == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final target = widget.section;
          final index = target == null
              ? -1
              : lines.indexWhere((l) => l is HelpHeading && l.text == target);
          if (index >= 0) {
            // 章节在列表中间，用 Column + ensureVisible 比按偏移估算准
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final ctx = _sectionKey.currentContext;
              if (ctx != null) {
                Scrollable.ensureVisible(
                  ctx,
                  duration: const Duration(milliseconds: 250),
                );
              }
            });
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < lines.length; i++)
                  KeyedSubtree(
                    key: i == index ? _sectionKey : null,
                    child: _line(context, lines[i]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _line(BuildContext context, HelpLine l) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyMedium?.copyWith(height: 1.55);
    switch (l) {
      case HelpHeading(:final level):
        // 一级标题就是 AppBar 上的「使用帮助」，正文里不再重复
        if (level == 1) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(top: level == 2 ? 24 : 16, bottom: 6),
          child: Text(
            l.text,
            style: (level == 2
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.titleMedium)
                ?.copyWith(
              fontWeight: FontWeight.bold,
              color: level == 2 ? theme.colorScheme.primary : null,
            ),
          ),
        );
      case HelpBullet(:final marker):
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  marker,
                  style: body?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(child: _rich(context, l.text, body)),
            ],
          ),
        );
      case HelpParagraph():
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _rich(context, l.text, body),
        );
    }
  }

  TapGestureRecognizer _tap(String url) {
    final r = TapGestureRecognizer()
      ..onTap =
          () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    _recognizers.add(r);
    return r;
  }

  Widget _rich(BuildContext context, String text, TextStyle? style) {
    final link = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final s in helpSpans(text))
            if (s.url)
              TextSpan(
                text: s.text,
                style: link,
                recognizer: _tap(s.text),
              )
            else
              TextSpan(
                text: s.text,
                style: s.bold
                    ? const TextStyle(fontWeight: FontWeight.bold)
                    : null,
              ),
        ],
      ),
    );
  }
}
