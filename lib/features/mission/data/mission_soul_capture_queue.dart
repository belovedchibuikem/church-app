import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Queues soul captures when the device cannot reach the API.
final class MissionSoulCaptureQueue extends ChangeNotifier {
  MissionSoulCaptureQueue({SharedPreferences? prefs}) : _prefs = prefs;

  static const storageKey = 'mission_soul_capture_queue';

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
    required String crusadeId,
    required String idempotencyKey,
    String? personId,
    String? givenName,
    String? familyName,
    String? consentAt,
  }) async {
    final items = [...await load()];
    final exists = items.any((item) => item['idempotency_key'] == idempotencyKey);
    if (exists) return;
    items.add({
      'crusade_id': crusadeId,
      'idempotency_key': idempotencyKey,
      'status': 'pending',
      if (personId != null) 'person_id': personId,
      if (givenName != null) 'given_name': givenName,
      if (familyName != null) 'family_name': familyName,
      if (consentAt != null) 'consent_at': consentAt,
    });
    await _write(items);
  }

  Future<void> mark(String idempotencyKey, String status) async {
    final items = [
      for (final item in await load())
        if (item['idempotency_key'] == idempotencyKey)
          {...item, 'status': status}
        else
          item,
    ];
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
