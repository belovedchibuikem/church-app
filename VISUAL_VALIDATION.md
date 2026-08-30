# Visual Validation — Community and Expansion Mobile Screens

Date: 2026-08-26

Canonical viewport: 390 x 844 logical pixels

References: `assets/design/community_13_reference.png` and
`assets/design/expansion_sheet_1.png` through `expansion_sheet_7.png`
plus `assets/design/continuation_sheet_1.png` through
`assets/design/continuation_sheet_8.png`, and
`assets/design/closure_offline_sheet.png`

## Result

- The 13 community screens and 52 distinct expansion screens were rendered as
  native Flutter widget trees. Duplicate screenshots reuse canonical routes.
- A further 95 distinct continuation screens were rendered after reusing all
  repeated canonical workflows from the new eight-sheet batch.
- The app deliberately omits fabricated time, battery, Wi-Fi, and cellular
  status-bar widgets. Platform safe-area behavior remains intact.
- Deterministic captures are stored in `artifacts/screenshots/community/`.
- `community-13-comparison.png` is the combined final review surface.
- `expansion-comparison-1.png` through `expansion-comparison-4.png` are the
  four expansion review surfaces.
- `continuation-comparison-1.png` through `continuation-comparison-7.png` are
  the continuation review surfaces.
- The default `/discover` route launched successfully with the canonical
  `flutter run -d chrome` command and attached to the Dart VM debug service.

## Discrepancy loop

1. Replaced the previous full-screen raster approach with native headers,
   controls, cards, lists, forms, tabs, and bottom navigation.
2. Split the 13 screens across three worker streams, then integrated them into
   the shared route and token system.
3. Removed duplicate text and controls from Live Service, Sermons, and Events
   where the supplied artwork crop already contained those reference details.
4. Anchored Church Detail actions to the bottom and corrected Discover hero
   sizing to remain overflow-free under both application and test fonts.
5. Made message badges screen-specific and fixed the Give navigation state.
6. Explicitly preloaded all visible raster assets so every golden is stable.
7. Regenerated and visually reviewed the combined 13-screen sheet.
8. Built canonical shared workflow components for fixed headers, form fields,
   summaries, cards, status pills, progress, uploads, actions, and module-aware
   bottom navigation.
9. Captured and reviewed all 52 expansion routes at 390 x 844; corrected the
   route guards and interaction paths without adding the reference device's
   time, battery, Wi-Fi, or cellular chrome.
10. Replaced the over-shared workflow navigation with reference-specific
    Church, Mission, KCA, Press, and universal account navigation sets, then
    regenerated all affected captures and comparison sheets.
11. Added deterministic payment states, privacy/guardian/safeguarding screens,
    eight KCA enrolment steps, training/review workspaces, the 14-stage Kingdom
    Journey, membership/leadership flows, scoped AI assistants, and map states.
12. Replaced the animated payment-processing indicator with a deterministic
    progress state so screenshot evidence remains stable across runs.
13. Added the final offline, queued-sync, sync-success, resumable-upload,
    upload-failure, storage, low-bandwidth, and unavailable-content states.
14. Tightened the upload-progress cards so the background-continuation notice
    remains visible above the persistent navigation at 390 x 844.

## Verification evidence

- `flutter analyze` — passed with no issues.
- `flutter test test/expanded_visual_capture_test.dart --update-goldens` — 52
  expansion render/golden tests passed without overflow.
- `flutter test test/expanded_navigation_test.dart` — 6 workflow and scoped
  authorization tests passed.
- `flutter test test/continuation_visual_capture_test.dart` — 95 continuation
  render/golden tests passed without overflow.
- `flutter test test/continuation_navigation_test.dart` — 10 continuation flow
  and scoped-authorization tests passed.
- `test/route_connectivity_test.dart` verifies canonical aliases,
  parameterized resource links, invalid-link fallback, and fail-closed guards.
- `flutter build web --release` — passed and produced `build/web`.
- `flutter run -d chrome` — launched, connected to the debug service, and
  exited cleanly after verification.

The browser-control extension was not connected, so the final PNG evidence is
captured from Flutter's deterministic render pipeline rather than a separate
browser-surface screenshot. It uses the same 390 x 844 widget tree and assets.
