# Family House Application — Cursor Master Implementation Prompt

## Your Role

Act as the lead senior Flutter, Laravel API, database, security, QA, and integration engineer for the **Family House** application. You are working inside the existing repository and must **implement, integrate, test, and verify** the requirements below—not merely describe them, produce a plan, generate sample code, or leave recommendations.

The screenshots attached to this prompt are part of the requirements. Inspect every screenshot carefully and use the existing design system, routes, components, navigation patterns, spacing, colours, typography, and user journeys. Preserve working functionality and improve confusing navigation without unnecessarily redesigning approved screens.

## Demo Accounts

Use these accounts for role-based testing in the development/demo environment only:

| Role | Email | Password |
|---|---|---|
| Platform administrator | `admin@familyhouse.demo` | `DemoPass!2026` |
| Church operations / pastor | `pastor@familyhouse.demo` | `DemoPass!2026` |
| Member / KCA student | `member@familyhouse.demo` | `DemoPass!2026` |

Never hard-code these credentials into production application code, commits, mobile binaries, logs, fixtures used in production, or UI source. If accounts or permissions are missing locally, create/update development seeders or factories and document how to run them.

---

## Non-Negotiable Outcome

Unlock every feature the authenticated user is authorised to access, replace all mock/placeholder/hard-coded runtime data in the affected modules with live API-backed data, fix authentication persistence and token refresh, and make navigation complete, predictable, and seamless.

**Zero tolerance for mock data in completed runtime features.** A screen is not complete merely because it renders. It is complete only when its list, detail, create/update action, status, empty state, error state, loading state, permissions, and navigation are connected to the real backend and verified.

If an API, database table, policy, service, job, event, notification, upload facility, or route required by the UI does not exist, implement it in the Laravel backend, including validation, authorization, migrations, models, resources, services/actions, controllers, routes, tests, and API documentation. Do not silently hide the feature or populate it with fake data.

Do not skip an item because it is large, because an endpoint is absent, or because the current implementation is incomplete. Do not mark anything complete using comments such as `TODO`, `FIXME`, “coming soon,” placeholder cards, static lists, fake delays, local sample JSON, dummy repositories, fallback mock objects, or hard-coded success responses.

---

## Mandatory Working Method

### 1. Inspect before editing

First inspect the entire relevant repository and determine:

- Flutter architecture, state management, routing, dependency injection, API client, secure storage, models, repositories, feature modules, and current tests.
- Laravel version, authentication system, API versioning, middleware, policies/permissions, database schema, storage configuration, queues, events, resources, tests, and API conventions.
- Existing environment/configuration files and repository instructions such as `AGENTS.md`, README files, contribution rules, linting, formatting, and test commands.
- Every attached screenshot and the exact page, route, role, control, or failure it represents.
- Existing API endpoints before creating duplicates.

Do not assume package names or architecture. Follow the established project structure unless a change is required to correct a demonstrable problem.

### 2. Build a traceability ledger

Create or update `IMPLEMENTATION_STATUS.md` at the repository root. Add one row for every requirement and every affected screen/action with these columns:

| ID | Requirement / Screen | Flutter Route | UI Action | API Endpoint | Backend Files | Permission | Tests | Status | Evidence |
|---|---|---|---|---|---|---|---|---|---|

Allowed statuses: `Not Started`, `In Progress`, `Blocked`, `Verified`. Only use `Verified` when the end-to-end acceptance checks pass. Record real filenames, endpoint methods/paths, test names, and verification evidence. If blocked by missing information or infrastructure, state the precise blocker and continue with every unblocked item.

### 3. Search for incomplete implementations

Search the affected code for mock data, placeholders, dummy data, static collections, hard-coded profile values, fake repositories, unfinished callbacks, disabled buttons, empty `onTap`/`onPressed`, TODO/FIXME markers, “coming soon,” hard-coded access-denied states, local JSON fixtures used at runtime, swallowed exceptions, and routes that lead nowhere. Replace or finish each occurrence within this scope.

### 4. Implement vertical slices

