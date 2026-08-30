# Family House Connect Mobile — Known Gaps

Updated: 2026-08-27

This file is an adversarial completion record. A gap remains open until code,
contract, and tests prove it closed. Designed/rendered screens are not treated
as production readiness by themselves.

## Critical gaps

### KG-001 — Mobile is not connected to Laravel

- **Status:** MOSTLY CLOSED (2026-08-27).
- **Evidence:** `HttpApiTransport`, session token store, `AppServices`
  composition root, generated public Dart client (`family_house_connect_public_api`)
  path dependency, and domain repositories for auth, profile/security, churches,
  home-church applications, events, mission catalogue, KCA verify, press
  catalogue, payments, prayer, needs, messaging, notifications, and sync are
  present and wired. Member KCA **reads** bind `/user/kca/*` when authenticated.
- **Remaining:** Share/social login stay honestly unavailable. KCA curriculum
  **writes** (evidence/grading) remain OD-008 gated. Multipart member file
  upload is not on mobile (list + DSR are). Native deep links remain scaffolded
  (KG-003).
- **Now bound (2026-08-27):** `POST /user/churches/{church}/memberships`,
  `GET /user/memberships`, `GET /user/events/registrations/{registration}`,
  `GET /press/publications/{publicId}/download` (binary stream, not the JSON
  client), `GET /user/home-churches/{homeChurch}`,
  `POST /user/home-churches/{homeChurch}/reports`,
  `POST /admin/mission/souls/{soul}/follow-ups` and follow-up-completion,
  `POST /user/events/feedback`, `POST /user/privacy/data-subject-requests`,
  `GET /user/files`, `GET /user/dashboard`, and public `GET /content/pages`.
  Church/mission/admin dashboards load those payloads or show honest
  unavailable — fixture totals stay behind `showUnboundFixtures` only.
- **Exit condition:** those remaining screens bind the existing routes + contract
  tests proving live operations (not fixtures). HTTP wiring is not production-ready.

### KG-002 — Laravel authorization adapter remains unbound

- **Status:** CLOSED for bootstrap binding (2026-08-26).
- **Evidence:** `LaravelAuthorizationGateway` calls
  `POST /api/v1/user/authorization/check`. `main.dart` / `AppServices`
  bootstrap that gateway (`FHC_VISUAL_REVIEW=true` only for golden allow-all).
- **Remaining:** MFA redirect model and assigning
  `member_security_self_service` (includes `mobile.app.access`) to real users.

### KG-003 — Platform deep links and notification resolution remain incomplete

- **Status:** PARTIALLY CLOSED for route ID preservation (2026-08-27).
- **Evidence:** `resolveCanonicalRoute` + `FhcRouteArgs` preserve entity ULIDs
  across canonicalization; `PermissionGuard` receives `resourceId` when present.
- **Remaining:** Android/iOS association files, notification resolver,
  intended-route restoration after auth, cold/warm link tests on native.
  Hosted association files are not present; native deep links cannot ship.
- **Impact:** web/local deep-link paths can carry IDs; native platform links
  cannot ship until KG-018 is closed.

### KG-004 — Mechanical dead-callback gate closed; semantic audit remains

- **Evidence:** all 41 explicit empty callbacks were replaced with canonical
  navigation or `fhcApiUnavailable`; the static audit now returns zero.
- **Residual:** fixture-backed tabs/cards still require repository binding and
  semantic flow tests before the full zero-dead-UI gate can be claimed.

### KG-005 — Offline/sync/upload/download behavior is UI-only

- **Evidence:** `UnconfiguredSyncRepository` is the default. No durable outbox,
  connectivity observer, or upload/download manager.
- **Exit condition:** durable outbox and file stores, per-item server state,
  idempotency, conflict/retry flows, and interruption tests.

### KG-006 — Payment and governed workflow states are not authoritative

- **Status:** PARTIALLY MITIGATED at shell (2026-08-27).
- **Evidence:** giving intents bind `/user/payments/giving-intents` and surface
  `PAYMENT_GOVERNANCE_DENIED` when `PAYMENT_GOVERNANCE_MODE=deny`. Release builds
  hide unbound payment fixture screens via `FhcFeatureUnavailablePage`.
  Debug/visual-review still shows fixture UI.
- **Remaining:** live PSP, webhook verification, refunds, and reconciliation
  stay fail-closed (OD-009/010). `local_manual` is QA-only. See
  `docs/HONEST_LIMITS.md`.

## High gaps

### KG-007 — OpenAPI coverage is incomplete

- Public OpenAPI covers status/health, churches, Home Church application
  submission, events, public Press plus download, public Mission catalogue,
  maps, certificate verification, content pages, and fail-closed payment
  webhook receivers (21 operations).
- Protected OpenAPI covers identity, User, and Admin (192 operations), including
  member tickets (registration GET), memberships, Home Church dashboard/reports,
  file list/upload, payments, messaging, notifications, sync, and catalog
  domains. OD-006/007/008 writes (safeguarding restricted reads, privacy
  deletion/legal-hold, KCA evidence/signers) remain gated even when listed.

### KG-008 — Permission vocabulary is not normalized

- Flutter route permissions include aliases; Laravel
  `MobilePermissionAliasCatalog` maps some aliases. Exact action names and role
  bundles are not fully normalized/seeded.

### KG-009 — Dynamic entity routing/data selection is absent

- **Status:** PARTIALLY CLOSED for routing args (2026-08-27).
- **Evidence:** entity IDs survive canonicalization in `FhcRouteArgs`; church
  detail reads them. Other detail screens still need repository loaders wired
  to those IDs.

