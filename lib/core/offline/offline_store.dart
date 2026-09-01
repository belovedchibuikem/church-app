import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_transport.dart';
import '../sync/sync_contract.dart';

export '../sync/sync_contract.dart' show SyncItemType, SyncItemState;

final class CachedApiEnvelope {
  const CachedApiEnvelope({
    required this.statusCode,
    required this.body,
    this.correlationId,
    required this.storedAt,
  });

  final int statusCode;
  final Object? body;
  final String? correlationId;
  final DateTime storedAt;

  ApiResponse toResponse() => ApiResponse(
        statusCode: statusCode,
        body: body,
        correlationId: correlationId,
        headers: const {'x-fhc-offline-cache': '1'},
      );

  Map<String, Object?> toJson() => {
        'statusCode': statusCode,
        'body': body,
        'correlationId': correlationId,
        'storedAt': storedAt.toUtc().toIso8601String(),
      };

  static CachedApiEnvelope? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final storedRaw = '${raw['storedAt'] ?? ''}';
    return CachedApiEnvelope(
      statusCode: (raw['statusCode'] as num?)?.toInt() ?? 200,
      body: raw['body'],
      correlationId: raw['correlationId'] as String?,
      storedAt: DateTime.tryParse(storedRaw)?.toUtc() ?? DateTime.now().toUtc(),
    );
  }
}

final class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.method,
    required this.path,
    this.query = const {},
    this.body,
    this.headers = const {},
    this.idempotencyKey,
    required this.type,
    required this.state,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final ApiMethod method;
  final String path;
  final Map<String, Object?> query;
  final Object? body;
  final Map<String, String> headers;
  final String? idempotencyKey;
  final SyncItemType type;
  final SyncItemState state;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  OutboxEntry copyWith({
    SyncItemState? state,
    int? attempts,
    String? lastError,
  }) {
    return OutboxEntry(
      id: id,
      method: method,
      path: path,
      query: query,
      body: body,
      headers: headers,
      idempotencyKey: idempotencyKey,
      type: type,
      state: state ?? this.state,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError,
    );
  }

  ApiRequest toRequest() => ApiRequest(
        method: method,
        path: path,
        query: query,
        headers: headers,
        body: body,
        idempotencyKey: idempotencyKey,
      );

  SyncItem toSyncItem() => SyncItem(
        localId: id,
        type: type,
        state: state,
        idempotencyKey: idempotencyKey ?? id,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'method': method.name,
        'path': path,
        'query': query,
        'body': body,
        'headers': headers,
        'idempotencyKey': idempotencyKey,
        'type': type.name,
        'state': state.name,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  static OutboxEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final methodName = '${raw['method'] ?? 'post'}';
    final typeName = '${raw['type'] ?? 'report'}';
    final stateName = '${raw['state'] ?? 'queued'}';
    return OutboxEntry(
      id: '${raw['id'] ?? ''}',
      method: ApiMethod.values.firstWhere(
        (value) => value.name == methodName,
        orElse: () => ApiMethod.post,
      ),
      path: '${raw['path'] ?? ''}',
      query: _mapObject(raw['query']),
      body: raw['body'],
      headers: {
        for (final entry in _mapObject(raw['headers']).entries)
          entry.key: '${entry.value ?? ''}',
      },
      idempotencyKey: raw['idempotencyKey'] as String?,
      type: SyncItemType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => SyncItemType.report,
      ),
      state: SyncItemState.values.firstWhere(
        (value) => value.name == stateName,
        orElse: () => SyncItemState.queued,
      ),
      createdAt:
          DateTime.tryParse('${raw['createdAt'] ?? ''}')?.toUtc() ??
          DateTime.now().toUtc(),
      attempts: (raw['attempts'] as num?)?.toInt() ?? 0,
      lastError: raw['lastError'] as String?,
    );
  }

  static Map<String, Object?> _mapObject(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries) '${entry.key}': entry.value,
    };
  }
}

abstract interface class OfflineStore {
  Future<CachedApiEnvelope?> readCache(String key);
  Future<void> writeCache(String key, CachedApiEnvelope envelope);
  Future<void> clearCache();
  Future<int> cacheEntryCount();
  Future<int> approximateCacheBytes();

  Future<List<OutboxEntry>> loadOutbox();
  Future<void> upsertOutbox(OutboxEntry entry);
  Future<void> removeOutbox(String id);
  Future<List<String>> loadCapabilities();
  Future<void> saveCapabilities(Iterable<String> permissions);
  Future<void> clearCapabilities();
}

/// In-memory store for unit tests.
final class MemoryOfflineStore implements OfflineStore {
  final Map<String, CachedApiEnvelope> cache = {};
  final Map<String, OutboxEntry> outbox = {};
  List<String> capabilities = const [];

  @override
  Future<CachedApiEnvelope?> readCache(String key) async => cache[key];