Complete each feature end to end: schema → model → business logic → authorization → API → Flutter data layer → state handling → UI interaction → navigation → tests. Do not build all UI first and postpone integration.

### 5. Do not stop at planning

After the audit, immediately begin implementation. Continue through all requirements in this prompt. Do not return a plan as the final output. Do not claim that something is outside scope merely because the backend or endpoint is missing; create what is required within the repository.

---

## Global Engineering Rules

### Live-data rules

- All affected screens must obtain runtime content from the live Laravel API.
- Use typed request/response models and the existing repository/service abstraction.
- Never silently replace an API failure with demo content. Show an accurate retryable error state.
- Provide purposeful loading, empty, offline, validation, success, and error states.
- Support pagination, refresh, search, filters, sorting, and debouncing where appropriate.
- Prevent duplicate submissions and duplicate registrations with both UI guards and server-side idempotency/uniqueness rules.
- Refresh affected queries after successful create/update/join/register actions.
- Ensure API resources return consistent envelopes, pagination metadata, validation errors, and machine-readable error codes according to existing conventions.

### Security and authorization rules

- Enforce permissions on the Laravel server; never rely only on hiding UI controls.
- Flutter route guards and visible actions must reflect server capabilities/permissions.
- A `403` must mean genuinely forbidden, not unauthenticated, expired token, missing profile data, or failed client hydration.
- A `401` must trigger the controlled refresh flow where eligible, not immediately force sign-in.
- Do not expose admin upload/edit/delete actions to members.
- Validate uploads by MIME type, extension, size, storage visibility, and authorization; use safe filenames and signed/private URLs when appropriate.
- Do not log tokens, passwords, sensitive profiles, private conversations, or uploaded private documents.

### Navigation and accessibility rules

- Every visible button, card, icon, tab, menu item, CTA, notification, and deep link must have a working destination or action.
- Back navigation must return users to a logical prior state without losing successfully submitted data.
- Preserve selected tab and relevant list/filter state where expected.
- Use clear text labels, accessible semantics, adequate contrast, readable touch targets, keyboard-safe forms, and meaningful screen-reader labels.
- Do not create duplicate screens when an existing canonical route can be repaired.

### Testing rules

- Add/update Laravel feature and unit tests for endpoints, validation, role policies, state transitions, uploads, idempotency, and unauthorised access.
- Add/update Flutter unit, repository, state, widget, navigation, and integration tests for the critical flows below.
- Test with all three demo roles.
- Test success, loading, empty, validation, expired-token, refresh-failure, forbidden, network-failure, retry, and duplicate-submission cases.
- Run formatter, static analysis, relevant unit/feature/widget/integration tests, and builds supported by the repository.
- Fix failures introduced by the work. Do not delete, skip, weaken, or rewrite valid tests merely to obtain a green result.

---

## Required Implementations

## R1 — Connect the Entire Church Module

Trace the “church modules are not connected” failure shown in the first screenshot. Repair all routes, dependency injection, repositories, permissions, and endpoints across the Church area.

At minimum, verify and connect every Church screen present in the current UI, including applicable journeys such as church discovery/details, my church, membership, first-timer/member status, leaders/pastors, departments or ministries, groups, services, attendance, announcements, prayer/needs/testimonies, contact/directions, joining, and related detail screens.

Requirements:

- Church cards and dashboard shortcuts open the correct real screens.
- Lists and details use API IDs rather than array indexes or hard-coded IDs.
- The active user’s church relationship and membership status come from the API.
- Actions such as join/request/contact/register display the authoritative server state after completion.
- Role boundaries are respected: members see member functions; pastors see authorised church-operation functions; platform admins see platform-authorised functions.
- Empty church data produces a useful empty state and discovery CTA, not a false error.

## R2 — Fix False “Sign-in Required” Errors

The application currently displays “Sign-in Required” while the user is already authenticated. Trace the root cause across session restoration, startup timing, route guards, state providers, secure storage, API interceptors, role/profile hydration, and backend middleware.

Implement:

