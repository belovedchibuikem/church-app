# Family House Connect Mobile — Requirements Traceability

Updated: 2026-08-26

Active references:

- `assets/design/community_13_reference.png`
- `assets/design/expansion_sheet_1.png` through
  `assets/design/expansion_sheet_7.png`
- `assets/design/continuation_sheet_1.png` through
  `assets/design/continuation_sheet_8.png`
- `assets/design/closure_offline_sheet.png`

## Screen-to-route mapping

1. Discover Churches — `/discover` — public discovery — `church.discovery.view`
2. Church Detail — `/church/detail` — public church profile — `church.detail.view`
3. Live Service — `/fellowship/live` — public/member stream — `online_church.view`
4. Give / Donate — `/give` — protected — `giving.create`
5. Sermons / Library — `/sermons` — public/member library — `sermons.view`
6. Prayer Requests — `/prayer` — protected — `prayer.view`
7. Groups / Small Groups — `/groups` — protected — `groups.view`
8. Events — `/events` — public/member events — `events.view`
9. Notifications — `/notifications` — protected — `notifications.view`
10. Profile — `/profile` — protected — `profile.view`
11. Bible — `/bible` — public/member scripture — `bible.view`
12. Giving History — `/give/history` — protected — `giving.history.view`
13. Settings — `/settings` — protected — `settings.view`

## Expansion canonical routes

Repeated screenshots across the seven expansion sheets are intentionally
deduplicated onto these canonical implementations.

- Church and Home Church: `/church/reports`, `/church/first-timers`,
  `/home-church/members`, `/home-church/attendance`,
  `/home-church/activities`, `/home-church/finance`,
  `/home-church/monthly-report`, `/home-church/share-need`,
  `/home-church/needs`, `/online-church`, `/altar-call`,
  `/altar-call/submitted`, `/altar-call/follow-ups`,
  `/counseling/request`, `/needs/request`, `/needs/status`,
  `/testimony/new`, and `/leadership`.
- Events and account: `/wallet`, `/events/register`, `/events/payment`,
  `/events/tickets`, `/events/attendance`, and `/events/feedback`.
- Mission: `/mission/partners`, `/mission/partner`, `/mission/support`,
  `/mission/invite`, `/mission/request-status`, `/mission/souls/add`,
  `/mission/souls/profile`, `/mission/mentor-assignment`, `/mission/teams`,
  `/mission/support-request`, and `/mission/assignments`.
- KCA: `/kca/evidence`, `/kca/submissions`, `/kca/certification`,
  `/kca/admission`, `/kca/attendance`, `/kca/mentees`, `/kca/review`,
  `/kca/assessment`, `/kca/certificate`, `/kca/verify`, `/kca/alumni`,
  `/kca/alumni/dashboard`, and `/kca/opportunities`.
- Press: `/press/categories`, `/press/resource`, `/press/audio`, and
  `/downloads`.

Existing canonical screens such as dashboards, directories, groups, services,
giving, notifications, settings, event details, and Press publications are
reused wherever an expansion sheet repeats their design.

## Continuation canonical routes

The eight continuation sheets and final closure sheet add 95 distinct routes after deduplicating soul
capture, need/testimony, Church activity/finance, Mission assignment/crusade,
KCA admission/attendance/review/certificate, and other already implemented
screens.

- Payments and preferences: `/payments/receipt`,
  `/payments/receipt/share`, `/payments/history`, `/payments/transaction`,
  `/payments/pending`, `/payments/refund`, `/payments/dispute`,
  `/payments/processing`, `/payments/success`, `/payments/failed`,
  `/giving/recurring`, `/settings/notifications`, and
  `/settings/communications`.
- Privacy, guardian and safeguarding: `/settings/sessions`,
  `/settings/privacy`, `/settings/consents`, `/settings/data-export`,
  `/settings/delete-account`, `/guardian/child`, `/guardian/controls`,
  `/guardian/consent`, `/guardian/restricted`, `/safeguarding/report`, and
  `/pastoral/record`.
- KCA lifecycle: `/kca/enrollment/1` through `/kca/enrollment/8`,
  `/kca/application-review`, `/kca/admission-letter`, `/kca/orientation`,
  `/kca/practical-service`, `/kca/written-assessments`,
  `/kca/spiritual-assignment`, `/kca/self-review`, `/kca/admin-review`,
  `/kca/locked-module`, `/kca/physical-assignment`,
  `/kca/mentor-dashboard`, `/kca/lecturer`, `/kca/intervention`, and
  `/kca/admission-decision`.
