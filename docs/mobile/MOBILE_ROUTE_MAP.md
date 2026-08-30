# Family House Connect Mobile Route Map

Updated: 2026-08-26

## Audit basis

This map is an inventory of the router that exists in `lib/app/app.dart`, not a
proposal for a replacement router. The current application uses
`MaterialApp.onGenerateRoute`, path strings, `FhcRoutes` constants where they
exist, and `PermissionGuard` for selected destinations.

- Registered path strings: **212**
- Canonical destinations after alias consolidation: **208**
- Explicit aliases: **4**
- Parameterized route aliases: common resource paths normalize to canonical
  destinations; selected-record loading remains unbound.
- Unknown-route behavior: renders Content Not Available while retaining the
  requested `RouteSettings.name`.
- Route names: Flutter route names are the path strings. `FhcRoutes` centralizes
  106 of them; the remaining paths are raw literals in the router and/or UI.

Gate notation:

- `Open` — no `PermissionGuard` is present. This describes current client
  behavior and is not a claim that the backend resource is public.
- `G:<permission>` — the route invokes `AuthorizationGateway.authorize` with
  that exact permission.
- No route currently supplies `resourceId` or `organizationScope` to the guard.
- Production/default bootstrap uses `UnconfiguredAuthorizationGateway` and
  fails closed. Visual tests inject the review gateway explicitly; a live
  Laravel-backed gateway is not bound.

## Foundation, onboarding and global shell

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/splash` | Splash | Open | root → `/onboarding/discover` |
| `/onboarding/discover` | Onboarding: Discover | Open | splash → `/onboarding/connect` or `/language` |
| `/onboarding/connect` | Onboarding: Connect | Open | onboarding → `/onboarding/multiply` or `/language` |
| `/onboarding/multiply` | Onboarding: Multiply | Open | onboarding → `/home-church/start` or `/language` |
| `/language` | Language & location | Open | onboarding → `/sign-in` |
| `/sign-in` | Sign in | Open | setup → `/verify-phone` |
| `/verify-phone` | Verify phone | Open | sign in → `/2fa` or `/sign-in` |
| `/2fa` | Two-factor authentication | Open | verification → `/role-selection` |
| `/role-selection` | Role/experience selection | Open | setup → `/hub` |
| `/hub` | Application/module hub | Open | top-level shell → modules and quick actions |
| `/modules` | Module selector | Open | hub → Church, Mission, KCA, Press |
| `/discover` | Discover churches | Open | shell; canonical discovery root → `/church/detail` |
| `/messages` | Messages inbox | Open | shell; thread rows → configured resource routes |
| `/notifications` | Notifications | `G:notifications.view` | account → `/messages`, `/events`, `/sermons`, `/prayer`, `/groups` |
| `/profile` | Profile | `G:profile.view` | shell → giving, prayer, groups, settings |
| `/settings` | Settings | `G:settings.view` | profile → notification/privacy settings, sign in |

## Church and Home Church

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/church` | Church dashboard | `G:church.dashboard.view` | modules → prayer, events, detail, live service |
| `/church/admin` | Church admin dashboard | `G:church.dashboard.view` | Church → `/church` |
| `/church/home` | Church module home | Open | modules → Church feature rows |
| `/church/detail` | Church detail | Open | discover → back/discover |
| `/church/members` | Members directory | Open | Church home → messages |
| `/church/groups` | Ministry groups | Open | Church home → `/groups` |
| `/church/announcements` | Announcements | Open | Church home → notifications |
| `/church/ministries` | Ministries | Open | Church home → Church groups |
| `/church/documents` | Church documents | Open | Church home |
| `/church/settings` | Church settings | Open | Home Church → configured settings rows |
| `/church/reports` | Church reports | `G:church.reports.view` | Church dashboard |
| `/church/first-timers` | First-timer follow-up | `G:church.followup.view` | Church dashboard |
| `/church/attendance` | Church attendance | `G:church.attendance.manage` | Church dashboard |
| `/church/attendance/record` | Record attendance | `G:church.attendance.manage` | attendance |
| `/church/activities` | Church activities | `G:church.activities.manage` | Church dashboard |
| `/church/finance` | Church finance | `G:church.finance.view` | Church dashboard |
| `/leadership` | Leadership dashboard | `G:leadership.dashboard.view` | modules/leadership |
| `/home-church` | Home Church dashboard | Open | modules → members, attendance, activities, reports, prayer, messages |
| `/home-church/members` | Home Church members | `G:home_church.members.view` | Home Church |
| `/home-church/attendance` | Home Church attendance | `G:home_church.attendance.manage` | Home Church |
| `/home-church/activities` | Home Church activities | `G:home_church.activities.manage` | Home Church |
| `/home-church/finance` | Home Church finance | `G:home_church.finance.view` | Home Church |
| `/home-church/reports` | Home Church reports | `G:home_church.reports.view` | Home Church |
| `/home-church/monthly-report` | Monthly report | `G:home_church.reports.create` | Home Church reports |
| `/home-church/share-need` | Share a need | `G:home_church.needs.create` | Home Church |
| `/home-church/needs` | Needs management | `G:home_church.needs.manage` | Home Church |
| `/home-church/start` | Start Home Church: identity | Open | onboarding/hub → step 2 |
| `/home-church/start/2` | Start Home Church: location | Open | step 1 → step 3 |
| `/home-church/start/3` | Start Home Church: plan | Open | step 2 → step 4 |
| `/home-church/start/4` | Start Home Church: review | Open | step 3 → progress |
| `/home-church/applications` | Home Church applications | Open | progress/Home Church |
| `/home-church/progress` | Home Church application progress | Open | step 4 → applications |
| `/online-church` | Online Church | Open | Church/modules → live service |
| `/altar-call` | Digital altar call | Open | Church → submitted |
| `/altar-call/submitted` | Altar-call confirmation | Open | altar call → Church home |
| `/altar-call/follow-ups` | Altar-call follow-ups | `G:altar_call.followup.view` | Church dashboard |
| `/counseling/request` | Counselling request | `G:counselling.create` | Church/more |
| `/needs/request` | Need request | `G:needs.create` | Church → status |
| `/needs/status` | Need status | `G:needs.view_own` | need request |
| `/needs/detail` | Need details | `G:needs.view_own` | need status |
| `/testimony/new` | Testimony submission | `G:testimony.create` | Church/more |

