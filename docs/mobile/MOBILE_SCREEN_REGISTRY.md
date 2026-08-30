# Family House Connect Mobile Screen Registry

Updated: 2026-08-26

## Registry contract and limitations

This is the canonical inventory of screens reachable from
`lib/app/app.dart`. It is based on the implemented router and feature widgets,
with duplicate aliases consolidated. It contains **208 canonical screen
destinations** and documents the four aliases separately.

The following field rules apply to every row in the registry:

| Required field | Recorded value / rule |
|---|---|
| Canonical screen ID | Stable `FHC-<domain>-<number>` value in the tables below |
| Screen name / owning domain / route path | Explicit in each row |
| Route name | The path string is the Flutter route name. `C` means a matching `FhcRoutes` constant exists; `L` means the route is only a literal in the current route registry/UI |
| Parent, entry points, outgoing destinations | The matching path row in [MOBILE_ROUTE_MAP.md](MOBILE_ROUTE_MAP.md) is part of this registry and records these fields explicitly |
| Allowed roles | `Open`: no role is evaluated by Flutter. `G:<permission>`: any identity for which the injected gateway grants that permission. A canonical role-to-permission matrix is absent, so role names are not invented |
| Permission requirement | Explicit in the Gate column; `—` means no Flutter permission guard |
| Scope requirement | **Not encoded for any route.** No guard invocation passes `organizationScope` or `resourceId`; Laravel must remain authoritative |
| API dependencies | `API-UNBOUND` for every current screen. The source tree has presentation widgets but no feature repository/data-source/OpenAPI client; current content is local prototype data |
| Deep-link capability | Every row is static named-route addressable (`DL-S`). No screen has a typed resource-ID route (`DL-R` is absent) |
| Notification destination capability | `NT` marks a current hard-coded notification destination. Other registered paths are technically pushable but have no notification payload resolver |
| Authentication requirement | `G` routes can receive `unauthenticated`, `forbidden`, or `restricted` from `AuthorizationGateway`; Open routes have no auth gate. Production/default bootstrap fails closed; visual tests opt into the review gateway explicitly |
| Offline capability | `OF` marks an explicit offline/download/sync/recovery screen. Other screens have no verified offline repository contract |
| Sensitive-data classification | `PUB` public/general; `INT` internal ministry/profile; `PII` personal data; `FIN` financial; `CHD` child/guardian; `RST` restricted pastoral/safeguarding/leadership |
| Design reference | `F13` = `assets/design/foundation_13_reference.png`; `C13` = `assets/design/community_13_reference.png`; `E` = `assets/design/expansion_sheet_1.png` … `expansion_sheet_7.png`; `N` = `assets/design/continuation_sheet_1.png` … `continuation_sheet_8.png`; `O` = `assets/design/closure_offline_sheet.png` |
| Implementation status | All rows are `UI` (native Flutter UI registered). This does **not** mean API-integrated, production-authorized, localized, or workflow-complete |

Implementation abbreviations:

- `ACS.<kind>` — `AccountContinuationScreen(kind: ...)`
- `KLS.<kind>` — `KcaLifecycleScreen(kind: ...)`
- `KJS.<kind>` — `KingdomJourneyScreen(kind: ...)`
- `LCS.<kind>` — `LeadershipContinuationScreen(kind: ...)`
- `OSS.<kind>` — `OfflineSyncScreen(kind: ...)`

## Foundation, onboarding and account shell (16)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-FND-001 | Splash | `/splash` | C | `SplashScreen` | — | PUB | F13 | UI, DL-S |
| FHC-FND-002 | Onboarding — Discover | `/onboarding/discover` | L | `OnboardingDiscoverScreen` | — | PUB | F13 | UI, DL-S |
| FHC-FND-003 | Onboarding — Connect | `/onboarding/connect` | L | `OnboardingConnectScreen` | — | PUB | F13 | UI, DL-S |
| FHC-FND-004 | Onboarding — Multiply | `/onboarding/multiply` | L | `OnboardingMultiplyScreen` | — | PUB | F13 | UI, DL-S |
| FHC-FND-005 | Language & location | `/language` | L | `LanguageLocationScreen` | — | PII | F13 | UI, DL-S |
| FHC-FND-006 | Sign in | `/sign-in` | L | `SignInScreen` | — | PII | F13 | UI, DL-S |
| FHC-FND-007 | Verify phone | `/verify-phone` | L | `VerifyPhoneScreen` | — | PII | F13 | UI, DL-S |
| FHC-FND-008 | Two-factor authentication | `/2fa` | L | `TwoFactorScreen` | — | PII | F13 | UI, DL-S |
| FHC-FND-009 | Role selection | `/role-selection` | L | `RoleSelectionScreen` | — | PII | F13 | UI, DL-S |
| FHC-FND-010 | Module hub | `/hub` | C | `ModuleHubScreen` | — | INT | F13 | UI, DL-S |
| FHC-FND-011 | Modules | `/modules` | C | `ModulesScreen` | — | INT | F13 | UI, DL-S |
| FHC-FND-012 | Discover churches | `/discover` | C | `FindChurchesScreen` | — | PUB | C13 | UI, DL-S |
| FHC-FND-013 | Messages inbox | `/messages` | C | `MessagesInboxScreen` | — | PII | C13 | UI, DL-S, NT |
| FHC-FND-014 | Notifications | `/notifications` | C | `NotificationsScreen` | `notifications.view` | PII | C13 | UI, DL-S |
| FHC-FND-015 | Profile | `/profile` | C | `ProfileScreen` | `profile.view` | PII | C13 | UI, DL-S |
| FHC-FND-016 | Settings | `/settings` | C | `SettingsScreen` | `settings.view` | PII | C13 | UI, DL-S |

