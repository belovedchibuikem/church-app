# Family House Connect Mobile UI Gaps

Audit date: 2026-08-26

## Scope

This audit compares the completion brief with implemented routes and visible
interaction code. It does not redesign approved screens. A row means either a
required destination/state has no canonical UI or an existing screen contains
an interaction whose required destination/action contract is absent.

The initial audit found 41 explicit empty callbacks. Post-remediation static
search now finds zero: implied actions use canonical routes or the shared
integration-required state. Remaining rows describe missing backend/native
capabilities or fixture-only behavior, not silent empty callbacks.

## Missing or incomplete canonical UI

| PRIORITY | REQUIREMENT | DOMAIN | ORIGINATING SCREEN | REQUIRED DESTINATION | WHY NECESSARY | ROLE | PROPOSED SCREEN ID | PRESENTATION | CURRENT EVIDENCE / STATUS |
|---|---|---|---|---|---|---|---|---|---|
| Critical | Complete new-user flow | Identity | Sign In | Registration, email verification, recovery, profile setup, church affiliation | Brief requires full Splash-to-Home onboarding | Visitor | `AUTH_REGISTER`, `AUTH_VERIFY_EMAIL`, `AUTH_RECOVERY`, `PROFILE_SETUP`, `CHURCH_AFFILIATION` | Full routes | Routes absent; Create Account, Forgot Password, Google and Apple callbacks are empty |
| Critical | Restore authenticated destination | Identity/navigation | Any protected deep link | Login/MFA then intended destination | Prevents lost context and unauthorized display | All | `AUTH_INTENDED_DESTINATION_GATE` | Router state, not a new visual redesign | No auth redirect/session restoration architecture |
| Critical | Typed entity detail | Cross-domain | Church/event/crusade/KCA/Press/payment/message lists | Parameterized detail routes | Static sample details cannot represent selected records | Varies | Existing detail IDs with `:id` | Full routes using existing design | Current detail routes carry no entity IDs and render fixed data |
| Critical | Permission-specific denial | Security | Protected resource deep link | Restricted state with safe navigation | Must handle 403 without exposing record existence | All | `RESTRICTED_ACCESS` | Reusable full-page state | State exists, but guards receive permission only; no resource/scope and default gateway allows all |
| Critical | Authoritative loading/error/empty/offline states | All data domains | Every data screen | Typed state variants and retry | Hard-coded loaded state cannot consume APIs safely | All | Reuse `FhcLoading`, `FhcError`, `FhcEmpty`, `FhcOffline` patterns | Inline/state page | Only a few screens have local empty/restricted visuals; no shared data-state controller |
| Critical | Real payment lifecycle | Finance | Give/Event Payment/Payment Processing | Pending, server-confirmed success/failure, receipt | Must not fake financial success | Member | Existing payment state screens, driven by payment ID | Full routes | Screens are static; no payment API/repository/reconciliation |
| Critical | Durable sync conflict resolution | Offline | Sync Pending | Conflict/detail/retry per outbox item | Server validation can reject or conflict | Authorized offline user | `SYNC_ITEM_DETAIL`, `SYNC_CONFLICT_RESOLUTION` | Full route or large sheet | Sync Now only shows a snackbar; success screen is directly route-addressable |
| Critical | Upload source/validation/status detail | Uploads | Evidence upload and failed upload | File picker, validation, per-upload detail, cancel/pause/resume/retry | Required upload workflow cannot be represented by navigation alone | Authorized contributor | `UPLOAD_PICKER`, `UPLOAD_ITEM_DETAIL` | Native picker + large sheet/full route | No picker/plugin/store/API; retry routes directly to static progress |
| High | Download progress/open/remove | Press/KCA/offline | Publication and Downloads | Per-asset progress, open, remove, storage confirmation | Required offline content lifecycle | Entitled user | `DOWNLOAD_ITEM_DETAIL` | Bottom sheet/full route/dialog | Download icons/callbacks are empty or static; no file persistence |
| High | Notification typed destination | Communications | Notifications | Resource-specific destination or unavailable/restricted | Generic route cannot open the referenced record | Authenticated user | `NOTIFICATION_RESOLVER` | Router resolver | Rows use hard-coded in-memory generic routes; no notification ID |
| High | Conversation detail | Messaging | Messages inbox | `/messages/:conversationId` | One static mentor chat cannot serve all threads | Participant | `CONVERSATION_DETAIL` | Full route | One inbox row has no route; other group rows route to generic Groups |
| High | Church join/contact action | Church discovery | Church Detail | Join/follow/contact/call/directions/website actions and states | Primary discovery workflow is incomplete | Visitor/member | `CHURCH_CONTACT_ACTIONS` | Bottom sheet/external intent/dialog as appropriate | Follow and contact/action callbacks include empty handlers |
| High | Group membership action | Community | Groups / Church Groups | Join/request/leave and result state | Join buttons currently have no action | Member | `GROUP_MEMBERSHIP_ACTION` | Confirmation/dialog or sheet | Empty group join callbacks found |
| High | Member record add/detail/edit | Church/Home Church | Members Directory | Add member form and member detail | Leader directory workflow cannot complete | Leader | `MEMBER_CREATE`, `MEMBER_DETAIL` | Full route or large sheet | Add Member and row action callbacks are empty |
| High | Ministry detail/create/join | Church | Ministries | Ministry detail and membership/request action | List implies navigation/action | Member/leader | `MINISTRY_DETAIL`, `MINISTRY_MEMBERSHIP_ACTION` | Full route + dialog | Empty callbacks found in ministries screen |
| High | Prayer request detail/prayer action | Prayer | Prayer Requests | Request detail and prayed/assign action | Rows imply drill-down and status transition | Member/worker | `PRAYER_DETAIL` | Full route | List-row callback is empty; only create route is wired |
| High | Sermon detail/player/search/filter | Media | Sermons Library | Sermon detail/player and search/filter results | Library cannot perform core consumption actions | Public/member | `SERMON_DETAIL_PLAYER` | Full route/player + sheet | Search, filter and row callbacks include empty handlers |
| High | Bible reading destinations | Bible | Bible | Passage reader, plans, bookmarks, highlights | Quick-access cards/rows imply navigation | Member | `BIBLE_READER`, `READING_PLAN_DETAIL`, `BOOKMARKS`, `HIGHLIGHTS` | Full routes | Multiple Bible row/card callbacks are empty |
| High | Event share/register from detail | Events | Event Detail / Events list | Share sheet and registration route | Core event flow entry point is dead | Public/member | Reuse `EVENT_REGISTRATION`; add share contract | Route + native share sheet | Empty event-detail/list callbacks found |
| High | Mission follow-up creation/report | Mission | Souls Follow-up / Crusade Detail | Add Soul and report creation | Mission operational flow stops at primary CTA | Mission worker | Reuse `SOUL_ADD`; `MISSION_REPORT_CREATE` | Full route | Add New Soul and Create Report callbacks are empty despite routes/screens existing for adjacent flows |
| High | KCA enrolment option and mentor chat actions | KCA | Enrol / Mentor Chat | Selected enrolment workflow; send/attach/call actions | KCA onboarding and communication are incomplete | Applicant/student/mentor | Existing KCA enrollment/chat routes plus action sheets | Full route/bottom sheet | Empty callbacks in enrol and mentor-chat screens |
| High | Press publication actions | Press | Press Library / Publication Detail | Open publication, download, share, player | Core Press workflow is incomplete | Public/member | Existing parameterized publication/player/download destinations | Full route/sheet | Empty callbacks in library and book screens; no asset API |
| High | Giving submission/history detail | Finance | Give / Giving History | Payment initiation and transaction detail | Primary giving CTA and history drill-down are dead | Member | Existing payment routes driven by ID | Full route | Give primary button and history row callbacks are empty |
| Medium | Profile edit | Account | Profile | Edit profile form | Visible Edit Profile CTA must work | Member | `PROFILE_EDIT` | Full route or large sheet | Profile button has empty callback |
| Medium | Home Church application review actions | Home Church | Applications | Review/detail/approve/reject/request-info | List CTA implies governance workflow | Authorized leader | `HOME_CHURCH_APPLICATION_DETAIL` | Full route | Application action callback is empty; no protected API contract |
| Medium | Documents download/share | Church | Documents | Download/open/share and result states | Visible document actions must work | Authorized member | `DOCUMENT_ACTIONS` | Bottom sheet/system open | Download callback empty; no signed asset contract |
| Medium | Unknown/expired link state | Navigation | External link/cold start | Content unavailable with safe return/search/support | Unknown paths currently look like normal Splash | All | Existing `CONTENT_UNAVAILABLE` configured with reason | Full route | Screen exists, but router fallback does not use it |
| Medium | Unsaved-form discard confirmation | Forms | Multi-step Home Church, KCA, reports, needs, support | Confirm discard / save draft | Required back behavior and progress preservation | Varies | `UNSAVED_CHANGES_DIALOG` | Dialog | No reusable discard guard or persistent draft architecture found |
| Medium | Search/filter overlays | Multiple lists | Directory/map/sermons/Press | Functional filter/sort sheet | Decorative or local-only controls do not bind to data | Varies | Reusable `FILTER_SHEET` | Bottom sheet | Several controls alter no repository query; no pagination/search controllers |

