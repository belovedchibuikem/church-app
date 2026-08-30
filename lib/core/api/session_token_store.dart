/// Re-export of the concrete session token store used by [HttpApiTransport].
///
/// Interface: [SessionTokenStore] in `api_transport.dart`.
/// Implementation lives under `core/auth` (secure storage / in-memory web).
library;

export '../auth/session_token_store.dart';
