# Family House Connect Mobile Deep-Link Map

Audit date: 2026-08-26

## Current verdict

App-level deep-link resolution is implemented for the canonical aliases below;
platform association and record loading are **not implemented end to end**.

The app has 212 exact registered named paths (including aliases) in
`lib/app/app.dart`, and widget tests can inject one of those strings through
`FamilyHouseConnectApp(initialRoute: ...)`. That is route addressability for
tests, not production deep-link support.

Current limitations:

- Routing uses `MaterialApp.onGenerateRoute` plus a canonical alias resolver.
- Common Church, Home Church, Mission, KCA, Press, event, payment, and message
  resource paths normalize to existing screens; IDs are not repository-bound.
- Unknown paths render the Content Not Available state.
- There is no declarative `Router`, route-information parser, intended-route
  restoration, auth/onboarding redirect, or session-expiry redirect.
- `FhcRoutes` is incomplete: many registered paths are raw strings in screens
  or `app.dart`.
- `android/` and `ios/` projects now exist with App Links / Associated Domains
  scaffolds and `fhc://` custom scheme; hosted association files and store
  signing remain incomplete (see `docs/native/APP_LINK_ASSOCIATION.md`).
- Web uses the default Flutter bootstrap. There is no URL strategy or hosting
  rewrite configuration proven for direct path refresh.
- Notifications contain hard-coded in-memory route strings. They do not carry
  a server-issued destination type, resource ID, scope, expiry, or signed link.
- Widget tests cover canonical aliases, parameterized resource normalization,
  invalid-link fallback, and fail-closed authorization. Native cold/warm links,
  notifications, expiry, and intended-destination restoration remain.

The URI host below is intentionally a placeholder. An approved application
domain and association files are external prerequisites.

## Canonical destination proposal and implementation status