## Church and Home Church (40)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-CHU-001 | Church dashboard | `/church` | C | `ChurchDashboardScreen` | `church.dashboard.view` | INT | F13 | UI, DL-S |
| FHC-CHU-002 | Church admin dashboard | `/church/admin` | C | `ChurchAdminDashboardScreen` | `church.dashboard.view` | RST | F13 | UI, DL-S |
| FHC-CHU-003 | Church module home | `/church/home` | C | `ChurchModuleHomeScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-004 | Church detail | `/church/detail` | C | `ChurchDetailScreen` | — | PUB | C13 | UI, DL-S |
| FHC-CHU-005 | Members directory | `/church/members` | C | `MembersListScreen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-006 | Church groups | `/church/groups` | C | `ChurchGroupsScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-007 | Announcements | `/church/announcements` | C | `AnnouncementsScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-008 | Ministries | `/church/ministries` | C | `MinistriesScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-009 | Church documents | `/church/documents` | C | `DocumentsScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-010 | Church settings | `/church/settings` | C | `ChurchSettingsScreen` | — | RST | F13 | UI, DL-S |
| FHC-CHU-011 | Church reports | `/church/reports` | C | `ChurchReportsScreen` | `church.reports.view` | RST | E | UI, DL-S |
| FHC-CHU-012 | First-timer follow-up | `/church/first-timers` | C | `FirstTimersScreen` | `church.followup.view` | PII | E | UI, DL-S |
| FHC-CHU-013 | Church attendance | `/church/attendance` | C | `HomeChurchAttendanceScreen` | `church.attendance.manage` | PII | E | UI, DL-S |
| FHC-CHU-014 | Record attendance | `/church/attendance/record` | L | `RecordAttendanceScreen` | `church.attendance.manage` | PII | N | UI, DL-S |
| FHC-CHU-015 | Church activities | `/church/activities` | C | `HomeChurchActivitiesScreen` | `church.activities.manage` | INT | E | UI, DL-S |
| FHC-CHU-016 | Church finance | `/church/finance` | C | `ChurchFinanceScreen` | `church.finance.view` | FIN | E | UI, DL-S |
| FHC-CHU-017 | Home Church dashboard | `/home-church` | C | `HomeChurchDashboardScreen` | — | INT | F13 | UI, DL-S |
| FHC-CHU-018 | Home Church members | `/home-church/members` | C | `HomeChurchMembersScreen` | `home_church.members.view` | PII | E | UI, DL-S |
| FHC-CHU-019 | Home Church attendance | `/home-church/attendance` | C | `HomeChurchAttendanceScreen` | `home_church.attendance.manage` | PII | E | UI, DL-S |
| FHC-CHU-020 | Home Church activities | `/home-church/activities` | C | `HomeChurchActivitiesScreen` | `home_church.activities.manage` | INT | E | UI, DL-S |
| FHC-CHU-021 | Home Church finance | `/home-church/finance` | C | `ChurchFinanceScreen(homeChurch: true)` | `home_church.finance.view` | FIN | E | UI, DL-S |
| FHC-CHU-022 | Home Church reports | `/home-church/reports` | C | `ChurchReportsScreen(homeChurch: true)` | `home_church.reports.view` | RST | E | UI, DL-S |
| FHC-CHU-023 | Monthly report | `/home-church/monthly-report` | C | `MonthlyReportScreen` | `home_church.reports.create` | RST | E | UI, DL-S |
| FHC-CHU-024 | Share a need | `/home-church/share-need` | C | `ShareNeedScreen` | `home_church.needs.create` | PII | E | UI, DL-S |
| FHC-CHU-025 | Needs management | `/home-church/needs` | C | `NeedsManagementScreen` | `home_church.needs.manage` | RST | E | UI, DL-S |
| FHC-CHU-026 | Start Home Church — step 1 | `/home-church/start` | C | `StartHomeChurchStep1Screen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-027 | Start Home Church — step 2 | `/home-church/start/2` | C | `StartHomeChurchStep2Screen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-028 | Start Home Church — step 3 | `/home-church/start/3` | C | `StartHomeChurchStep3Screen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-029 | Start Home Church — step 4 | `/home-church/start/4` | C | `StartHomeChurchStep4Screen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-030 | Home Church applications | `/home-church/applications` | C | `HomeChurchApplicationsScreen` | — | RST | F13 | UI, DL-S |
| FHC-CHU-031 | Home Church application progress | `/home-church/progress` | C | `StartHomeChurchProgressScreen` | — | PII | F13 | UI, DL-S |
| FHC-CHU-032 | Online Church | `/online-church` | C | `OnlineChurchScreen` | — | PUB | E | UI, DL-S |
| FHC-CHU-033 | Digital altar call | `/altar-call` | C | `AltarCallScreen` | — | PII | E | UI, DL-S |
| FHC-CHU-034 | Altar-call submitted | `/altar-call/submitted` | C | `AltarCallSubmittedScreen` | — | PII | E | UI, DL-S |
| FHC-CHU-035 | Altar-call follow-ups | `/altar-call/follow-ups` | C | `AltarCallFollowupsScreen` | `altar_call.followup.view` | RST | E | UI, DL-S |
| FHC-CHU-036 | Counselling request | `/counseling/request` | C | `CounselingRequestScreen` | `counselling.create` | RST | E | UI, DL-S |
| FHC-CHU-037 | Need request | `/needs/request` | C | `NeedRequestScreen` | `needs.create` | PII | E | UI, DL-S |
| FHC-CHU-038 | Need status | `/needs/status` | C | `NeedStatusScreen` | `needs.view_own` | PII | E | UI, DL-S |
| FHC-CHU-039 | Need details | `/needs/detail` | L | `NeedDetailsScreen` | `needs.view_own` | PII | N | UI, DL-S |
| FHC-CHU-040 | Testimony submission | `/testimony/new` | C | `TestimonySubmissionScreen` | `testimony.create` | PII | E | UI, DL-S |

