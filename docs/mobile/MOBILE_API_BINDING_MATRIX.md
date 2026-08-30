# Family House Connect Mobile API Binding Matrix

Audit date: 2026-08-27 (shell composition update)

## Readiness verdict

The Flutter shell now has a composition root (`AppServices`), `HttpApiTransport`,
session token store, Laravel authorization gateway, and a path dependency on the
generated Dart clients under `../api/clients/dart`. Domain repositories are wired
for auth, catalogue, payments, prayer, needs, messaging, notifications, sync,
and KCA curriculum reads. Remaining gaps are screen-level fixture leftovers and
OD-gated writes (see `KNOWN_GAPS.md` and repo `docs/HONEST_LIMITS.md`).

Evidence:

- `lib/core/di/app_services.dart` constructs transport, token store, gateway,
  public client, and domain repositories including payment/prayer/need/message/
  notification/sync/KCA.
- `lib/core/api/http_api_transport.dart` implements `ApiTransport`.
- `family_house_connect_public_api` path-depends on `../api/clients/dart`.
- Feature `data/` repositories cover auth, profile, security, church, home
  church applications, events, mission catalogue, KCA verify + curriculum reads,
  press catalogue, payments, prayer, needs, messaging, notifications, and sync.
- Needs share/list screens bind `/user/needs`; some church/mission ops screens
  still fixture or honest-unavailable pending contracts.

## Status key

- **BOUND (partial)** — repository + transport exist for listed operations.
- **SERVER CONTRACT / UNBOUND** — OpenAPI operation exists; Flutter does not call it yet.
- **SERVER ROUTE / NO OPENAPI / UNBOUND** — Laravel route exists; no public OpenAPI / client use.
- **MISSING CONTRACT** — no corresponding operation found for the designed UI.
- **LOCAL UI ONLY** — widget/fixture only; not durable or authoritative.

## Binding matrix (shell-relevant)

| SCREEN / DOMAIN | REPOSITORY | STATUS |
|---|---|---|
| Bootstrap / DI | `AppServices` | BOUND (partial) — composition root live |
| Authorization guard | `LaravelAuthorizationGateway` | BOUND (partial) — `/user/authorization/check` |
| Sign In / MFA / logout | `LaravelAuthRepository` | BOUND (partial) — mobile auth routes |
| Profile / preferences | `LaravelProfileRepository` | BOUND (partial) — `/user/me`, preferences |
| Security sessions / consents | `LaravelSecurityRepository` | BOUND (partial) — `/user/security/*` |
| Discover churches / detail | `ChurchRepositoryImpl` | BOUND (partial) — public church list/detail; route IDs preserved |
| Start Home Church submit | `HomeChurchRepositoryImpl` | BOUND (partial) — public application submit |
| Events list / detail | `RemoteEventRepository` | BOUND (partial) — public list/get; register/ticket still unavailable |
| Mission crusades / locations | `HttpMissionRepository` | BOUND (partial) — public catalogue + admin list/capture/assign when transport+scope; soul detail/follow-up unbound |
| KCA certificate verify | `HttpKcaRepository` | BOUND (partial) — public verify only |
| Press library / publication | `RemotePressRepository` | BOUND (partial) — public catalogue; download unbound |
| Maps configuration / places | `MapsApi` | BOUND (partial) — public maps endpoints |
| Generated public client | `FamilyHousePublicApiClient` | BOUND (partial) — wired in `AppServices` |
| Prayer | — | MISSING CONTRACT — honest unavailable in release |
| Giving / payments / wallet | — | MISSING CONTRACT — honest unavailable in release |
| Messages | — | MISSING CONTRACT — honest unavailable in release |
| Notifications | — | MISSING CONTRACT |
| Offline / sync / uploads | `UnconfiguredSyncRepository` | LOCAL UI ONLY |
| Restricted pastoral / guardian | — | MISSING CONTRACT; OD-006/007 |

## Laravel/OpenAPI blockers

1. Protected OpenAPI still incomplete for payments, messaging, notifications,
   operational Home Church/Mission/KCA lifecycle, uploads, sync, and AI.
2. Client permission aliases vs Laravel canonical families remain partially
   normalized (KG-008).
3. No `android/` or `ios/` projects — native ship blocker.
4. Generated Dart clients live under `api/clients/dart` (awkward path from mobile;
   wired via pubspec path dependency).

## Minimum next binding sequence

1. Bind remaining feature screens to repositories already in `AppServices`.
2. Add payment/prayer/messaging OpenAPI + repositories before enabling those UIs
   in release.
3. Generate `android/` + `ios/` and configure secure storage / deep links.
4. Contract tests against Laravel with real roles/scopes.
