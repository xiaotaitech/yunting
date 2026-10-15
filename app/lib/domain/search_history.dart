/// 「添加书籍」的搜索历史（local-first-drawer-ui）：只存本机，最近在前。
abstract final class SearchHistory {
  static const int maxEntries = 10;

  /// 记一次搜索：去掉首尾空白，同一个词只留最新一次，超出上限丢最旧的。
  static List<String> push(List<String> history, String query) {
    final q = query.trim();
    if (q.isEmpty) return history;
    return [q, ...history.where((h) => h != q)].take(maxEntries).toList();
  }
}