| DESTINATION TYPE | PROPOSED UNIVERSAL LINK | REQUIRED APP ROUTE | REQUIRED PARAMETERS | AUTH / AUTHORIZATION | SAFE FALLBACK | CURRENT STATUS |
|---|---|---|---|---|---|---|
| Global home | `https://<approved-app-domain>/home` | `/hub` | none | Session-aware | onboarding/sign-in, then intended route | Exact internal route exists; external link handling absent |
| Kingdom Journey milestone | `.../journey/{milestone}` | `/journey/:milestone` | milestone code | Auth; `journey.view_own` | `/journey` or restricted | Separate static routes exist; no parameter parser |
| Church profile | `.../churches/{churchId}` | `/church/:id` | canonical church ID | Public fields; re-check protected actions | `/churches`, 404/content unavailable | Only static `/church/detail`; OpenAPI `getChurch` exists but is unbound |
| Home Church | `.../home-churches/{homeChurchId}` | `/home-church/:id` | Home Church ID | Auth, membership/leadership permission, scope | restricted or public parent-church view | Only static `/home-church`; no ID/scope resolution |
| Event | `.../events/{eventId}` | `/events/:id` | event ID | Public detail; protected registration actions | `/events`, 404/content unavailable | Only static `/events/detail`; OpenAPI `getEvent` unbound |
| Event registration/ticket | `.../events/{eventId}/registration/{registrationId}` | `/events/:id/ticket/:registrationId` | event and registration IDs | Auth, ownership/scope | sign-in then intended route; restricted if not owner | Static `/events/tickets`; no IDs or ownership check |
| Mission location | `.../mission/locations/{locationId}` | `/mission/location/:id` | location ID | Public fields; scope for protected actions | `/map`, 404/content unavailable | Static `/map/mission-location`; list OpenAPI exists, no detail operation |
| Mission crusade | `.../mission/crusades/{crusadeId}` | `/mission/crusade/:id` | crusade ID | Public detail; permission for worker actions | public detail or restricted action | Static `/mission/crusade`; OpenAPI detail unbound |
| Mission soul | `.../mission/souls/{soulId}` | `/mission/soul/:id` | soul ID | Auth, permission, scope, restricted record policy | restricted without disclosing existence | Static `/mission/souls/profile`; no ID and no API contract |
| KCA module | `.../kca/modules/{moduleId}` | `/kca/module/:id` | module ID | Auth, enrolment, `kca.module.*`, prerequisites | KCA gate/locked/restricted | Static unguarded `/kca/module`; no ID or API contract |
| KCA assignment/evidence | `.../kca/assignments/{assignmentId}` | `/kca/assignment/:id` | assignment ID | Auth, ownership/cohort, `kca.assignment.*` | restricted/locked/not found | Static screens only; no ID or API contract |
| KCA certificate verification | `.../verify/kca-certificate?code={code}` | `/kca/verify?code=...` | certificate code | Public verification | invalid/expired verification state | Static `/kca/verify`; OpenAPI operation exists but query is not parsed |
| Press publication | `.../press/publications/{publicId}` | `/press/publication/:id` | public publication ID | Public catalogue; asset entitlement when needed | `/press`, content unavailable | Static `/press/publication`; OpenAPI detail unbound |
| Press player/download | `.../press/publications/{publicId}/play` | `/press/publication/:id/player` | publication/asset ID | Visibility and asset entitlement | publication detail or content unavailable | Static `/press/audio`; no ID, signed asset, or entitlement contract |
| Payment transaction | `.../payments/{paymentId}` | `/payments/:id` | payment ID | Auth, ownership, `finance.payment.*` | restricted without leaking record | Static guarded `/payments/transaction`; no ID/API contract |
| Payment receipt | `.../payments/{paymentId}/receipt` | `/payments/:id/receipt` | payment ID | Auth, ownership, `finance.receipts.*` | transaction/restricted | Static guarded `/payments/receipt`; no ID/API contract |
| Conversation | `.../messages/{conversationId}` | `/messages/:conversationId` | conversation ID | Auth, participant, safeguarding rules | inbox or restricted | `/messages` inbox and static mentor chat only |
| Notification destination | `.../notifications/{notificationId}` | `/notifications/:id` then typed target | notification ID and server target payload | Auth, target permission/scope/ownership, expiry | inbox, restricted, or content unavailable | In-memory notification rows push hard-coded generic routes |
| Guardian/child record | `.../guardian/children/{childId}` | `/guardian/child/:id` | child ID | Auth, guardian relationship, consent and child policy | restricted without record disclosure | Static guarded `/guardian/child`; resource ID not passed to guard |
| Leadership approval | `.../leadership/approvals/{requestId}` | `/leadership/approval/:id` | request ID and scope | Auth, recent MFA if required, exact scope | queue/restricted | Static guarded `/leadership/approval`; no ID/API contract |
| Content unavailable | internal fallback | `/content/unavailable` | reason, optional safe return target | Depends on original target | global hub | Implemented as unknown-route fallback; reason data remains pending |
| Offline downloads | internal only | `/downloads/storage` | optional asset/category | Auth for private assets | offline screen | Static guarded screen; no durable download index |

## Notification routing contract required from Laravel

A notification should not contain a raw arbitrary client route. The mobile
contract should return at least:

- notification ID and type;
- typed destination kind;
- canonical resource ID(s);
- organization scope identifier where relevant;
- minimum capability/permission hint for UX only;
- expiry and revocation state;
- safe fallback destination;
- server correlation ID.

The client must resolve the typed destination through a closed registry, then
perform authentication, verification/MFA policy, permission, scope, ownership,
and classification checks. Laravel remains authoritative. A 403 must show the
restricted state; a 404/expired target must show content unavailable; an
unauthenticated user must be returned to the intended route only after a valid
session is established.

## Required implementation work

1. Approve the universal-link domain and URI namespace.
2. Add Android/iOS platform projects and configure App Links/Universal Links
   plus association files.
3. Replace exact-switch navigation with a declarative router or equivalent
   route-information parser supporting typed parameters and nested back stacks.
4. Centralize every route in a canonical registry; remove raw route strings.
5. Add auth/onboarding/verification/MFA redirects with intended-route restore.
6. Pass resource ID and organization scope into `PermissionGuard` or a richer
   route guard.
7. Bind route loaders to repositories so 404, 403, offline, and expired states
   are authoritative.
8. Implement a typed notification destination resolver.
9. Add platform and widget/integration tests for cold start, warm start, invalid
   link, expired link, unauthenticated restore, wrong role, wrong scope, 403,
   404, notification back navigation, and web direct refresh.
