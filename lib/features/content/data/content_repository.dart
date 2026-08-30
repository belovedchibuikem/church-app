import 'package:family_house_connect_public_api/public_api.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/app_failure.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';

/// Public CMS catalogue client for `GET /content/pages` and
/// `GET /content/pages/{slug}` via [FamilyHousePublicApiClient].
abstract interface class ContentRepository {
  Future<AppResult<List<JsonObject>>> listContentPages();
  Future<AppResult<JsonObject>> getContentPage(String slug);
}

final class RemoteContentRepository implements ContentRepository {
  RemoteContentRepository({required FamilyHousePublicApiClient publicApi})
      : _publicApi = publicApi;

  final FamilyHousePublicApiClient _publicApi;

  @override
  Future<AppResult<List<JsonObject>>> listContentPages() async {
    try {
      final envelope = await _publicApi.listContentPages();
      final data = envelope.data;
      if (data is! List) {
        return const AppError(
          ServerFailure('Content pages envelope missing data[].'),
        );
      }
      return AppSuccess(
        data
            .whereType<Map>()
            .map((item) => _asJsonObject(Map<String, dynamic>.from(item)))
            .toList(growable: false),
      );
    } on PublicApiException catch (error) {
      return AppError(_failureFromPublicApi(error));
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach content API.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Content pages request failed.', cause: error),
      );
    }
  }

  @override
  Future<AppResult<JsonObject>> getContentPage(String slug) async {
    final trimmed = slug.trim();
    if (trimmed.isEmpty) {
      return const AppError(ValidationFailure('Content page slug is required.'));
    }

    try {
      final envelope = await _publicApi.getContentPage(trimmed);
      final data = envelope.data;
      if (data is! Map) {
        return const AppError(
          ServerFailure('Content page envelope missing data.'),
        );
      }
      return AppSuccess(_asJsonObject(Map<String, dynamic>.from(data)));
    } on PublicApiException catch (error) {
      return AppError(_failureFromPublicApi(error));
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to reach content API.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Content page request failed.', cause: error),
      );
    }
  }
}

AppFailure _failureFromPublicApi(PublicApiException error) {
  return mapHttpStatusToFailure(
    statusCode: error.statusCode,
    message: error.message,
    code: error.code,
    correlationId: error.correlationId,
  );
}

JsonObject _asJsonObject(Map<String, dynamic> source) {
  return source.map((key, value) => MapEntry(key, value as Object?));
}
