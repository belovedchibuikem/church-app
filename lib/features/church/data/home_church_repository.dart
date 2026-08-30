import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/api/transport_repository_helpers.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// In-memory draft carried across the Start Home Church wizard.
final class HomeChurchApplicationDraft {
  String? churchId;
  String? locationId;
  String? administrativeUnitId;
  String? churchName;
  String? locationLabel;

  String? givenName;
  String? middleName;
  String? familyName;
  String? preferredName;

  String? proposedName;
  int? expectedParticipants;
  String? meetingDay;
  String? meetingTime;

  String? contactEmail;
  String? contactPhone;
  bool guidelinesAgreed = false;

  String? lastApplicationId;
  String? lastStatus;

  void clear() {
    churchId = null;
    locationId = null;
    administrativeUnitId = null;
    churchName = null;
    locationLabel = null;
    givenName = null;
    middleName = null;
    familyName = null;
    preferredName = null;
    proposedName = null;
    expectedParticipants = null;
    meetingDay = null;
    meetingTime = null;
    contactEmail = null;
    contactPhone = null;
    guidelinesAgreed = false;
    lastApplicationId = null;
    lastStatus = null;
  }

  JsonObject toPayload({required String idempotencyKey}) => {
        'church_id': churchId,
        'location_id': locationId,
        'administrative_unit_id': administrativeUnitId,
        'applicant': {
          'given_name': givenName,
          'middle_name': middleName,
          'family_name': familyName,
          'preferred_name': preferredName,
        },
        'proposed_name': proposedName,
        'expected_participants': expectedParticipants,
        'meeting_day': meetingDay,
        'meeting_time': meetingTime,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'guidelines_agreed': guidelinesAgreed,
        'idempotency_key': idempotencyKey,
      };
}

final class HomeChurchApplicationSubmission {
  const HomeChurchApplicationSubmission({
    required this.applicationId,
    required this.status,
    this.receivedAt,
    this.idempotentReplay = false,
    this.correlationId,
  });

  final String applicationId;
  final String status;
  final String? receivedAt;
  final bool idempotentReplay;
  final String? correlationId;

  JsonObject toJson() => {
        'application_id': applicationId,
        'status': status,
        'received_at': receivedAt,
        'idempotent_replay': idempotentReplay,
        'correlation_id': correlationId,
      };
}

/// Holds the in-progress public home-church application draft.
final class HomeChurchApplicationSession {
  HomeChurchApplicationSession._();

  static final draft = HomeChurchApplicationDraft();
}