- A single authoritative authentication/session state.
- A startup/auth-hydration state so protected screens wait for session restoration instead of treating “not loaded yet” as signed out.
- Correct separation of unauthenticated, refreshing, authenticated, forbidden, offline, and server-error states.
- Safe session restoration after app restart/background-resume.
- A redirect that preserves the intended destination only when a genuine login is required.
- No sign-in redirect after a successful authenticated form submission.

Add a regression test that launches/restores an authenticated session, directly opens each affected protected route, and confirms no false sign-in page appears.

## R3 — Media Home Uses Real APIs

Connect every section, module, tab, carousel, category, search/filter, card, and CTA on the Media screen to live API data. If required endpoints do not exist, create them.

Support the media types and screens represented in the app, including Books, Sermons, Devotionals, Live Services, Watch, and Listen. Use server-provided media IDs, titles, descriptions, thumbnails/covers, speakers/authors, publication dates, durations, media types, playback/download URLs, availability, and pagination.

Remove runtime mock media and create correct loading, empty, error, retry, pagination, pull-to-refresh, and offline-aware states.

## R4 — Watch and Listen Screens Use Real APIs

Implement the Watch and Listen screenshots as fully API-backed experiences:

- Real lists, categories, search, filters, details, related content, and playback sources.
- Audio/video player lifecycle: initialise, play, pause, seek, progress, duration, buffering, failure, retry, background/interruption handling where supported, and cleanup on disposal.
- Live-service state: scheduled, upcoming, live now, ended, replay available, or unavailable.
- Do not label content live based on hard-coded UI state.
- Secure or expiring media URLs must be refreshed correctly.
- Persist legitimate playback progress/history through the API if the current product design includes it.
- Analytics/events must not block playback and must avoid duplicate view/listen counts.

## R5 — Mission Access, Tabs, and Screens

Fix the incorrect “Access Denied” state for ordinary authenticated members. A member must not be denied merely because their role is `member`. Members may discover, view, participate in, register interest in, support, follow, or otherwise use the member-facing mission experiences provided by the app. Mission creation, sensitive soul/follow-up records, assignments, reports, and administration remain restricted to explicitly authorised pastor/mission/admin roles.

Connect every existing Mission tab and its child screens to real routes and APIs. Verify tab switching, deep linking, refresh, search/filter, list/detail navigation, registration/support actions, status tracking, and appropriate empty/error states. Implement missing member-facing screens or APIs required by the attached designs. Ensure server policies and frontend guards express the same permission matrix.

## R6 — KCA Enrolment and Admission Lifecycle

Make KCA enrolment a real, resumable, API-driven multi-step process. The user completes one valid step at a time before advancing.

Implement:

- Load the enrolment definition/options from the API where values are configurable.
- Render and enforce required versus optional fields accurately.
- Validate each step client-side for usability and server-side for authority.
- Save a draft after each step or at safe checkpoints, restore it across app restart/session refresh, and show save/sync state.
- Do not discard earlier steps when navigating back.
- Support conditional fields, document/evidence uploads, consent, leadership recommendation, and guardian consent where applicable to the existing enrolment design.
- Display server validation errors beside the correct fields.
- Final review and explicit submission to the live API.
- Idempotent final submission so taps/retries cannot create duplicate applications.
- After success, update local authenticated/profile/application state without forcing sign-in.
- Show a real confirmation/reference and route to Admission Tracking.
- Admission tracking must show authoritative states and history such as draft, submitted, under review, more information required, provisionally accepted, admitted/activated, deferred, or not accepted, according to backend rules.
- When activated/admitted, the KCA module becomes available based on API capabilities/permissions without reinstalling or re-signing in.

Do not simulate admission progress with timers or hard-coded statuses.

## R7 — Correct and Complete Bottom Navigation

Audit the actual information architecture and correct the bottom navigation labels/icons/routes. The current mismatches include:

- A discover-style icon incorrectly labelled **Give**.
- A chart-style icon incorrectly labelled **Events**.

Choose labels that match the actual destination and approved app information architecture. Make all intended primary destinations visible and accessible without overcrowding. If there are more destinations than the bottom bar can clearly support, use a properly labelled **More** destination/menu with accessible entries; do not silently remove existing modules.