## Remediated dead-interaction evidence

Files that contained empty callbacks at audit time included:

- `lib/features/foundation/presentation/screens/sign_in_screen.dart`
- `lib/features/church/presentation/screens/church_detail_screen.dart`
- `lib/features/church/presentation/screens/find_churches_screen.dart`
- `lib/features/church/presentation/screens/members_list_screen.dart`
- `lib/features/church/presentation/screens/church_groups_screen.dart`
- `lib/features/church/presentation/screens/ministries_screen.dart`
- `lib/features/church/presentation/screens/documents_screen.dart`
- `lib/features/church/presentation/screens/home_church_applications_screen.dart`
- `lib/features/community/presentation/screens/events_screen.dart`
- `lib/features/community/presentation/screens/event_detail_screen.dart`
- `lib/features/community/presentation/screens/give_screen.dart`
- `lib/features/community/presentation/screens/giving_history_screen.dart`
- `lib/features/community/presentation/screens/groups_screen.dart`
- `lib/features/community/presentation/screens/prayer_screen.dart`
- `lib/features/community/presentation/screens/sermons_library_screen.dart`
- `lib/features/community/presentation/screens/bible_screen.dart`
- `lib/features/mission/presentation/screens/souls_followup_screen.dart`
- `lib/features/mission/presentation/screens/crusade_detail_screen.dart`
- `lib/features/kca/presentation/screens/kca_enroll_screen.dart`
- `lib/features/kca/presentation/screens/mentor_chat_screen.dart`
- `lib/features/press/presentation/screens/press_library_screen.dart`
- `lib/features/press/presentation/screens/press_book_screen.dart`
- `lib/features/account/presentation/screens/profile_screen.dart`

All listed callbacks were remediated. Unsupported backend/native actions now
use an explicit unavailable/error state rather than inventing an outcome.

## Safe conclusion

The approved designs are broadly represented and the explicit dead-callback
gate is closed. Production completion still depends on binding the repository,
identity, deep-link, persistence, and platform gaps documented in the
companion audits.