## Community, events, giving and media

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/events` | Events | Open | shell/discover → detail |
| `/events/detail` | Event detail | Open | events → giving/register entry points |
| `/events/register` | Event registration | Open | detail → payment |
| `/events/payment` | Event payment | Open | registration → tickets |
| `/events/tickets` | Event tickets | Open | payment → event detail |
| `/events/attendance` | Event attendance | Open | ticket/event workflow |
| `/events/feedback` | Event feedback | Open | event workflow |
| `/prayer` | Prayer requests | `G:prayer.view` | discover/profile → new request |
| `/prayer/new` | New prayer request | `G:prayer.create` | prayer → prayer |
| `/give` | Give | `G:giving.create` | hub/event/profile |
| `/give/history` | Giving history | `G:giving.history.view` | profile |
| `/giving/recurring` | Recurring giving | `G:giving.recurring.manage` | giving/payments |
| `/wallet` | Wallet | `G:wallet.view` | giving/profile |
| `/fellowship/live` | Live service/fellowship | Open | Church, sermons, online Church |
| `/sermons` | Sermons library | Open | discover → live service |
| `/groups` | Community groups | `G:groups.view` | discover/messages/profile |
| `/bible` | Bible | Open | discover |
| `/media` | Media hub | Open | modules → sermons, Bible, Press |

## Payments, receipts and preferences

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/payments/receipt` | Receipt detail | `G:payments.receipts.view_own` | transaction/success → share receipt |
| `/payments/receipt/share` | Share receipt | `G:payments.receipts.view_own` | receipt |
| `/payments/history` | Payment history | `G:payments.history.view_own` | giving/profile |
| `/payments/transaction` | Transaction detail | `G:payments.transactions.view_own` | history → receipt |
| `/payments/pending` | Payment pending | `G:payments.transactions.view_own` | processing → history |
| `/payments/refund` | Refund status | `G:payments.refunds.view_own` | transaction/history |
| `/payments/dispute` | Dispute/chargeback | `G:payments.disputes.view_own` | transaction/history |
| `/payments/processing` | Payment processing | `G:payments.create` | give/event payment |
| `/payments/success` | Payment success | `G:payments.transactions.view_own` | processing → receipt |
| `/payments/failed` | Payment failed | `G:payments.transactions.view_own` | processing/retry |
| `/settings/notifications` | Notification channel preferences | `G:settings.notifications.manage` | settings |
| `/settings/communications` | Communication preferences | `G:settings.communications.manage` | settings |