## Community, events, giving and media (17)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-COM-001 | Events | `/events` | C | `EventsScreen` | — | PUB | C13 | UI, DL-S, NT |
| FHC-COM-002 | Event detail | `/events/detail` | C | `EventDetailScreen` | — | PUB | E | UI, DL-S |
| FHC-COM-003 | Event registration | `/events/register` | C | `EventRegistrationScreen` | — | PII | E | UI, DL-S |
| FHC-COM-004 | Event payment | `/events/payment` | C | `EventPaymentScreen` | — | FIN | E | UI, DL-S |
| FHC-COM-005 | Event tickets | `/events/tickets` | C | `EventTicketsScreen` | — | PII | E | UI, DL-S |
| FHC-COM-006 | Event attendance | `/events/attendance` | C | `EventAttendanceScreen` | — | PII | E | UI, DL-S |
| FHC-COM-007 | Event feedback | `/events/feedback` | C | `EventFeedbackScreen` | — | INT | E | UI, DL-S |
| FHC-COM-008 | Prayer requests | `/prayer` | C | `PrayerScreen` | `prayer.view` | PII | C13 | UI, DL-S, NT |
| FHC-COM-009 | New prayer request | `/prayer/new` | C | `PrayerNewScreen` | `prayer.create` | PII | C13 | UI, DL-S |
| FHC-COM-010 | Give | `/give` | C | `GiveScreen` | `giving.create` | FIN | C13 | UI, DL-S |
| FHC-COM-011 | Giving history | `/give/history` | C | `GivingHistoryScreen` | `giving.history.view` | FIN | C13 | UI, DL-S |
| FHC-COM-012 | Wallet | `/wallet` | C | `WalletScreen` | `wallet.view` | FIN | E | UI, DL-S |
| FHC-COM-013 | Live service | `/fellowship/live` | C | `LiveFellowshipScreen` | — | PUB | C13 | UI, DL-S |
| FHC-COM-014 | Sermons library | `/sermons` | C | `SermonsLibraryScreen` | — | PUB | C13 | UI, DL-S, NT |
| FHC-COM-015 | Groups | `/groups` | C | `GroupsScreen` | `groups.view` | INT | C13 | UI, DL-S, NT |
| FHC-COM-016 | Bible | `/bible` | C | `BibleScreen` | — | PUB | C13 | UI, DL-S |
| FHC-COM-017 | Media hub | `/media` | C | `MediaHubScreen` | — | PUB | F13 | UI, DL-S |

