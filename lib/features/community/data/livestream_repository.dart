import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_transport.dart';
import '../../../core/api/app_failure.dart';
import '../../../core/api/fhc_api_config.dart';
import '../../../core/contracts/mobile_repository_contracts.dart';
import '../../account/data/profile_repository.dart';
import '../../account/data/user_api_client.dart';

/// Public livestream catalogue + authenticated chat/reactions.
final class LivestreamRepository {
  LivestreamRepository({
    String? baseUrl,
    http.Client? httpClient,
    UserApiClient? userClient,
    SessionTokenStore? tokenStore,
  }) : baseUrl = resolveFhcApiUrl(override: baseUrl),
       _http = httpClient ?? http.Client(),
       _user = userClient ??
           UserApiClient(
             tokenStore: sharedAccountTokenStore(tokenStore),
             baseUrl: baseUrl,
           );

  final String baseUrl;
  final http.Client _http;
  final UserApiClient _user;

  Uri get _root => Uri.parse(baseUrl.replaceAll(RegExp(r'/$'), ''));

  Future<AppResult<JsonObject?>> getCurrent() async {
    try {
      final response = await _http.get(
        Uri.parse('${_root.toString()}/livestreams/current'),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
        if (decoded is! Map) {
          return const AppError(ServerFailure('Invalid livestream envelope.'));
        }
        final data = decoded['data'];
        if (data == null) return const AppSuccess(null);
        if (data is Map) {
          return AppSuccess(
            Map<String, Object?>.from(
              data.map((key, value) => MapEntry('$key', value)),
            ),
          );
        }
        return const AppError(ServerFailure('Expected livestream object.'));
      }
      return AppError(
        ServerFailure('Livestream request failed (${response.statusCode}).'),
      );
    } on http.ClientException catch (error) {
      return AppError(
        NetworkFailure('Unable to load the live service.', cause: error),
      );
    } catch (error) {
      return AppError(
        UnknownFailure('Livestream request failed.', cause: error),
      );
    }
  }

  Future<AppResult<List<JsonObject>>> listComments(
    String livestreamId, {
    String? since,
  }) {
    final path = since == null || since.isEmpty
        ? '/user/livestreams/${Uri.encodeComponent(livestreamId)}/comments'
        : '/user/livestreams/${Uri.encodeComponent(livestreamId)}/comments'
            '?since=${Uri.encodeComponent(since)}';
    return _user.getList(path);
  }

  Future<AppResult<JsonObject>> postComment(
    String livestreamId,
    String body,
  ) {
    return _user.postObject(
      '/user/livestreams/${Uri.encodeComponent(livestreamId)}/comments',
      {'body': body},
    );
  }

  Future<AppResult<JsonObject>> react(String livestreamId) {
    return _user.postObject(
      '/user/livestreams/${Uri.encodeComponent(livestreamId)}/reactions',
      const {},
    );
  }
}