## Mission

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/mission` | Mission dashboard | `G:mission.dashboard.view` | modules → souls, teams, crusade |
| `/mission/crusade` | Crusade detail | `G:mission.dashboard.view` | Mission → souls |
| `/mission/invite` | Invite/request a crusade | Open | Mission → request status |
| `/mission/request-status` | Crusade request status | Open | invite |
| `/mission/souls` | Souls follow-up | `G:mission.dashboard.view` | Mission/crusade → messages |
| `/mission/souls/add` | Add soul | `G:mission.souls.create` | Mission → soul profile |
| `/mission/souls/profile` | Soul profile | `G:mission.souls.view` | souls/add |
| `/mission/mentor-assignment` | Assign mentor | `G:mission.mentors.assign` | soul profile |
| `/mission/teams` | Mission teams | Open | Mission |
| `/mission/support-request` | Mission support request | `G:mission.support.request` | Mission/partner |
| `/mission/assignments` | Mission worker assignments | `G:mission.assignments.view` | Mission |
| `/mission/partners` | Mission partners | Open | Mission → partner detail |
| `/mission/partner` | Mission partner detail | Open | partners → support |
| `/mission/support` | Support a mission | Open | partner detail |

## KCA

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/kca` | KCA dashboard | `G:kca.dashboard.view` | modules → modules, assignments, mentor |
| `/kca/gate` | KCA entry gate | Open | hub → enrol or dashboard |
| `/kca/enroll` | KCA enrolment landing | Open | gate → enrolment step 1 |
| `/kca/modules` | KCA modules | Open | dashboard → module |
| `/kca/module` | KCA module detail | Open | modules → lesson/assignments |
| `/kca/lesson` | KCA lesson | Open | module → assignments |
| `/kca/assignments` | KCA assignments | Open | module/dashboard → lesson |
| `/kca/mentor` | Mentor chat | Open | dashboard |
| `/kca/evidence` | Evidence upload | `G:kca.evidence.create` | assignments → submissions |
| `/kca/submissions` | Evidence submissions | `G:kca.evidence.view_own` | evidence |
| `/kca/certification` | Certification progress | `G:kca.certification.view_own` | KCA/journey |
| `/kca/admission` | Admission status | `G:kca.admission.view_own` | enrolment |
| `/kca/attendance` | KCA attendance | `G:kca.attendance.view` | KCA |
| `/kca/mentees` | Mentees | `G:kca.mentoring.view` | mentor dashboard |
| `/kca/review` | Mentor evidence review | `G:kca.evidence.review` | mentees/submissions |
| `/kca/assessment` | Final assessment | `G:kca.assessment.view_own` | KCA lifecycle |
| `/kca/certificate` | KCA certificate | `G:kca.certificate.view_own` | certification |
| `/kca/verify` | Certificate verification | Open | public verification |
| `/kca/alumni` | Alumni directory | Open | KCA |
| `/kca/alumni/dashboard` | Alumni dashboard | Open | KCA/profile |
| `/kca/opportunities` | Alumni opportunities | Open | alumni |
| `/kca/enrollment/1` | Enrolment: Church information | `G:kca.enrollment.create` | enrol landing → step 2 |
| `/kca/enrollment/2` | Enrolment: Walk with Christ | `G:kca.enrollment.create` | step 1 → step 3 |
| `/kca/enrollment/3` | Enrolment: Why join | `G:kca.enrollment.create` | step 2 → step 4 |
| `/kca/enrollment/4` | Enrolment: Interests and skills | `G:kca.enrollment.create` | step 3 → step 5 |
| `/kca/enrollment/5` | Enrolment: Commitments | `G:kca.enrollment.create` | step 4 → step 6 |
| `/kca/enrollment/6` | Enrolment: Personal commitment | `G:kca.enrollment.create` | step 5 → step 7 |
| `/kca/enrollment/7` | Enrolment: Guardian consent | `G:kca.enrollment.create` | step 6 → step 8 |
| `/kca/enrollment/8` | Enrolment: Recommendation | `G:kca.enrollment.create` | step 7 → application review |
| `/kca/application-review` | Application review status | `G:kca.admission.view_own` | enrolment → admission letter |
| `/kca/admission-letter` | Admission letter | `G:kca.admission.view_own` | review → orientation |
| `/kca/orientation` | Orientation | `G:kca.orientation.view` | admission → practical service |
| `/kca/practical-service` | Practical service | `G:kca.practical_service.manage` | orientation |
| `/kca/written-assessments` | Written assessments | `G:kca.assessments.view_own` | KCA lifecycle |
| `/kca/spiritual-assignment` | Spiritual assignment | `G:kca.assignments.view_own` | KCA lifecycle |
| `/kca/self-review` | Student self-review | `G:kca.reviews.create_own` | KCA lifecycle |
| `/kca/admin-review` | Administrator review | `G:kca.reviews.manage` | leadership/KCA |
| `/kca/locked-module` | Locked module/prerequisites | `G:kca.modules.view` | module progression |
| `/kca/physical-assignment` | Physical/practical assignment | `G:kca.assignments.create` | assignments |
| `/kca/mentor-dashboard` | Mentor dashboard | `G:kca.mentoring.view` | KCA → mentees/reviews |
| `/kca/lecturer` | Lecturer workspace | `G:kca.lessons.deliver` | KCA |
| `/kca/intervention` | Mentor intervention | `G:kca.mentoring.intervene` | mentor dashboard |
| `/kca/admission-decision` | Admission decision detail | `G:kca.admission.manage` | admissions/leadership |