/// Public apply + authenticated home-church dashboard/report client.
///
/// - Apply: `POST /home-church-applications` (public, Idempotency-Key required)
/// - Dashboard: `GET /user/home-churches/{homeChurch}` when [transport] is set
/// - Report: `POST /user/home-churches/{homeChurch}/reports` when [transport] is set
final class HomeChurchRepositoryImpl
    with TransportRepositoryHelpers
    implements HomeChurchRepository {
  HomeChurchRepositoryImpl({
    String? baseUrl,
    http.Client? httpClient,
    ApiTransport? transport,
  })  : baseUrl = resolveFhcApiUrl(override: baseUrl),
        _http = httpClient ?? http.Client(),
        _transport = transport;

  final String baseUrl;
  final http.Client _http;
  final ApiTransport? _transport;

  Future<AppResult<HomeChurchApplicationSubmission>> submitPublicApplication(
    HomeChurchApplicationDraft draft, {
    String? idempotencyKey,
  }) async {
    final key = (idempotencyKey ?? _newIdempotencyKey()).trim();
    if (key.length < 8) {
      return const AppError(
        ValidationFailure(
          'Idempotency key must be at least 8 characters.',
          errors: {
            'idempotency_key': ['Idempotency key must be at least 8 characters.'],
          },
        ),
      );
    }

    final missing = <String, List<String>>{};
    void requireField(String name, Object? value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        missing[name] = ['This field is required.'];
      }
    }

    requireField('church_id', draft.churchId);
    requireField('location_id', draft.locationId);
    requireField('administrative_unit_id', draft.administrativeUnitId);
    requireField('applicant.given_name', draft.givenName);
    requireField('applicant.family_name', draft.familyName);
    requireField('proposed_name', draft.proposedName);
    requireField('meeting_day', draft.meetingDay);
    requireField('meeting_time', draft.meetingTime);
    requireField('contact_email', draft.contactEmail);
    requireField('contact_phone', draft.contactPhone);
    if (draft.expectedParticipants == null || draft.expectedParticipants! < 1) {
      missing['expected_participants'] = ['Expected participants is required.'];
    }
    if (!draft.guidelinesAgreed) {
      missing['guidelines_agreed'] = ['You must agree to the guidelines.'];
    }

    if (missing.isNotEmpty) {
      return AppError(
        ValidationFailure(
          'Please complete the required application fields.',
          errors: missing,
        ),
      );
    }

    final payload = draft.toPayload(idempotencyKey: key);

    try {
      final uri = Uri.parse('$baseUrl/home-church-applications');
      final response = await _http
          .post(
            uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Idempotency-Key': key,
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      final failure = _mapError(response);
      if (failure != null) return AppError(failure);

      final body = _decodeBody(response.body);
      final data = body['data'] as Map<String, dynamic>? ?? const {};
      final meta = body['meta'] as Map<String, dynamic>? ?? const {};
      final applicationId = data['application_id'] as String? ?? '';
      if (applicationId.isEmpty) {
        return const AppError(
          ServerFailure('Application response was incomplete.'),
        );
      }

      final submission = HomeChurchApplicationSubmission(
        applicationId: applicationId,
        status: data['status'] as String? ?? 'draft',
        receivedAt: data['received_at'] as String?,
        idempotentReplay: meta['idempotent_replay'] == true,
        correlationId: body['correlation_id'] as String?,
      );

      draft.lastApplicationId = submission.applicationId;
      draft.lastStatus = submission.status;
      return AppSuccess(submission);
    } catch (error, stack) {
      debugPrint('HomeChurchRepository.submitPublicApplication: $error\n$stack');
      return AppError(
        NetworkFailure('Unable to submit home church application.', cause: error),
      );
    }
  }

  @override
  Future<AppResult<JsonObject>> submitApplication(JsonObject application) async {
    final draft = HomeChurchApplicationDraft()
      ..churchId = application['church_id'] as String?
      ..locationId = application['location_id'] as String?
      ..administrativeUnitId = application['administrative_unit_id'] as String?
      ..proposedName = application['proposed_name'] as String?
      ..expectedParticipants =
          (application['expected_participants'] as num?)?.toInt()
      ..meetingDay = application['meeting_day'] as String?
      ..meetingTime = application['meeting_time'] as String?
      ..contactEmail = application['contact_email'] as String?
      ..contactPhone = application['contact_phone'] as String?
      ..guidelinesAgreed = application['guidelines_agreed'] == true;

    final applicant = application['applicant'];
    if (applicant is Map) {
      draft.givenName = applicant['given_name'] as String?;
      draft.middleName = applicant['middle_name'] as String?;
      draft.familyName = applicant['family_name'] as String?;
      draft.preferredName = applicant['preferred_name'] as String?;
    }

    final result = await submitPublicApplication(
      draft,
      idempotencyKey: application['idempotency_key'] as String?,
    );
    return switch (result) {
      AppSuccess(:final value) => AppSuccess(value.toJson()),
      AppError(:final failure) => AppError(failure),
    };
  }

  @override
  Future<AppResult<JsonObject>> getDashboard(String id) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Home church dashboard requires an authenticated API transport. '
          'No dashboard data is shown.',
        ),
      );
    }

    final trimmed = id.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Home church id is required.'));
    }

    return sendObject(
      transport,
      ApiRequest(
        method: ApiMethod.get,
        path: '/user/home-churches/${encodeId(trimmed)}',
      ),
    );
  }

  @override
  Future<AppResult<void>> submitReport(JsonObject report) async {
    final transport = _transport;
    if (transport == null) {
      return const AppError(
        IntegrationUnavailableFailure(
          'Home church reports require an authenticated API transport. '
          'No report was submitted.',
        ),
      );
    }

    String? asText(Object? value) {
      if (value == null) return null;
      final trimmed = '$value'.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final id = asText(report['home_church_id']) ?? asText(report['id']) ?? '';
    final summary = asText(report['summary']) ?? '';
    if (id.isEmpty) {
      return const AppError(
        ValidationFailure(
          'Home church id is required.',
          errors: {
            'home_church_id': ['Home church id is required.'],
          },
        ),
      );
    }
    if (summary.isEmpty) {
      return const AppError(
        ValidationFailure(
          'Summary is required.',
          errors: {
            'summary': ['Summary is required.'],
          },
        ),
      );
    }

    final period = asText(report['period_code']);
    final body = <String, Object?>{
      'summary': summary,
      if (period != null && period.isNotEmpty) 'period_code': period,
    };

    return sendVoid(
      transport,
      ApiRequest(
        method: ApiMethod.post,
        path: '/user/home-churches/${encodeId(id)}/reports',
        body: body,
        idempotencyKey: newIdempotencyKey('hc-report'),
      ),
    );
  }

  String _newIdempotencyKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'hc-${DateTime.now().toUtc().millisecondsSinceEpoch}-$hex';
  }

  Map<String, dynamic> _decodeBody(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    return const {};
  }

  AppFailure? _mapError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return null;

    Map<String, dynamic> body = const {};
    try {
      body = _decodeBody(response.body);
    } catch (_) {}

    final error = body['error'] as Map<String, dynamic>? ?? const {};
    final message = (error['message'] as String?)?.trim();
    final details = error['details'] as Map<String, dynamic>? ?? const {};
    final fieldsRaw = details['fields'];
    final fields = <String, List<String>>{};
    if (fieldsRaw is Map) {
      for (final entry in fieldsRaw.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is List) {
          fields[key] = value.map((e) => e.toString()).toList();
        } else if (value != null) {
          fields[key] = [value.toString()];
        }
      }
    }

    final fallback = message?.isNotEmpty == true
        ? message!
        : 'Request failed (${response.statusCode}).';

    return switch (response.statusCode) {
      401 => UnauthorizedFailure(fallback),
      403 => ForbiddenFailure(fallback),
      404 => NotFoundFailure(fallback),
      409 => ConflictFailure(fallback),
      422 => ValidationFailure(fallback, errors: fields),
      429 => RateLimitFailure(fallback),
      >= 500 => ServerFailure(fallback),
      _ => UnknownFailure(fallback),
    };
  }
}