- Kingdom Journey: `/journey`, `/journey/discover`,
  `/journey/join-church`, `/journey/member`, `/journey/grow`,
  `/journey/serve`, `/journey/win-souls`, `/journey/become-kca`,
  `/journey/home-church`, and `/journey/multiply`.
- Membership and leadership: `/membership/register`,
  `/first-timer/register`, `/first-timer/journey`, `/convert/profile`,
  `/disciple/progress`, `/member/profile`, `/ministry/role`,
  `/ministry/history`, `/evangelism/activity`, `/evangelism/report`,
  `/referrals/connect`, `/referrals/tracking`, `/leadership/approvals`,
  `/leadership/approval`, `/leadership/reports`, and `/leadership/alerts`.
- AI, scope and map: `/ai`, `/ai/pastoral`, `/ai/mission`, `/ai/kca`,
  `/ai/press`, `/ai/pastoral-reports`, `/leadership/scope`,
  `/leadership/scope-dashboard`, `/map`, `/map/filter`,
  `/map/mission-location`, `/map/no-church`, and `/global-expansion`.
- Additional distinct Church forms: `/needs/detail` and
  `/church/attendance/record`.
- Offline, synchronization, upload, and recovery states: `/offline`,
  `/sync/pending`, `/sync/success`, `/uploads/progress`, `/uploads/failed`,
  `/downloads/storage`, `/settings/low-bandwidth`, and
  `/content/unavailable`.

## Implementation evidence

- All 13 screens are native Flutter widget trees. Raster assets are limited to
  reference photography, avatars, thumbnails, and banner artwork.
- `FhcDevicePage` uses the platform safe area and overlay style only. It does
  not draw time, battery, Wi-Fi, or cellular status widgets.
- The default app route is `/discover`; every reference screen is directly
  route-addressable.
- Shared color, typography, spacing, radius, elevation, sizing, and motion
  tokens are centralized in `lib/core/design_system/fhc_tokens.dart`.
- Deterministic captures use a 390 x 844 viewport and are stored under
  `artifacts/screenshots/community/` and `artifacts/screenshots/expansion/`.
- Continuation captures are stored under
  `artifacts/screenshots/continuation/` and grouped into seven final comparison
  sheets.
- Shared expansion primitives live in
  `lib/shared/widgets/workflow_components.dart`; feature screens remain split
  by Church, Mission, KCA, and community/Press boundaries.
- Workflow tests verify altar-call confirmation, need submission/status,
  event registration/payment/ticketing, Mission support, and KCA evidence
  review navigation.
- Continuation workflow tests verify payment-to-receipt, KCA enrolment,
  Kingdom Journey, membership registration, leadership scope, server-pending
  sync behavior, upload pause/retry, local storage/preferences, and exact
  server-scoped permissions for sensitive payment, privacy, guardian,
  safeguarding, pastoral, KCA, leadership, AI, sync, upload, and download
  routes.

## Authorization evidence

- Protected routes are wrapped by `PermissionGuard` and call an injected
  `AuthorizationGateway` before rendering their content.
- Widget tests verify server-style denial states and exact permission requests
  for Giving, Wallet, Home Church finance, altar-call follow-up, Mission soul
  capture, KCA evidence/review, sync queue, upload retry, and download
  management routes.
- The sibling Laravel application exposes 67 `/api/v1` routes. Its public
  OpenAPI contains 14 operations covering health, Church discovery, a Home
  Church application, public events/Press/Mission, and KCA certificate
  verification. Laravel authorization, scope containment, mobile credential,
  protected-user, and OpenAPI contract tests are run during closeout.
- Flutter production bootstrap fails closed through
  `UnconfiguredAuthorizationGateway`; visual tests explicitly opt into the
  allow-all review adapter. The Laravel transport/token adapter remains an
  integration gap, so mobile-to-Laravel authorization is not falsely claimed.
- Transport/failure, repository, and sync contracts are present under
  `lib/core`; the 14-operation public client and protected/mobile OpenAPI still
  require generation/binding.

## Verification commands

```sh
flutter analyze
flutter test --concurrency=1 --reporter compact
flutter build web --release
flutter run -d chrome
```

See `VISUAL_VALIDATION.md` for the visual discrepancy loop and capture result.