## Payments (11)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-PAY-001 | Receipt detail | `/payments/receipt` | L | `ACS.receipt` | `payments.receipts.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-002 | Share receipt | `/payments/receipt/share` | L | `ACS.shareReceipt` | `payments.receipts.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-003 | Payment history | `/payments/history` | L | `ACS.paymentHistory` | `payments.history.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-004 | Transaction detail | `/payments/transaction` | L | `ACS.transaction` | `payments.transactions.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-005 | Payment pending | `/payments/pending` | L | `ACS.paymentPending` | `payments.transactions.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-006 | Refund status | `/payments/refund` | L | `ACS.refund` | `payments.refunds.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-007 | Dispute / chargeback | `/payments/dispute` | L | `ACS.dispute` | `payments.disputes.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-008 | Recurring giving | `/giving/recurring` | L | `ACS.recurringGiving` | `giving.recurring.manage` | FIN | N | UI, DL-S |
| FHC-PAY-009 | Payment processing | `/payments/processing` | L | `ACS.paymentProcessing` | `payments.create` | FIN | N | UI, DL-S |
| FHC-PAY-010 | Payment success | `/payments/success` | L | `ACS.paymentSuccess` | `payments.transactions.view_own` | FIN | N | UI, DL-S |
| FHC-PAY-011 | Payment failed | `/payments/failed` | L | `ACS.paymentFailed` | `payments.transactions.view_own` | FIN | N | UI, DL-S |
## Mission (14)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-MIS-001 | Mission dashboard | `/mission` | C | `MissionDashboardScreen` | `mission.dashboard.view` | INT | F13 | UI, DL-S |
| FHC-MIS-002 | Crusade detail | `/mission/crusade` | C | `CrusadeDetailScreen` | `mission.dashboard.view` | INT | E | UI, DL-S |
| FHC-MIS-003 | Invite a crusade | `/mission/invite` | C | `InviteCrusadeScreen` | — | PII | E | UI, DL-S |
| FHC-MIS-004 | Crusade request status | `/mission/request-status` | C | `CrusadeRequestStatusScreen` | — | PII | E | UI, DL-S |
| FHC-MIS-005 | Souls follow-up | `/mission/souls` | C | `SoulsFollowupScreen` | `mission.dashboard.view` | PII | F13 | UI, DL-S |
| FHC-MIS-006 | Add soul | `/mission/souls/add` | C | `AddSoulScreen` | `mission.souls.create` | PII | E | UI, DL-S |
| FHC-MIS-007 | Soul profile | `/mission/souls/profile` | C | `SoulProfileScreen` | `mission.souls.view` | PII | E | UI, DL-S |
| FHC-MIS-008 | Assign mentor | `/mission/mentor-assignment` | C | `AssignMentorScreen` | `mission.mentors.assign` | PII | E | UI, DL-S |
| FHC-MIS-009 | Mission teams | `/mission/teams` | C | `MissionTeamsScreen` | — | INT | E | UI, DL-S |
| FHC-MIS-010 | Mission support request | `/mission/support-request` | C | `MissionSupportRequestScreen` | `mission.support.request` | FIN | E | UI, DL-S |
| FHC-MIS-011 | Mission worker assignments | `/mission/assignments` | C | `MissionAssignmentsScreen` | `mission.assignments.view` | INT | E | UI, DL-S |
| FHC-MIS-012 | Mission partners | `/mission/partners` | C | `MissionPartnersScreen` | — | INT | E | UI, DL-S |
| FHC-MIS-013 | Mission partner detail | `/mission/partner` | C | `MissionPartnerDetailsScreen` | — | INT | E | UI, DL-S |
| FHC-MIS-014 | Support a mission | `/mission/support` | C | `SupportMissionScreen` | — | FIN | E | UI, DL-S |