Requirements:

- Each icon, label, selected state, tooltip/semantic label, and route agrees.
- Selected state follows nested routes correctly.
- Tabs do not create duplicate navigation stacks on repeated taps.
- Back behaviour is predictable.
- Role/capability-based visibility is driven by the authenticated API profile, not hard-coded email checks.
- Deep links and post-login redirects land in the correct tab.

## R8 — KCA Global Community, Follow, Search, and Chat

An admitted/activated KCA student must be able to discover other visible KCAs across countries, states/regions, and LGAs/local areas, subject to privacy and safeguarding rules.

Implement live APIs and screens for:

- KCA directory with pagination.
- Search by permitted fields.
- Country, state/region, and LGA/local-area filters populated from canonical geography APIs.
- Public-safe KCA profile details.
- Follow/unfollow with idempotent endpoints and accurate counts/states.
- Following/followers lists if represented in the design.
- One-to-one chat with conversation list, message history pagination, sending, delivery state, unread counts, retry, and real-time updates using the project’s supported broadcasting mechanism; use safe polling only if the repository has no real-time infrastructure and document the decision.
- Block/report/mute and appropriate safeguarding controls where users can contact each other.
- Privacy settings and server-side enforcement of profile visibility and messaging permissions.

Do not expose private enrolment data, contact data, guardian/child data, pastoral records, or location precision beyond the approved public-safe profile fields.

## R9 — Access-Token Refresh and Session Reliability

Fix the token-refresh defect that logs users out prematurely.

Implement the correct pattern for the authentication system already used by the backend:

- Store tokens/session secrets only in the project’s secure storage mechanism.
- Restore the session before evaluating protected routes.
- Refresh before/when access tokens expire according to server semantics.
- On an eligible `401`, perform a **single-flight refresh** so simultaneous failing requests trigger only one refresh operation.
- Queue eligible failed requests and replay each once after a successful refresh.
- Prevent refresh recursion and infinite request loops.
- Rotate and persist new tokens atomically if the server rotates refresh tokens.
- Distinguish authentication failure from `403`, validation, offline, timeout, and server errors.
- Clear the session and request sign-in only when refresh is definitively invalid/expired/revoked—not on temporary connectivity or server failure.
- Handle logout, revoked sessions, app restart, background resume, clock skew, and concurrent requests safely.
- Ensure refresh endpoints and middleware are covered by Laravel tests and client concurrency/regression tests.

Never print tokens in logs or expose them in crash reports.

## R10 — Complete Event Registration and “My Events”

Opening an event must lead through a clear API-backed detail and registration journey.

Implement:

- Events list with upcoming/current/past states from API dates and status.
- Event detail, eligibility/capacity, schedule/location or online access, registration fields, validation, consent/payment when applicable, review, and submit.
- Server-side capacity, deadline, eligibility, duplicate-registration, and idempotency enforcement.
- After successful registration, create an attendee record and return a unique attendee code plus a valid QR code payload.
- Show a registration confirmation/ticket screen containing event details, attendee details, status, attendee code, and scannable QR code.
- QR content must use an opaque, verifiable attendee token/reference and must not unnecessarily expose personal information.
- Add wallet/download/share only if consistent with the existing design and security policy.
- **My Events** must show the authenticated user’s registered upcoming/current events from the API.
- Past Events must use API history, not mock entries.
- Event detail must reflect registration/cancellation/check-in status accurately.
- Refresh My Events immediately after registration without requiring sign-in.
- If organiser check-in already exists, ensure the QR/code can be verified exactly once or according to documented re-entry rules.

## R11 — Replace Profile Mock Data and Repair Profile Navigation

Audit the Profile screen and every linked setting/detail screen. Replace placeholder values, sample counters, fake avatars, static church/KCA status, hard-coded contact details, and dummy history with authenticated API data.

Connect the full profile journey represented in the application, including applicable personal data, avatar, contact information, location, church/membership, KCA status, ministries/groups, activity/history, notification preferences, privacy, security, password/MFA, active sessions, downloads, help/support, and logout.

