/// 使用帮助用到的 Markdown 子集（design.md D5）：标题、列表、段落，
/// 行内只有 `**粗体**` 和裸网址。够用，不引入 Markdown 渲染依赖。
sealed class HelpLine {
  const HelpLine(this.text);

  final String text;

  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _bullet = RegExp(r'^(?:[-*]|(\d+)\.)\s+(.*)$');

  /// 按行解析。连续的普通行合并成一个段落，空行结束段落。
  static List<HelpLine> parse(String markdown) {
    final out = <HelpLine>[];
    final para = <String>[];
    void flush() {
      if (para.isNotEmpty) out.add(HelpParagraph(para.join(' ')));
      para.clear();
    }

    for (final raw in markdown.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) {
        flush();
        continue;
      }
      final h = _heading.firstMatch(line);
      if (h != null) {
        flush();
        out.add(HelpHeading(h.group(1)!.length, h.group(2)!.trim()));
        continue;
      }
      final b = _bullet.firstMatch(line);
      if (b != null) {
        flush();
        out.add(
          HelpBullet(
            b.group(1) == null ? '•' : '${b.group(1)}.',
            b.group(2)!.trim(),
          ),
        );
        continue;
      }
      para.add(line);
    }
    flush();
    return out;
  }
}

class HelpHeading extends HelpLine {
  const HelpHeading(this.level, super.text);

  final int level;
}

class HelpBullet extends HelpLine {
  const HelpBullet(this.marker, super.text);

  final String marker;
}

class HelpParagraph extends HelpLine {
  const HelpParagraph(super.text);
}

/// 行内片段：普通文字、粗体或网址。
class HelpSpan {
  const HelpSpan(this.text, {this.bold = false, this.url = false});

  final String text;
  final bool bold;
  final bool url;
}

// 网址到空白或中文标点为止，句末的"。"不算进链接
final _inline = RegExp(r'\*\*(.+?)\*\*|(https?://[^\s，。、；）)」]+)');

List<HelpSpan> helpSpans(String text) {
  final out = <HelpSpan>[];
  var last = 0;
  for (final m in _inline.allMatches(text)) {
    if (m.start > last) out.add(HelpSpan(text.substring(last, m.start)));
    final bold = m.group(1);
    out.add(
      bold != null
          ? HelpSpan(bold, bold: true)
          : HelpSpan(m.group(0)!, url: true),
    );
    last = m.end;
  }
  if (last < text.length) out.add(HelpSpan(text.substring(last)));
  return out;
}