## KCA (43)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-KCA-001 | KCA dashboard | `/kca` | C | `KcaDashboardScreen` | `kca.dashboard.view` | INT | F13 | UI, DL-S |
| FHC-KCA-002 | KCA entry gate | `/kca/gate` | C | `KcaEntryGate` | — | INT | F13 | UI, DL-S |
| FHC-KCA-003 | KCA enrolment landing | `/kca/enroll` | C | `KcaEnrollScreen` | — | PII | F13 | UI, DL-S |
| FHC-KCA-004 | KCA modules | `/kca/modules` | C | `KcaModulesScreen` | — | INT | F13 | UI, DL-S |
| FHC-KCA-005 | KCA module detail | `/kca/module` | C | `KcaModuleScreen` | — | INT | F13 | UI, DL-S |
| FHC-KCA-006 | KCA lesson | `/kca/lesson` | C | `KcaLessonScreen` | — | INT | F13 | UI, DL-S |
| FHC-KCA-007 | KCA assignments | `/kca/assignments` | C | `KcaAssignmentsScreen` | — | INT | F13 | UI, DL-S |
| FHC-KCA-008 | Mentor chat | `/kca/mentor` | C | `MentorChatScreen` | — | PII | F13 | UI, DL-S |
| FHC-KCA-009 | Evidence upload | `/kca/evidence` | C | `KcaEvidenceUploadScreen` | `kca.evidence.create` | PII | E | UI, DL-S |
| FHC-KCA-010 | Evidence submissions | `/kca/submissions` | C | `KcaSubmissionsScreen` | `kca.evidence.view_own` | PII | E | UI, DL-S |
| FHC-KCA-011 | Certification progress | `/kca/certification` | C | `KcaCertificationProgressScreen` | `kca.certification.view_own` | PII | E | UI, DL-S |
| FHC-KCA-012 | Admission status | `/kca/admission` | C | `KcaAdmissionStatusScreen` | `kca.admission.view_own` | PII | E | UI, DL-S |
| FHC-KCA-013 | KCA attendance | `/kca/attendance` | C | `KcaAttendanceScreen` | `kca.attendance.view` | PII | E | UI, DL-S |
| FHC-KCA-014 | Mentees | `/kca/mentees` | C | `KcaMenteesScreen` | `kca.mentoring.view` | PII | E | UI, DL-S |
| FHC-KCA-015 | Mentor evidence review | `/kca/review` | C | `KcaMentorReviewScreen` | `kca.evidence.review` | RST | E | UI, DL-S |
| FHC-KCA-016 | Final assessment | `/kca/assessment` | C | `KcaFinalAssessmentScreen` | `kca.assessment.view_own` | PII | E | UI, DL-S |
| FHC-KCA-017 | KCA certificate | `/kca/certificate` | C | `KcaCertificateScreen` | `kca.certificate.view_own` | PII | E | UI, DL-S |
| FHC-KCA-018 | Certificate verification | `/kca/verify` | C | `KcaCertificateVerifyScreen` | — | PUB | E | UI, DL-S |
| FHC-KCA-019 | Alumni directory | `/kca/alumni` | C | `KcaAlumniDirectoryScreen` | — | PII | E | UI, DL-S |
| FHC-KCA-020 | Alumni dashboard | `/kca/alumni/dashboard` | C | `KcaAlumniDirectoryScreen(dashboard: true)` | — | PII | E | UI, DL-S |
| FHC-KCA-021 | Alumni opportunities | `/kca/opportunities` | C | `KcaOpportunitiesScreen` | — | INT | E | UI, DL-S |
| FHC-KCA-022 | Enrolment — Church information | `/kca/enrollment/1` | L | `KLS.churchInfo` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-023 | Enrolment — Walk with Christ | `/kca/enrollment/2` | L | `KLS.walkWithChrist` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-024 | Enrolment — Why join | `/kca/enrollment/3` | L | `KLS.whyJoin` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-025 | Enrolment — Interests and skills | `/kca/enrollment/4` | L | `KLS.interests` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-026 | Enrolment — Commitments | `/kca/enrollment/5` | L | `KLS.commitments` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-027 | Enrolment — Personal commitment | `/kca/enrollment/6` | L | `KLS.personalCommitment` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-028 | Enrolment — Guardian consent | `/kca/enrollment/7` | L | `KLS.guardianConsent` | `kca.enrollment.create` | CHD | N | UI, DL-S |
| FHC-KCA-029 | Enrolment — Recommendation | `/kca/enrollment/8` | L | `KLS.recommendation` | `kca.enrollment.create` | PII | N | UI, DL-S |
| FHC-KCA-030 | Application review status | `/kca/application-review` | L | `KLS.applicationReview` | `kca.admission.view_own` | PII | N | UI, DL-S |
| FHC-KCA-031 | Admission letter | `/kca/admission-letter` | L | `KLS.admissionLetter` | `kca.admission.view_own` | PII | N | UI, DL-S |
| FHC-KCA-032 | Orientation | `/kca/orientation` | L | `KLS.orientation` | `kca.orientation.view` | INT | N | UI, DL-S |
| FHC-KCA-033 | Practical service | `/kca/practical-service` | L | `KLS.practicalService` | `kca.practical_service.manage` | INT | N | UI, DL-S |
| FHC-KCA-034 | Written assessments | `/kca/written-assessments` | L | `KLS.writtenAssessments` | `kca.assessments.view_own` | PII | N | UI, DL-S |
| FHC-KCA-035 | Spiritual assignment | `/kca/spiritual-assignment` | L | `KLS.spiritualAssignment` | `kca.assignments.view_own` | PII | N | UI, DL-S |
| FHC-KCA-036 | Student self-review | `/kca/self-review` | L | `KLS.selfReview` | `kca.reviews.create_own` | PII | N | UI, DL-S |
| FHC-KCA-037 | Administrator review | `/kca/admin-review` | L | `KLS.administratorReview` | `kca.reviews.manage` | RST | N | UI, DL-S |
| FHC-KCA-038 | Locked module | `/kca/locked-module` | L | `KLS.lockedModule` | `kca.modules.view` | INT | N | UI, DL-S |
| FHC-KCA-039 | Physical assignment | `/kca/physical-assignment` | L | `KLS.physicalAssignment` | `kca.assignments.create` | PII | N | UI, DL-S |
| FHC-KCA-040 | Mentor dashboard | `/kca/mentor-dashboard` | L | `KLS.mentorDashboard` | `kca.mentoring.view` | PII | N | UI, DL-S |
| FHC-KCA-041 | Lecturer workspace | `/kca/lecturer` | L | `KLS.lecturerWorkspace` | `kca.lessons.deliver` | RST | N | UI, DL-S |
| FHC-KCA-042 | Mentor intervention | `/kca/intervention` | L | `KLS.mentorIntervention` | `kca.mentoring.intervene` | RST | N | UI, DL-S |
| FHC-KCA-043 | Admission decision detail | `/kca/admission-decision` | L | `KLS.admissionDecision` | `kca.admission.manage` | RST | N | UI, DL-S |

