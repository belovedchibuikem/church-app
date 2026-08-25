# Family House Connect Mobile — Requirements Traceability

Updated: 2026-08-24

The three assigned reference sheets are implemented as one Flutter application. Duplicate visual explorations are canonicalized according to the approved mobile closure document.

| Screen ID | Route | Roles | Permission | API domain | Reference | Verification |
|---|---|---|---|---|---|---|
| FHC-011 | `/home` | visitor, member | `home.view` | identity/modules | 07:36 sheet | widget + visual |
| CH-001 | `/discover/churches` | visitor, member | `church.discovery.view` | churches/geography | 10:51 sheet | visual |
| CH-002 | `/church/family-house-ikeja` | visitor, member | `church.detail.view` | churches | 10:51 sheet | visual |
| CH-012 | `/church` | member, leader | `church.dashboard.view` | churches/memberships | 07:36 sheet | visual |
| CH-021 | `/prayer` | visitor, member | `prayer.view` | prayer | 10:48 sheet | visual |
| HC-002..005 | `/home-church/apply/*` | visitor, member | `home_church.apply` | home-churches | 10:48 sheet | route + visual |
| HC-007 | `/home-church/applications` | member | `home_church.application.view` | home-churches | 10:48 sheet | visual |
| HC-008 | `/home-church` | home church leader | `home_church.dashboard.view` | home-churches | 10:51 sheet | visual |
| OC-002 | `/online-church/live` | visitor, member | `online_church.view` | online-church | 07:36 sheet | visual |
| MS-001 | `/mission` | member, mission worker | `mission.dashboard.view` | mission | 10:51 sheet | visual |
| MS-004 | `/mission/crusades/lagos-outreach` | mission worker, leader | `mission.crusade.view` | crusades | 10:51 sheet | visual |
| KCA-001 | `/kca/enroll` | visitor, member | `kca.enroll` | kca | 10:51 sheet | visual |
| KCA-015 | `/kca` | KCA student | `kca.dashboard.view` | kca | 10:48 sheet | visual |
| KCA-016 | `/kca/modules` | KCA student, mentor | `kca.modules.view` | kca | 10:48 sheet | visual |
| KCA-017 | `/kca/modules/leadership-influence` | KCA student, mentor | `kca.lesson.view` | kca | 10:51 sheet | visual |
| KCA-021 | `/kca/assignments` | KCA student | `kca.assignments.view` | kca | 10:51 sheet | visual |
| KCA-030 | `/messages/mentor` | KCA student, mentor | `kca.mentor_chat.view` | kca/communications | 10:51 sheet | visual |
| PR-001 | `/press` | visitor, member | `press.library.view` | press | 10:51 sheet | visual |
| PR-003 | `/press/publications/walking-in-purpose` | visitor, member | `press.publication.view` | press | 07:36 sheet | visual |
| EV-001 | `/events` | visitor, member | `events.view` | events | 10:48 sheet | visual |
| PAY-001 | `/giving` | member | `giving.create` | giving/payments | 10:51 sheet | visual |
| COM-004 | `/notifications` | member | `notifications.view` | communications/alerts | 10:51 sheet | visual |
| SEC-001 | `/profile` | member | `profile.view` | users/people | 10:48 sheet | visual |
| SEC-002 | `/settings` | member | `settings.view` | users/security | 10:51 sheet | visual |

## Authorization evidence

- `PermissionGuard` calls an injected `AuthorizationGateway` before rendering protected content.
- A widget test verifies that a server-style forbidden decision produces `RestrictedAccessState`.
- Laravel remains authoritative for every operation and resource. No Laravel application, OpenAPI file, base URL, token flow, permission matrix, or test account was present in the supplied workspace, so live Laravel authorization is **not verified** and is not represented as complete.

## Visual evidence

- All 27 canonical routes have deterministic 390 × 844 golden captures in `artifacts/screenshots/`.
- `artifacts/screenshots/all-canonical.png` provides the combined comparison surface.
- See `VISUAL_VALIDATION.md` for the discrepancy loop and the source-resolution limitation.

## State and platform notes

- Loading, access-check failure, forbidden/restricted, and data/reference states are implemented at the shared guard level.
- Reference assets are bundled locally, so the approved screens render offline. Privileged workflows are never marked complete offline.
- English is the frozen reference language. The application registers English, Yoruba, Igbo, Hausa, French, Arabic, Chinese, and Swahili locales; production translations remain an open content dependency.
- Screen semantics and 390×844 responsive scaling are covered by widget tests.