## Press and downloads

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/press` | Press library | Open | modules → book/publication |
| `/press/book` | Press book reader/detail | Open | Press library |
| `/press/categories` | Press categories | Open | Press library |
| `/press/resource` | Press resource detail | Open | Press library |
| `/press/audio` | Press audio player | Open | Press resource/library |
| `/downloads` | Downloads/saved content | Open | Press/KCA/media |
| `/downloads/storage` | Downloads and storage management | `G:downloads.manage_own` | offline/downloads → low-bandwidth settings |

## Kingdom Journey, membership and leadership

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/journey` | Kingdom Journey overview | `G:journey.view_own` | shell → discover stage |
| `/journey/discover` | Discover Family House | `G:journey.view_own` | journey → join Church |
| `/journey/join-church` | Join Church | `G:journey.manage_own` | journey → member |
| `/journey/member` | Become a member | `G:journey.view_own` | journey → grow |
| `/journey/grow` | Grow spiritually | `G:journey.view_own` | journey stage |
| `/journey/serve` | Serve | `G:journey.view_own` | journey stage |
| `/journey/win-souls` | Win souls and disciple | `G:journey.view_own` | journey stage |
| `/journey/become-kca` | Become KCA/mentor | `G:journey.view_own` | journey → certification |
| `/journey/home-church` | Start/develop Home Church | `G:journey.view_own` | journey → Home Church |
| `/journey/multiply` | Plant Church/raise leaders/multiply | `G:journey.view_own` | journey terminal stage |
| `/membership/register` | Membership registration | `G:membership.create` | Church/journey → first-timer registration |
| `/first-timer/register` | First-timer registration | `G:church.first_timers.create` | Church → first-timer journey |
| `/first-timer/journey` | First-timer journey | `G:church.followup.view` | first-timer registration |
| `/convert/profile` | Convert profile | `G:mission.souls.view` | Mission/soul follow-up |
| `/disciple/progress` | Disciple progress | `G:discipleship.progress.view` | journey/mentoring |
| `/member/profile` | Member profile | `G:members.profile.view` | member directory |
| `/ministry/role` | Ministry role profile | `G:ministry.roles.view` | member/ministry |
| `/ministry/history` | Ministry history | `G:ministry.history.view_own` | profile/journey |
| `/evangelism/activity` | Evangelism activity | `G:mission.activities.create` | Mission → report |
| `/evangelism/report` | Evangelism report | `G:mission.reports.view` | activity/leadership |
| `/referrals/connect` | Connect/referral to Church | `G:church.referrals.manage` | convert/soul profile |
| `/referrals/tracking` | Referral tracking | `G:church.referrals.view` | referrals |
| `/leadership/approvals` | Approvals queue | `G:leadership.approvals.view` | leadership → approval detail |
| `/leadership/approval` | Approval request detail | `G:leadership.approvals.manage` | approvals |
| `/leadership/reports` | Leadership KPI reports | `G:leadership.reports.view` | leadership |
| `/leadership/alerts` | Leadership alerts | `G:leadership.alerts.view` | leadership |
| `/leadership/scope` | Leadership scope selector | `G:leadership.scope.select` | leadership → scoped dashboard |
| `/leadership/scope-dashboard` | Scope-aware leadership dashboard | `G:leadership.dashboard.view` | scope selector |