## Press and downloads (6)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-PRS-001 | Press library | `/press` | C | `PressLibraryScreen` | — | PUB | E | UI, DL-S |
| FHC-PRS-002 | Press book | `/press/book` | C | `PressBookScreen` | — | PUB | F13 | UI, DL-S |
| FHC-PRS-003 | Press categories | `/press/categories` | C | `PressCategoriesScreen` | — | PUB | E | UI, DL-S |
| FHC-PRS-004 | Press resource detail | `/press/resource` | C | `PressResourceDetailScreen` | — | PUB | E | UI, DL-S |
| FHC-PRS-005 | Press audio player | `/press/audio` | C | `PressAudioPlayerScreen` | — | PUB | E | UI, DL-S |
| FHC-PRS-006 | Downloads/saved content | `/downloads` | C | `DownloadsScreen` | — | INT | E | UI, DL-S |

## Kingdom Journey (10)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-JRN-001 | Kingdom Journey overview | `/journey` | L | `KJS.overview` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-002 | Discover Family House | `/journey/discover` | L | `KJS.discover` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-003 | Join Church | `/journey/join-church` | L | `KJS.joinChurch` | `journey.manage_own` | PII | N | UI, DL-S |
| FHC-JRN-004 | Become a member | `/journey/member` | L | `KJS.member` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-005 | Grow spiritually | `/journey/grow` | L | `KJS.grow` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-006 | Serve | `/journey/serve` | L | `KJS.serve` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-007 | Win souls and disciple | `/journey/win-souls` | L | `KJS.winSouls` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-008 | Become KCA / mentor | `/journey/become-kca` | L | `KJS.becomeKca` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-009 | Start/develop Home Church | `/journey/home-church` | L | `KJS.homeChurch` | `journey.view_own` | PII | N | UI, DL-S |
| FHC-JRN-010 | Plant Church / multiply | `/journey/multiply` | L | `KJS.multiply` | `journey.view_own` | PII | N | UI, DL-S |

