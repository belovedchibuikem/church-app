import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Queues KCA evidence files until a live `/user/files` + evidence POST can run.
final class KcaEvidenceQueue extends ChangeNotifier {
  KcaEvidenceQueue({SharedPreferences? prefs}) : _prefs = prefs;

  static const storageKey = 'kca_evidence_queue';
  static const maxBytes = 1500000;

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
    required String assignmentId,
    required String idempotencyKey,
    required String filename,
    required List<int> bytes,
    String? description,
  }) async {
    if (bytes.length > maxBytes) return;
    final items = [...await load()];
    final exists = items.any(
      (item) => item['idempotency_key'] == idempotencyKey,
    );
    if (exists) return;
    items.add({
      'assignment_id': assignmentId,
      'idempotency_key': idempotencyKey,
      'filename': filename,
      'bytes_b64': base64Encode(bytes),
      if (description != null && description.isNotEmpty)
        'description': description,
    });
    await _write(items);
  }

  Future<void> remove(String idempotencyKey) async {
    final items = [
      for (final item in await load())
        if (item['idempotency_key'] != idempotencyKey) item,
    ];
    await _write(items);
  }

  Future<void> _write(List<Map<String, String>> items) async {
    final prefs = await _ensurePrefs();
    await prefs.setString(storageKey, jsonEncode(items));
    notifyListeners();
  }
}