### KG-010 — Authentication/onboarding flow is incomplete

- **Status:** MOSTLY CLOSED for first-run shell (2026-08-28).
- **Evidence:** splash → onboarding (once, persisted) → language/location
  setup → mobile login / optional MFA → role selection → hub. Returning
  launches skip onboarding. Live API default is
  `https://familyconnect.katakarra.com/api/v1`.
- **Remaining:** registration, recovery, phone OTP server ops, and social
  sign-in stay honestly unavailable (no Laravel mobile routes).

### KG-011 — Data-state architecture is absent

- **Status:** PARTIALLY CLOSED for shared widgets (2026-08-27).
- **Evidence:** `lib/shared/widgets/async_state.dart` provides reusable
  loading/error/empty/unavailable primitives. Production/debug now default to
  live repositories (`showUnboundFixtures` only for `FHC_VISUAL_REVIEW`).
  Remaining unbound church directory lists still show honest unavailable.

### KG-012 — Restricted-data policy remains externally blocked

- Laravel OD-006 / OD-007 remain open. Mobile must not cache or expose
  counselling, pastoral, safeguarding, or child records until approved.

### KG-013 — No end-to-end or device integration tests

- Existing tests are widget navigation/render, golden capture, and unit route
  ID tests. No Laravel contract suite or native device integration yet.

## Medium gaps

### KG-014 — Route registry is split and incomplete

- `app.dart` registers a large exact-path set; `FhcRoutes` remains a subset.

### KG-015 — Unknown route fallback resolved

- Unknown paths render Content Not Available. Remaining: reason/return-target
  data and platform cold-link tests.

### KG-016 — Localization runtime is implemented

- **Status:** CLOSED for infrastructure (2026-08-28).
- **Evidence:** Shared message catalogs for `en`, `yo`, `ig`, `ha`, `fr`, `ar`,
  `zh`, `sw`; web `LocaleProvider` + cookie persistence; mobile `FhcLocaleScope`
  + `ChangeNotifier` launch store; Arabic RTL; `Accept-Language` on API calls.
  Language pickers apply the locale immediately. Remaining CMS/article bodies
  stay server-authored per locale rather than machine-substituted UI strings.

### KG-017 — Accessibility validation is incomplete

- Shared primitives exist; full screen-reader/focus/large-text audit remains.

### KG-018 — Native mobile platform configuration is absent

- **Status:** PARTIALLY CLOSED (2026-08-27).
- **Evidence:** `android/` and `ios/` projects generated via `flutter create`;
  Android Internet/location + cleartext for local API; iOS ATS local networking
  + location usage string. App Links / Associated Domains scaffolds,
  `CODE_SIGN_ENTITLEMENTS` wired to `Runner.entitlements`,
  `key.properties.example` release signing hook, push permission/background
  declarations, and `PushNotificationScaffold` on `AppServices`
  (`isConfigured == false` until OD-009). See `docs/native/APP_LINK_ASSOCIATION.md`
  and repo `docs/HONEST_LIMITS.md`.
- **Remaining (honest):** hosted association files with real cert fingerprints,
  upload keystore secrets, FCM/APNs provider (OD-009), and device QA.

### KG-019 — Production environment configuration is absent

- **Status:** PARTIALLY CLOSED (2026-08-27).
- **Evidence:** `FHC_API_URL` / `FHC_PUBLIC_API_BASE_URL` aligned in
  `fhc_api_config.dart`, `.env.example`, and `dart-define.example.json`.
  Release logging warns when unset.
- **Remaining:** certificate pinning policy, production observability, and
  approved hosted environments.

### KG-020 — Backend evidence corrected

- Traceability records Laravel API v1 routes, public OpenAPI, authorization
  foundation, and progressive Flutter binding.

## External decisions and dependencies

The following cannot be safely invented in Flutter:

1. Approved application/universal-link domain and platform association files.
2. Versioning/code-generation policy for published client packages (protected
   OpenAPI already covers identity/User/Admin).
3. Normalized permission codes, seeded role bundles, scope containment, and
   record policies.
4. Test identities for every relevant role, scope, ownership and MFA state.
5. Payment providers/currencies/refund/reconciliation/webhook governance.
6. Messaging, push, email/SMS/WhatsApp, streaming, maps, storage and AI
   providers by region.
7. KCA pass thresholds, prerequisites, fees, signers and revocation authority.
8. Restricted-record jurisdiction, retention, export and deletion policy.
9. Production API, Redis/queue, storage, mail, observability, backup and restore
   environments.

## Companion audits

- `docs/mobile/MOBILE_API_BINDING_MATRIX.md`
- `docs/mobile/MOBILE_DEEP_LINK_MAP.md`
- `docs/mobile/MOBILE_UI_GAPS.md`

## Current readiness assessment

The Flutter app now has native `android/` + `ios/` projects, a composition root,
the generated `family_house_connect_public_api` client, and HTTP repositories for
auth, catalogue domains, payments, prayer, needs, messaging, notifications, sync,
and KCA curriculum **reads**. Membership request, event tickets, Press download,
and Home Church dashboard/reports still return unavailable in those repositories
despite Laravel routes existing. Giving intents surface payment-governance
denials honestly until OD-009/010 providers are approved. Native
association/signing/push remain scaffolded, not store-ready —
`PushNotificationScaffold.isConfigured` stays false until a real provider;
profile/security revoke/withdraw surfaces recent-MFA honestly. See
`docs/HONEST_LIMITS.md`. Wired HTTP is not production-ready.
