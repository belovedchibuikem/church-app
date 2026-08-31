import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Queues lesson completions when the device cannot reach the API.
final class KcaLessonCompletionQueue extends ChangeNotifier {
  KcaLessonCompletionQueue({SharedPreferences? prefs}) : _prefs = prefs;

  static const storageKey = 'kca_lesson_completion_queue';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<Map<String, String>>> load() async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (item is Map)
            {
              for (final entry in item.entries)
                if (entry.value != null) '${entry.key}': '${entry.value}',
            },
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> enqueue({
    required String lessonId,
    required String idempotencyKey,
    String? unlockToken,
  }) async {
    final items = [...await load()];
    final exists = items.any(
      (item) => item['idempotency_key'] == idempotencyKey || item['lesson_id'] == lessonId,
    );
    if (exists) return;
    items.add({
      'lesson_id': lessonId,
      'idempotency_key': idempotencyKey,
      if (unlockToken != null && unlockToken.isNotEmpty) 'unlock_token': unlockToken,
    });
    await _write(items);
  }

  Future<void> remove(String lessonId) async {
    final items = [
      for (final item in await load())
        if (item['lesson_id'] != lessonId) item,
    ];
    await _write(items);
  }

  Future<void> _write(List<Map<String, String>> items) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(storageKey, jsonEncode(items));
    notifyListeners();
  }
}