## Membership and leadership (19)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-LDR-001 | Leadership dashboard | `/leadership` | C | `LeadershipDashboardScreen` | `leadership.dashboard.view` | RST | E | UI, DL-S |
| FHC-LDR-002 | Membership registration | `/membership/register` | L | `LCS.membershipRegistration` | `membership.create` | PII | N | UI, DL-S |
| FHC-LDR-003 | First-timer registration | `/first-timer/register` | L | `LCS.firstTimerRegistration` | `church.first_timers.create` | PII | N | UI, DL-S |
| FHC-LDR-004 | First-timer journey | `/first-timer/journey` | L | `LCS.firstTimerJourney` | `church.followup.view` | PII | N | UI, DL-S |
| FHC-LDR-005 | Convert profile | `/convert/profile` | L | `LCS.convertProfile` | `mission.souls.view` | PII | N | UI, DL-S |
| FHC-LDR-006 | Disciple progress | `/disciple/progress` | L | `LCS.discipleProgress` | `discipleship.progress.view` | PII | N | UI, DL-S |
| FHC-LDR-007 | Member profile | `/member/profile` | L | `LCS.memberProfile` | `members.profile.view` | PII | N | UI, DL-S |
| FHC-LDR-008 | Ministry role profile | `/ministry/role` | L | `LCS.ministryRole` | `ministry.roles.view` | PII | N | UI, DL-S |
| FHC-LDR-009 | Ministry history | `/ministry/history` | L | `LCS.ministryHistory` | `ministry.history.view_own` | PII | N | UI, DL-S |
| FHC-LDR-010 | Evangelism activity | `/evangelism/activity` | L | `LCS.evangelismActivity` | `mission.activities.create` | INT | N | UI, DL-S |
| FHC-LDR-011 | Evangelism report | `/evangelism/report` | L | `LCS.evangelismReport` | `mission.reports.view` | RST | N | UI, DL-S |
| FHC-LDR-012 | Connect/referral to Church | `/referrals/connect` | L | `LCS.connectChurch` | `church.referrals.manage` | PII | N | UI, DL-S |
| FHC-LDR-013 | Referral tracking | `/referrals/tracking` | L | `LCS.referralTracking` | `church.referrals.view` | PII | N | UI, DL-S |
| FHC-LDR-014 | Approvals queue | `/leadership/approvals` | L | `LCS.approvalsQueue` | `leadership.approvals.view` | RST | N | UI, DL-S |
| FHC-LDR-015 | Approval detail | `/leadership/approval` | L | `LCS.approvalDetail` | `leadership.approvals.manage` | RST | N | UI, DL-S |
| FHC-LDR-016 | Leadership reports | `/leadership/reports` | L | `LCS.leadershipReports` | `leadership.reports.view` | RST | N | UI, DL-S |
| FHC-LDR-017 | Leadership alerts | `/leadership/alerts` | L | `LCS.alerts` | `leadership.alerts.view` | RST | N | UI, DL-S |
| FHC-LDR-018 | Leadership scope selector | `/leadership/scope` | L | `LCS.scopeSelector` | `leadership.scope.select` | RST | N | UI, DL-S |
| FHC-LDR-019 | Scope-aware leadership dashboard | `/leadership/scope-dashboard` | L | `LCS.scopeDashboard` | `leadership.dashboard.view` | RST | N | UI, DL-S |

## AI (6)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-AI-001 | AI assistant hub | `/ai` | L | `ACS.aiHub` | `ai.assistants.use` | PII | N | UI, DL-S |
| FHC-AI-002 | Pastoral AI assistant | `/ai/pastoral` | L | `ACS.pastoralAssistant` | `ai.pastoral.use` | RST | N | UI, DL-S |
| FHC-AI-003 | Mission AI assistant | `/ai/mission` | L | `LCS.missionAi` | `ai.mission.use` | RST | N | UI, DL-S |
| FHC-AI-004 | KCA AI study assistant | `/ai/kca` | L | `LCS.kcaAi` | `ai.kca.use` | PII | N | UI, DL-S |
| FHC-AI-005 | Press AI assistant | `/ai/press` | L | `LCS.pressAi` | `ai.press.use` | INT | N | UI, DL-S |
| FHC-AI-006 | Pastoral AI reports | `/ai/pastoral-reports` | L | `LCS.pastoralReports` | `ai.pastoral.reports` | RST | N | UI, DL-S |

## Map and global expansion (5)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-MAP-001 | Global Family House map | `/map` | L | `LCS.globalMap` | — | PUB | N | UI, DL-S |
| FHC-MAP-002 | Map filters | `/map/filter` | L | `LCS.mapFilter` | — | PUB | N | UI, DL-S |
| FHC-MAP-003 | Mission location detail | `/map/mission-location` | L | `LCS.missionLocation` | — | INT | N | UI, DL-S |
| FHC-MAP-004 | No Church nearby | `/map/no-church` | L | `LCS.noChurchNearby` | — | PUB | N | UI, DL-S |
| FHC-MAP-005 | Global expansion journey | `/global-expansion` | L | `LCS.globalExpansion` | — | PUB | N | UI, DL-S |