/// Maps API meeting day labels used in the wizard to Laravel `MeetingDay` values.
String? meetingDayApiValue(String? label) {
  if (label == null) return null;
  final normalized = label.trim().toLowerCase();
  return switch (normalized) {
    'mon' || 'monday' => 'monday',
    'tue' || 'tuesday' => 'tuesday',
    'wed' || 'wednesday' => 'wednesday',
    'thu' || 'thursday' => 'thursday',
    'fri' || 'friday' => 'friday',
    'sat' || 'saturday' => 'saturday',
    'sun' || 'sunday' => 'sunday',
    _ => normalized.contains('-') ? null : normalized,
  };
}

/// Maps display times like `6:00 PM` to `H:i` (`18:00`).
String? meetingTimeApiValue(String? label) {
  if (label == null || label.trim().isEmpty) return null;
  final raw = label.trim();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(raw);
  if (match == null) {
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(raw)) return raw;
    return null;
  }
  var hour = int.parse(match.group(1)!);
  final minute = match.group(2)!;
  final meridiem = match.group(3)?.toUpperCase();
  if (meridiem == 'PM' && hour < 12) hour += 12;
  if (meridiem == 'AM' && hour == 12) hour = 0;
  return '${hour.toString().padLeft(2, '0')}:$minute';
}

int? expectedParticipantsApiValue(String? range) {
  if (range == null || range.trim().isEmpty) return null;
  final digits = RegExp(r'\d+').firstMatch(range)?.group(0);
  if (digits == null) return null;
  return int.tryParse(digits);
}
