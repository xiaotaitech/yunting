/// 章节自然序排序（library-catalog 规格「章节自然序排列」）。
///
/// 字典序会把「第10章」排在「第2章」前面，这在有声书里是灾难性的。
/// 这里把文件名切成「文本段」与「数字段」交替的序列，数字段按数值比较。
library;

final _digits = RegExp(r'\d+');

/// 把字符串切成 token 序列：String 表示文本段，BigInt 表示数字段。
/// 用 BigInt 是因为有些文件名里会出现超长数字（时间戳、哈希片段）。
List<Object> tokenize(String input) {
  final lower = input.toLowerCase();
  final tokens = <Object>[];
  var cursor = 0;
  for (final match in _digits.allMatches(lower)) {
    if (match.start > cursor) {
      tokens.add(lower.substring(cursor, match.start));
    }
    tokens.add(BigInt.parse(match.group(0)!));
    cursor = match.end;
  }
  if (cursor < lower.length) tokens.add(lower.substring(cursor));
  return tokens;
}

/// 自然序比较。数字段之间比数值，文本段之间比字典序；
/// 类型不同的段落固定「数字在前」，让 `1.mp3` 排在 `a.mp3` 之前。
int compareNatural(String a, String b) {
  final ta = tokenize(a);
  final tb = tokenize(b);
  final n = ta.length < tb.length ? ta.length : tb.length;

  for (var i = 0; i < n; i++) {
    final x = ta[i];
    final y = tb[i];
    if (x is BigInt && y is BigInt) {
      final c = x.compareTo(y);
      if (c != 0) return c;
    } else if (x is String && y is String) {
      final c = x.compareTo(y);
      if (c != 0) return c;
    } else {
      return x is BigInt ? -1 : 1;
    }
  }
  final lengthDiff = ta.length.compareTo(tb.length);
  if (lengthDiff != 0) return lengthDiff;
  // token 序列完全相同时（仅大小写不同），回退到原串比较以保证排序稳定。
  return a.compareTo(b);
}

/// 章节排序的统一入口：有 track 号优先按 track，否则按文件名自然序。
/// （规格：「优先采用 track 标签」）
int compareChapters({
  required String nameA,
  required String nameB,
  int? trackA,
  int? trackB,
}) {
  if (trackA != null && trackB != null && trackA != trackB) {
    return trackA.compareTo(trackB);
  }
  return compareNatural(nameA, nameB);
}

/// track 号是否可用作排序依据。
///
/// 只有**每一个**章节都带 track 号时才算数。混着用（有的比 track、有的比文件名）
/// 会让比较器失去传递性，排出来的顺序是不确定的。
bool canSortByTrack(Iterable<int?> tracks) {
  var count = 0;
  for (final t in tracks) {
    if (t == null) return false;
    count++;
  }
  return count > 0;
}

/// 取一个网盘路径的父目录。
///
/// 章节排序需要它：跨子目录的书要先按子目录排，再按文件名排。
String parentDirOf(String path) {
  final i = path.lastIndexOf('/');
  return i <= 0 ? '/' : path.substring(0, i);
}
