import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists KCA enrolment wizard field maps for steps 1–8.
///
/// Keys: `kca_enrolment_step_{n}` → JSON object of string field values.
final class KcaEnrolmentDraftStore extends ChangeNotifier {
  KcaEnrolmentDraftStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _prefix = 'kca_enrolment_step_';
  static const stepCount = 8;

  SharedPreferences? _prefs;
  bool _closed = false;

  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }

  Future<SharedPreferences> _ensurePrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _key(int step) => '$_prefix$step';

  Future<Map<String, String>> loadStep(int step) async {
    if (step < 1 || step > stepCount) return const {};
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_key(step));
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.value != null) '${entry.key}': '${entry.value}',
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> saveStep(int step, Map<String, String> fields) async {
    if (step < 1 || step > stepCount) return;
    final prefs = await _ensurePrefs();
    await prefs.setString(_key(step), jsonEncode(fields));
    if (!_closed) notifyListeners();
  }

  Future<Map<String, String>> loadAll() async {
    final merged = <String, String>{};
    for (var step = 1; step <= stepCount; step++) {
      final fields = await loadStep(step);
      for (final entry in fields.entries) {
        merged['step${step}_${entry.key}'] = entry.value;
        // Also keep bare keys from later steps (last write wins) for API body.
        merged[entry.key] = entry.value;
      }
    }
    return merged;
  }

  /// Hydrates steps from a server `application_data` object when present.
  Future<void> hydrateFromApplicationData(Map<String, Object?> data) async {
    for (var step = 1; step <= stepCount; step++) {
      final nested = data['step_$step'] ?? data['step$step'];
      if (nested is Map) {
        final fields = <String, String>{
          for (final entry in nested.entries)
            if (entry.value != null) '${entry.key}': '${entry.value}',
        };
        if (fields.isNotEmpty) await saveStep(step, fields);
        continue;
      }
      // Flat keys prefixed with stepN_
      final prefix = 'step${step}_';
      final fields = <String, String>{};
      for (final entry in data.entries) {
        final key = entry.key;
        if (key.startsWith(prefix) && entry.value != null) {
          fields[key.substring(prefix.length)] = '${entry.value}';
        }
      }
      if (fields.isNotEmpty) await saveStep(step, fields);
    }
  }

  Future<void> clear() async {
    final prefs = await _ensurePrefs();
    for (var step = 1; step <= stepCount; step++) {
      await prefs.remove(_key(step));
    }
    if (!_closed) notifyListeners();
  }
}
