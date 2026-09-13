import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/transfer_history_item.dart';

class HistoryNotifier extends Notifier<List<TransferHistoryItem>> {
  static const _storageKey = 'transfer_history_list';

  @override
  List<TransferHistoryItem> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      final items = rawList
          .map((itemStr) => TransferHistoryItem.fromJson(jsonDecode(itemStr)))
          .toList();
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = items;
    } catch (_) {}
  }

  Future<void> addHistoryItem(TransferHistoryItem item) async {
    final updated = [item, ...state];
    state = updated;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringList = updated.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, stringList);
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    state = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<TransferHistoryItem>>(
      HistoryNotifier.new,
    );