  @override
  Future<void> writeCache(String key, CachedApiEnvelope envelope) async {
    cache[key] = envelope;
  }

  @override
  Future<void> clearCache() async => cache.clear();

  @override
  Future<int> cacheEntryCount() async => cache.length;

  @override
  Future<int> approximateCacheBytes() async {
    var total = 0;
    for (final entry in cache.entries) {
      total += entry.key.length + jsonEncode(entry.value.toJson()).length;
    }
    return total;
  }

  @override
  Future<List<OutboxEntry>> loadOutbox() async =>
      outbox.values.toList(growable: false);

  @override
  Future<void> upsertOutbox(OutboxEntry entry) async {
    outbox[entry.id] = entry;
  }

  @override
  Future<void> removeOutbox(String id) async {
    outbox.remove(id);
  }

  @override
  Future<List<String>> loadCapabilities() async => capabilities;

  @override
  Future<void> saveCapabilities(Iterable<String> permissions) async {
    capabilities = permissions.toList(growable: false);
  }

  @override
  Future<void> clearCapabilities() async {
    capabilities = const [];
  }
}

/// Durable SharedPreferences cache + outbox. Web-safe (no dart:io).
final class SharedPreferencesOfflineStore implements OfflineStore {
  SharedPreferencesOfflineStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _indexKey = 'fhc.offline.cache.index';
  static const _cachePrefix = 'fhc.offline.cache.';
  static const _outboxKey = 'fhc.offline.outbox';
  static const _capabilitiesKey = 'fhc.offline.capabilities';
  static const _maxEntries = 400;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    if (_prefs != null) return _prefs!;
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  static String cacheKeyFor(ApiRequest request) {
    final query = request.query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final queryPart = [
      for (final entry in query)
        if (entry.value != null) '${entry.key}=${entry.value}',
    ].join('&');
    return '${request.method.name}:${request.path}?$queryPart';
  }

  String _slot(String key) => '$_cachePrefix${key.hashCode}';

  @override
  Future<CachedApiEnvelope?> readCache(String key) async {
    final prefs = await _ensure();
    final raw = prefs.getString(_slot(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      return CachedApiEnvelope.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCache(String key, CachedApiEnvelope envelope) async {
    final prefs = await _ensure();
    final encoded = jsonEncode(envelope.toJson());
    await prefs.setString(_slot(key), encoded);
    final index = [...?prefs.getStringList(_indexKey)]..remove(key);
    index.add(key);
    while (index.length > _maxEntries) {
      final evicted = index.removeAt(0);
      await prefs.remove(_slot(evicted));
    }
    await prefs.setStringList(_indexKey, index);
  }

  @override
  Future<void> clearCache() async {
    final prefs = await _ensure();
    final index = prefs.getStringList(_indexKey) ?? const <String>[];
    for (final key in index) {
      await prefs.remove(_slot(key));
    }
    await prefs.remove(_indexKey);
  }

  @override
  Future<int> cacheEntryCount() async {
    final prefs = await _ensure();
    return (prefs.getStringList(_indexKey) ?? const []).length;
  }

  @override
  Future<int> approximateCacheBytes() async {
    final prefs = await _ensure();
    final index = prefs.getStringList(_indexKey) ?? const <String>[];
    var total = 0;
    for (final key in index) {
      total += (prefs.getString(_slot(key)) ?? '').length;
    }
    return total;
  }

  @override
  Future<List<OutboxEntry>> loadOutbox() async {
    final prefs = await _ensure();
    final raw = prefs.getString(_outboxKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final item in decoded)
          if (OutboxEntry.fromJson(item) != null) OutboxEntry.fromJson(item)!,
      ];
    } catch (error, stack) {
      debugPrint('Offline outbox decode failed: $error\n$stack');
      return const [];
    }
  }

  @override
  Future<void> upsertOutbox(OutboxEntry entry) async {
    final items = [
      for (final item in await loadOutbox())
        if (item.id != entry.id) item,
      entry,
    ];
    await _writeOutbox(items);
  }

  @override
  Future<void> removeOutbox(String id) async {
    final items = [
      for (final item in await loadOutbox())
        if (item.id != id) item,
    ];
    await _writeOutbox(items);
  }

  Future<void> _writeOutbox(List<OutboxEntry> items) async {
    final prefs = await _ensure();
    await prefs.setString(
      _outboxKey,
      jsonEncode([for (final item in items) item.toJson()]),
    );
  }

  @override
  Future<List<String>> loadCapabilities() async {
    final prefs = await _ensure();
    return prefs.getStringList(_capabilitiesKey) ?? const [];
  }

  @override
  Future<void> saveCapabilities(Iterable<String> permissions) async {
    final prefs = await _ensure();
    await prefs.setStringList(
      _capabilitiesKey,
      permissions.toList(growable: false),
    );
  }

  @override
  Future<void> clearCapabilities() async {
    final prefs = await _ensure();
    await prefs.remove(_capabilitiesKey);
  }
}