## AI, map and global expansion

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/ai` | AI assistant hub | `G:ai.assistants.use` | hub/profile → pastoral AI |
| `/ai/pastoral` | Pastoral AI assistant | `G:ai.pastoral.use` | AI hub |
| `/ai/mission` | Mission AI assistant | `G:ai.mission.use` | Mission/AI hub |
| `/ai/kca` | KCA AI study assistant | `G:ai.kca.use` | KCA/AI hub |
| `/ai/press` | Press AI assistant | `G:ai.press.use` | Press/AI hub |
| `/ai/pastoral-reports` | Pastoral AI reports mode | `G:ai.pastoral.reports` | leadership/AI |
| `/map` | Global Family House map | Open | discover/global expansion → filter/location |
| `/map/filter` | Map filter and search | Open | map |
| `/map/mission-location` | Mission location detail | Open | map |
| `/map/no-church` | No Church nearby state | Open | map/discover → global expansion |
| `/global-expansion` | Global expansion journey | Open | no-Church state |

## Privacy, guardian, safeguarding and account security

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/settings/sessions` | Active sessions | `G:security.sessions.manage` | settings/security |
| `/settings/privacy` | Privacy controls | `G:privacy.manage_own` | settings |
| `/settings/consents` | Consent management | `G:consents.manage_own` | privacy/settings |
| `/settings/data-export` | Data export | `G:privacy.export_own` | privacy/settings |
| `/settings/delete-account` | Account deletion | `G:privacy.delete_own` | privacy/settings |
| `/guardian/child` | Child profile | `G:guardian.child.view` | guardian/account |
| `/guardian/controls` | Guardian controls | `G:guardian.controls.manage` | guardian/account |
| `/guardian/consent` | Guardian consent | `G:guardian.consent.manage` | guardian/account |
| `/guardian/restricted` | Restricted child communication | `G:guardian.communication.view` | guardian/account |
| `/safeguarding/report` | Safeguarding report | `G:safeguarding.reports.create` | account/guardian |
| `/pastoral/record` | Restricted pastoral record | `G:pastoral.records.view` | pastoral/account |

## Offline, sync and recovery states

| Path | Destination | Gate | Parent / principal outgoing route |
|---|---|---|---|
| `/offline` | Offline mode | Open | connection state → storage/downloads |
| `/sync/pending` | Sync pending | `G:sync.queue.view_own` | offline/outbox |
| `/sync/success` | Sync successful | `G:sync.queue.view_own` | sync flow |
| `/uploads/progress` | Evidence upload progress | `G:uploads.view_own` | uploads/evidence |
| `/uploads/failed` | Upload failed/retry | `G:uploads.retry_own` | uploads → progress |
| `/settings/low-bandwidth` | Low-bandwidth media mode | Open | storage/settings |
| `/content/unavailable` | Deep-link content unavailable | Open | failed destination → hub/home |

## Aliases and consolidation