Implement safe edit/update flows with validation, optimistic updates only where safe, rollback/error handling, avatar upload, refresh, and consistent cached profile invalidation. Sensitive changes must follow the backend’s verification/security policy. Missing optional values should show a clean empty state or prompt, never invented content.

## R12 — Press Administration, Publications, Downloads, Sermons, and Live Services

Platform admins and properly authorised Press users must be able to create metadata and upload/manage:

- Books.
- Documents/publications.
- Sermons (audio and/or video as supported).
- Devotionals.
- Live-service records/streams and replays.

Implement or finish the Laravel schema, endpoints, validation, policies, storage, file metadata, publishing workflow/status, upload progress, failure/retry, edit, archive/unpublish, and listing/detail resources required by the current application.

Member-facing requirements:

- Published content appears in the correct Media/Press/Watch/Listen sections through live APIs.
- Books/documents authorised for download can be downloaded reliably with progress, storage permission handling, retry, filename/content-type integrity, and access control.
- Sermons play in the correct audio/video experience.
- Live services display actual schedule/live state and can be watched through valid stream URLs.
- Draft, rejected, scheduled, archived, expired, or unauthorised content must not leak into public/member lists.
- Deleting/unpublishing content must not leave broken cards or stale cached entries.

Use background/object storage patterns already established by the project. Do not store large media blobs directly in database columns.

## R13 — Group and Ministry Joining

Make group and ministry discovery and joining completely functional and API-driven.

Implement:

- Available group/ministry lists and details.
- Search/filter where present.
- Eligibility, scope/church, capacity, joining rules, approval requirements, and membership state from the API.
- Join/request-to-join with validation and idempotency.
- Leave/cancel-request actions where allowed.
- Pending, approved/joined, rejected, suspended, or left states according to backend rules.
- **My Groups** and **My Ministries** populated from authenticated API relationships.
- Immediate state refresh after joining/leaving without sign-in.
- Clear CTA labels reflecting the current state: Join, Request to Join, Pending, Joined, Leave, Reapply, or unavailable reason.
- Appropriate notifications to the applicant and authorised approvers if the project includes notifications.
- Admin/pastor approval APIs and screens where approval is required by existing business rules.

Prevent duplicate memberships and enforce tenant/church/scope boundaries on the server.

---

## Required API and Data Contract Review

For every affected feature, document the real endpoint in `IMPLEMENTATION_STATUS.md`. Use existing API conventions and versioning. At minimum, ensure the backend supports the domain capabilities below; endpoint names may adapt to the repository’s existing conventions:

| Domain | Minimum capability |
|---|---|
| Authentication | Login, authenticated user/capabilities, refresh, logout/revoke, sessions |
| Church | Discover/list, detail, my church/membership, join/request, related modules |
| Media/Press | Published catalogue, categories/types, details, search/filter, download/playback URLs, admin CRUD/upload/publish |
| Watch/Listen/Live | Lists, detail, streams/sources, live status, progress/history if supported |
| Mission | Member-facing list/detail/participation/support/status; restricted admin operations |
| KCA enrolment | Definition/options, draft create/read/update, step validation, uploads, submit, admission tracking |
| KCA community | Directory/search/geography filters, safe profile, follow/unfollow, privacy, block/report |
| Chat | Conversations, messages, send, read/unread, delivery/update channel, block/report enforcement |
| Events | List/detail, registration, attendee ticket/code/QR, My Events, past events, status/check-in |
| Profile | Read/update, avatar, relationships/status, preferences, security/session links |
| Groups/ministries | Discover/detail, join/request/leave, My Groups/My Ministries, approval/status |

Do not create a second conflicting API when a correct endpoint already exists. Repair and extend existing resources when appropriate. Add database indexes, foreign keys, uniqueness constraints, and transaction boundaries needed for integrity and performance.

---

## Mandatory End-to-End Acceptance Journeys

These journeys must be executed and recorded as evidence before completion:

### Journey A — Member authentication persistence

