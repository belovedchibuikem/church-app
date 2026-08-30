# Family House Connect Mobile

Native Flutter implementation of the Family House Connect mobile references.
The active review set contains the original 13 community screens, 52 expansion
workflow screens, and 95 continuation screens. Repeated designs across the
contact sheets resolve to the same canonical Flutter route instead of creating
duplicate implementations.

## Production shell

- Composition root: `lib/core/di/app_services.dart` wires `HttpApiTransport`,
  session token store, Laravel authorization gateway, generated public API
  client (`../api/clients/dart`), and domain repositories that exist.
- Route IDs: parameterized deep links keep entity ULIDs in `FhcRouteArgs`
  (`lib/core/routing/fhc_route_args.dart`) so detail screens can load records.
- Shared async UI: `lib/shared/widgets/async_state.dart` for loading / error /
  empty / unavailable.
- Unbound payment, prayer, and messaging backends show honest unavailable UI
  unless `FHC_VISUAL_REVIEW` is on (golden/screenshot suites only).

## API URL configuration

Flutter does not read `.env` files. Use dart-defines (see `.env.example` and
`dart-define.example.json`):

| Define | Meaning |
|---|---|
| `FHC_API_URL` | Full `/api/v1` base for app transport/auth |
| `FHC_PUBLIC_API_BASE_URL` | Host origin for generated Dart clients |

Production default (when defines are unset):
`https://familyconnect.katakarra.com/api/v1`

```sh
flutter run --dart-define-from-file=dart-define.example.json
```

Local Laravel:

```sh
flutter run --dart-define-from-file=dart-define.local.json
```

`FHC_VISUAL_REVIEW=true` enables the allow-all authorization gateway for
golden/screenshot suites only. Do not ship release binaries with that define.

## Native platform status

`android/` and `ios/` projects exist (Internet/location, App Links / Associated
Domains scaffolds, release signing hook via `android/key.properties.example`,
push permission declarations). Store ship still needs upload keystore secrets,
hosted association files, and FCM/APNs after OD-009 — see
`docs/native/APP_LINK_ASSOCIATION.md` and repo `docs/HONEST_LIMITS.md`.

Local review may use Flutter web (`flutter run -d chrome`) or a device/emulator.

## Modules

- discovery, church detail, online church, groups, sermons, prayer, giving,
  wallet, events, notifications, profile, Bible, and settings;
- Home Church members, attendance, activities, reports, finance, needs,
  first-timer follow-up, altar call, counselling, and testimony workflows;
- Mission partners and support, crusade request, soul capture/follow-up,
  mentoring, teams, assignments, and support requests;
- KCA evidence, review, admission, certification, attendance, mentoring,
  assessment, certificates, alumni, and opportunities;
- Press categories, publications, media playback, and downloads;
- payments and receipts, privacy, consent, guardian/safeguarding, KCA enrolment
  and training, Kingdom Journey, membership, evangelism, leadership approvals,
  scoped dashboards, AI assistants, and global map workflows;
- offline access, queued synchronization, resumable evidence-upload states,
  download storage, low-bandwidth media preferences, and unavailable deep-link
  destinations.

Run the canonical target:

```sh
flutter run -d chrome
```

The default route is `/splash`. First launch continues through onboarding,
language/location setup, and sign-in into the module hub. Onboarding is stored
on-device and does not appear again. Every screen is also directly addressable
through the routes documented in `REQUIREMENTS_TRACEABILITY.md`.

Deterministic 390 x 844 visual captures:

```sh
flutter test test/visual_capture_test.dart --update-goldens
flutter test test/expanded_visual_capture_test.dart --update-goldens
flutter test test/continuation_visual_capture_test.dart --update-goldens
```

See `REQUIREMENTS_TRACEABILITY.md`, `VISUAL_VALIDATION.md`, and `KNOWN_GAPS.md`.