| Alias | Canonical route | Shared implementation |
|---|---|---|
| `/churches` | `/discover` | `FindChurchesScreen` |
| `/church/directory` | `/church/members` | `MembersListScreen` |
| `/first-timers` | `/church/first-timers` | `FirstTimersScreen` |
| `/press/publication` | `/press/resource` | `PressResourceDetailScreen` |

The alias paths are registered for compatibility but are not separate canonical
screens. Contextual variants such as Church/Home Church finance and
Alumni directory/dashboard remain separate canonical destinations because the
router supplies configuration that changes the screen context.

## Required-path comparison and gaps

The completion brief names conceptual routes that do not exactly match current
paths. Existing equivalents should be preferred until a migration decision is
approved:

| Brief path/concept | Current equivalent or gap |
|---|---|
| `/onboarding` | No route; use `/onboarding/discover` |
| `/setup/language`, `/setup/location` | Combined at `/language` |
| `/auth/login` | `/sign-in` |
| `/auth/register`, `/auth/verify-email`, `/auth/recovery` | No registered route |
| `/auth/verify-phone`, `/auth/mfa` | `/verify-phone`, `/2fa` |
| `/setup/profile`, `/setup/church-affiliation` | No dedicated route |
| `/setup/role` | `/role-selection` |
| `/home` | `/hub` |
| `/discover/map` | `/map` |
| `/discover/church/:id` | `/church/detail`; no route parameter/resource ID |
| `/discover/home-church/:id`, `/discover/mission/:id` | No parameterized destination |
| `/church/membership` | `/membership/register` |
| `/church/prayer`, `/church/events`, `/church/needs` | `/prayer`, `/events`, `/needs/request|status|detail` |
| `/home-church/application`, `/home-church/application/status` | `/home-church/start...` and `/home-church/progress` |
| `/home-church/dashboard` | `/home-church` |
| `/online-church/live`, `/online-church/sermons`, `/online-church/bible-study`, `/online-church/prayer` | Existing top-level `/fellowship/live`, `/sermons`, `/bible`, `/prayer` |
| `/mission/crusades`, `/mission/crusade/:id`, `/mission/soul/:id`, `/mission/follow-up` | Singular/static `/mission/crusade`, `/mission/souls/profile`, `/mission/souls`; no IDs |
| `/kca/application`, `/kca/dashboard`, `/kca/module/:id`, `/kca/assignment/:id` | Existing enrol/admission/dashboard/module/assignment routes; no IDs |
| `/press/library`, `/press/publication/:id`, `/press/player`, `/press/downloads` | `/press`, `/press/resource`, `/press/audio`, `/downloads`; no IDs |
| `/events/:id`, `/events/:id/register`, `/events/:id/ticket` | Static `/events/detail`, `/events/register`, `/events/tickets` |
| `/giving`, `/payments`, `/payments/:id`, `/payments/:id/receipt` | `/give`, `/payments/history`, `/payments/transaction`, `/payments/receipt` |
| `/messages/:conversationId` | Only `/messages`; no conversation route parameter |
| `/settings/security`, `/settings/preferences` | Split among `/settings/sessions`, `/settings/notifications`, `/settings/communications`, `/settings/privacy` |

## Architectural gaps discovered

1. The router is string-switch based, not typed/declarative, and only part of
   the path set is centralized in `FhcRoutes`.
2. There are no resource-ID parameters, query-state contracts, URI parsing
   helpers, nested shell routes, or route restoration contracts.
3. Authentication, verification, MFA, role, resource ownership and
   organization-scope redirects are not centralized. `PermissionGuard` checks
   only a permission string.
4. Production authorization fails closed; no Laravel/OpenAPI-backed adapter
   is bound yet.
5. Numerous internal screens are currently `Open` in Flutter (notably KCA
   learning, Mission partner/team views, Home Church application steps, and
   map/location detail). Backend authorization may still be expected, but no
   API is bound.
6. Unknown paths render Content Not Available; reason/return-target data and
   platform cold-link handling remain pending.
7. Notification navigation is hard-coded to five static destinations. There is
   no typed notification payload resolver or resource authorization handoff.
8. `/map`, `/map/mission-location`, `/kca/verify`, child/financial/pastoral
   destinations have no resource identifier in the route, so record ownership
   cannot be represented by navigation state.