1. Sign in as `member@familyhouse.demo`.
2. Close/restart or simulate a cold start.
3. Open protected Church, Media, Mission, Event, KCA, Group, and Profile routes.
4. Confirm there is no false “Sign-in Required.”
5. Force access-token expiry with a valid refresh session.
6. Trigger simultaneous API calls and confirm exactly one refresh occurs, requests recover, and the user stays signed in.

### Journey B — Church and participation

1. Open Church from all relevant entry points.
2. View live church data and details.
3. Join/request or view current membership state as applicable.
4. Open groups/ministries, join one, and confirm it appears in My Groups/My Ministries.
5. Restart the app and confirm the server state persists.

### Journey C — Media and Press

1. Sign in as an authorised administrator.
2. Upload and publish a test book/document, sermon, devotional, and live/replay entry through real APIs.
3. Sign in as a member.
4. Confirm each published item appears in the correct section.
5. Download the authorised document, play the sermon, and open/watch the live or replay source.
6. Unpublish one item and verify it no longer appears to the member after refresh.

### Journey D — Mission

1. Sign in as a member and open Mission without access denial.
2. Open every Mission tab and at least one list/detail/action flow.
3. Confirm restricted administrative actions remain forbidden to the member.
4. Confirm the pastor/admin can access only the operations granted to their permissions.

### Journey E — KCA enrolment to activation

1. Start enrolment as the member.
2. Verify required fields block advancement and optional fields do not.
3. Complete steps, go backward/forward, restart, and restore the saved draft.
4. Submit once to the live API; repeat the network request and confirm no duplicate application.
5. Confirm no sign-in prompt appears.
6. Track the real admission state.
7. Activate/admit through an authorised workflow or fixture and verify KCA access updates.
8. Search/filter KCAs, follow one, start a conversation, send a message, and verify persistence/update.

### Journey F — Event registration

1. Open a live API event.
2. Complete registration and submit once.
3. Receive a unique attendee code and scannable QR ticket.
4. Confirm the event immediately appears in My Events.
5. Confirm past API events appear in Past Events.
6. Retry the registration request and confirm no duplicate attendee record is created.

### Journey G — Profile

1. Load the profile and verify every displayed value is returned by the API or is an honest empty state.
2. Edit an allowed field/avatar and confirm the API, UI, and subsequent app restart show the update.
3. Open every visible Profile menu item and confirm it routes to a functional screen.

---

## Definition of Done

The task is complete only when all of the following are true:

- Every R1–R13 ledger entry is `Verified` or has a genuine external blocker explicitly documented.
- No in-scope screen uses runtime mock, placeholder, dummy, or hard-coded domain data.
- No visible in-scope button/tab/card/menu has an empty handler, dead route, placeholder screen, or incorrect permission outcome.
- Authentication survives normal expiry, refresh, cold start, and concurrent requests.
- Member, pastor, and administrator permissions are tested on both client and server.
- New/changed endpoints have validation, authorization, resources, migrations where needed, and automated tests.
- Flutter has correct loading, empty, error, retry, success, and offline handling.
- All mandatory acceptance journeys pass.
- Formatting, linting/static analysis, automated tests, and supported builds pass, or unrelated pre-existing failures are precisely separated with evidence.
- API documentation and setup/seed instructions are updated.
- `IMPLEMENTATION_STATUS.md` contains real traceability evidence.

Do not declare completion based only on compilation, screenshots, successful HTTP `200` responses, or manually navigating one happy path.

---

## Final Response Required from Cursor

When—and only when—the implementation and verification are complete, report:

1. What was implemented for each R1–R13.
2. Root causes found, especially false sign-in, token refresh, and mission access.
3. Files, migrations, endpoints, routes, policies, and tests added or changed.
4. Test/analysis/build commands run and their exact results.
5. The completed acceptance-journey results for all demo roles.
6. Remaining genuine blockers, if any, including why they could not be resolved from the repository.
7. Any required environment variables, storage/queue/broadcast setup, or migration/seeding commands—without exposing secrets.

Do not use vague completion claims such as “all connected,” “mostly complete,” or “should work.” Provide verifiable evidence tied to the ledger and tests.

