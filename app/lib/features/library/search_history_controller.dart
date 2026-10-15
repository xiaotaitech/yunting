import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yun_audiobook/app/providers.dart';
import 'package:yun_audiobook/data/local/settings_dao.dart';
import 'package:yun_audiobook/domain/search_history.dart';

part 'search_history_controller.g.dart';

/// 搜索历史的写入口。keepAlive 的理由同其它命令式 controller。
@Riverpod(keepAlive: true)
class SearchHistoryController extends _$SearchHistoryController {
  @override
  void build() {}

  SettingsDao get _dao => ref.read(databaseProvider).settingsDao;

  Future<List<String>> _read() async {
    final raw = await _dao.read(SettingsDao.searchHistoryKey);
    return raw == null ? [] : List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> _write(List<String> h) =>
      _dao.write(SettingsDao.searchHistoryKey, jsonEncode(h));

  Future<void> add(String query) async {
    if (query.trim().isEmpty) return;
    await _write(SearchHistory.push(await _read(), query));
  }

  Future<void> remove(String query) async =>
      _write((await _read())..remove(query));

  Future<void> clear() => _write(const []);
}
