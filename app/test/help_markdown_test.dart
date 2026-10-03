import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yun_audiobook/features/help/help_markdown.dart';
import 'package:yun_audiobook/features/help/help_page.dart';

void main() {
  test('解析标题、列表与段落，连续行合并成段', () {
    final lines = HelpLine.parse('# 标题\n\n## 安装\n\n第一行\n第二行\n\n- 甲\n1. 乙\n');
    expect(lines, hasLength(5));
    expect((lines[0] as HelpHeading).level, 1);
    expect((lines[1] as HelpHeading).text, '安装');
    expect(lines[2], isA<HelpParagraph>());
    expect(lines[2].text, '第一行 第二行');
    expect((lines[3] as HelpBullet).marker, '•');
    expect((lines[4] as HelpBullet).marker, '1.');
  });

  test('行内粗体与网址，句末中文标点不算进链接', () {
    final spans = helpSpans('**下载**：打开 https://a.b/c.apk ；或 https://x.y/z。');
    expect(
      spans.map((s) => s.text).toList(),
      ['下载', '：打开 ', 'https://a.b/c.apk', ' ；或 ', 'https://x.y/z', '。'],
    );
    expect(spans[0].bold, isTrue);
    expect(spans[2].url, isTrue);
    expect(spans[4].url, isTrue);
  });

  test('帮助文件里有跳转用到的章节', () {
    final lines = HelpLine.parse(File('assets/help.md').readAsStringSync());
    final headings = lines.whereType<HelpHeading>().map((h) => h.text).toSet();
    expect(headings, containsAll([HelpSections.install, HelpSections.privacy]));
  });
}
