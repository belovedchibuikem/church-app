import '../api/api_transport.dart';
import '../contracts/mobile_repository_contracts.dart';
import 'kca_curriculum_prefetch.dart';

/// Best-effort prefetch so a later outage still has catalogue + member reads.
Future<void> warmupOfflineCache({
  ApiTransport? transport,
  KcaRepository? kcaRepository,
}) async {
  if (transport != null) {
    const reads = <ApiRequest>[
      ApiRequest(method: ApiMethod.get, path: '/health', skipAuth: true),
      ApiRequest(method: ApiMethod.get, path: '/bible/books', skipAuth: true),
      ApiRequest(method: ApiMethod.get, path: '/user/me'),
      ApiRequest(method: ApiMethod.get, path: '/user/dashboard'),
      ApiRequest(method: ApiMethod.get, path: '/user/prayers'),
      ApiRequest(method: ApiMethod.get, path: '/user/needs'),
      ApiRequest(method: ApiMethod.get, path: '/user/notifications'),
      ApiRequest(method: ApiMethod.get, path: '/user/kca/dashboard'),
      ApiRequest(method: ApiMethod.get, path: '/user/kca/modules'),
      ApiRequest(method: ApiMethod.get, path: '/churches', skipAuth: true),
      ApiRequest(
        method: ApiMethod.get,
        path: '/press/publications',
        skipAuth: true,
      ),
      ApiRequest(method: ApiMethod.get, path: '/events', skipAuth: true),
    ];

    for (final request in reads) {
      try {
        await transport.send(request);
      } catch (_) {}
    }
  }

  final kca = kcaRepository;
  if (kca != null) {
    try {
      await prefetchKcaCurriculum(kca);
    } catch (_) {}
  }
}