## Account privacy, guardian and safeguarding (13)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-ACC-001 | Notification preferences | `/settings/notifications` | L | `ACS.notificationPreferences` | `settings.notifications.manage` | PII | N | UI, DL-S |
| FHC-ACC-002 | Communication preferences | `/settings/communications` | L | `ACS.communicationPreferences` | `settings.communications.manage` | PII | N | UI, DL-S |
| FHC-ACC-003 | Active sessions | `/settings/sessions` | L | `ACS.activeSessions` | `security.sessions.manage` | PII | N | UI, DL-S |
| FHC-ACC-004 | Privacy controls | `/settings/privacy` | L | `ACS.privacy` | `privacy.manage_own` | PII | N | UI, DL-S |
| FHC-ACC-005 | Consent management | `/settings/consents` | L | `ACS.consents` | `consents.manage_own` | PII | N | UI, DL-S |
| FHC-ACC-006 | Data export | `/settings/data-export` | L | `ACS.dataExport` | `privacy.export_own` | PII | N | UI, DL-S |
| FHC-ACC-007 | Account deletion | `/settings/delete-account` | L | `ACS.accountDeletion` | `privacy.delete_own` | PII | N | UI, DL-S |
| FHC-ACC-008 | Child profile | `/guardian/child` | L | `ACS.childProfile` | `guardian.child.view` | CHD | N | UI, DL-S |
| FHC-ACC-009 | Guardian controls | `/guardian/controls` | L | `ACS.guardianControls` | `guardian.controls.manage` | CHD | N | UI, DL-S |
| FHC-ACC-010 | Guardian consent | `/guardian/consent` | L | `ACS.guardianConsent` | `guardian.consent.manage` | CHD | N | UI, DL-S |
| FHC-ACC-011 | Restricted child communication | `/guardian/restricted` | L | `ACS.restrictedCommunication` | `guardian.communication.view` | CHD | N | UI, DL-S |
| FHC-ACC-012 | Safeguarding report | `/safeguarding/report` | L | `ACS.safeguardingReport` | `safeguarding.reports.create` | RST | N | UI, DL-S |
| FHC-ACC-013 | Restricted pastoral record | `/pastoral/record` | L | `ACS.pastoralRecord` | `pastoral.records.view` | RST | N | UI, DL-S |

## Offline, sync and recovery (8)

| ID | Canonical screen | Path | N | Implementation | Gate | Class | Ref | Flags |
|---|---|---|---|---|---|---|---|---|
| FHC-OPS-001 | Offline mode | `/offline` | L | `OSS.offline` | — | INT | O | UI, DL-S, OF |
| FHC-OPS-002 | Sync pending | `/sync/pending` | L | `OSS.syncPending` | `sync.queue.view_own` | PII | O | UI, DL-S, OF |
| FHC-OPS-003 | Sync successful | `/sync/success` | L | `OSS.syncSuccessful` | `sync.queue.view_own` | PII | O | UI, DL-S, OF |
| FHC-OPS-004 | Upload progress | `/uploads/progress` | L | `OSS.uploadProgress` | `uploads.view_own` | PII | O | UI, DL-S, OF |
| FHC-OPS-005 | Upload failed/retry | `/uploads/failed` | L | `OSS.uploadFailed` | `uploads.retry_own` | PII | O | UI, DL-S, OF |
| FHC-OPS-006 | Low-bandwidth media mode | `/settings/low-bandwidth` | L | `OSS.lowBandwidth` | — | INT | O | UI, DL-S, OF |
| FHC-OPS-007 | Content unavailable | `/content/unavailable` | L | `OSS.contentUnavailable` | — | PUB | O | UI, DL-S, OF |
| FHC-OPS-008 | Downloads/storage management | `/downloads/storage` | L | `OSS.storage` | `downloads.manage_own` | INT | O | UI, DL-S, OF |

## Aliases (not canonical screens)

| Alias path | Canonical screen ID | Canonical path | Reason |
|---|---|---|---|
| `/churches` | FHC-FND-012 | `/discover` | Same `FindChurchesScreen` switch branch |
| `/church/directory` | FHC-CHU-005 | `/church/members` | Same `MembersListScreen`; no configuration difference |
| `/first-timers` | FHC-CHU-012 | `/church/first-timers` | Same permission and `FirstTimersScreen` branch |
| `/press/publication` | FHC-PRS-004 | `/press/resource` | Same `PressResourceDetailScreen` branch |

## Registry gaps and non-claims

1. **API-UNBOUND:** No Laravel/OpenAPI contract, feature repositories, remote
   data sources, base URL, token flow, or test identities are present. Screen
   data and apparent workflow outcomes must be treated as visual prototypes.
2. **ROLE/REQUIREMENTS GAP:** No `PERMISSION_MATRIX.md`, domain model, workflow
   catalogue, security model, or data-classification source exists in this
   workspace. The classifications above are conservative implementation-audit
   labels, not approved policy.
3. **SCOPE GAP:** All permission guards omit organization and resource scope.
4. **DEEP-LINK GAP:** Routes are static; entity-detail destinations do not
   carry IDs. A notification or external link cannot identify a particular
   Church, event, payment, soul, KCA record, publication, or conversation.
5. **AUTH GAP:** Open routes include screens that appear to contain internal or
   personal data. Flutter visibility is not security, but the missing guard is
   still a navigation/UX authorization gap.
6. **ROUTE-NAME GAP:** 106 of the 212 registered paths are not represented by a
   `FhcRoutes` constant. Raw literals increase drift risk.
7. **NOTIFICATION GAP:** Only `/messages`, `/events`, `/sermons`, `/prayer`, and
   `/groups` are current hard-coded notification targets.
8. **OFFLINE GAP:** The eight offline/sync views are implemented, but there is
   no outbox, persistence, background-upload, retry, or reconciliation data
   layer in the source tree.
