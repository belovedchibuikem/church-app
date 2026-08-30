# Native app-link association (honest status)

**Status:** Scaffolded in the Flutter `android/` + `ios/` projects — **not**
production-verified.

## What exists

| Piece | Location | Ready to ship? |
|---|---|---|
| Android App Links intent-filter | `android/app/src/main/AndroidManifest.xml` | No — host is a placeholder; Digital Asset Links file not published |
| Custom scheme `fhc://open` | Android + iOS URL types | Dev-only convenience |
| iOS Associated Domains entitlement | `ios/Runner/Runner.entitlements` + `CODE_SIGN_ENTITLEMENTS` in `project.pbxproj` | No — must enable capability in Apple Developer / Xcode signing + host `apple-app-site-association` |
| Release signing hook | `android/app/build.gradle.kts` + `android/key.properties.example` | No — without `key.properties`, release uses debug signing |
| Push background / POST_NOTIFICATIONS | Android manifest + iOS `UIBackgroundModes` | Declarations only; FCM/APNs unbound (`PushNotificationScaffold.isConfigured == false`) |

## Remaining before store ship

1. Approve production app domain(s).
2. Host `https://<domain>/.well-known/assetlinks.json` (Android) and
   `apple-app-site-association` (iOS) with the real package name / team ID /
   SHA-256 cert fingerprints.
3. Point Manifest host + Runner entitlements at that domain.
4. Create upload keystore, fill `android/key.properties` (never commit secrets).
5. In Xcode: confirm Associated Domains capability, keep
   `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements`, configure APNs
   (`aps-environment`) only after push provider approval — do not add a fake
   FCM/`GoogleService-Info.plist`.
6. Add FCM/`google-services.json` (or approved push vendor) after OD-009, then
   flip `PushNotificationScaffold.isConfigured` via a real adapter.

## Templates

See `well-known/` in this folder for non-production example association JSON.

Current placeholders:

- Android package: `com.smartlogix.family_house_connect`
- iOS bundle: `com.smartlogix.family_house_connect`
- App Links host scaffold: `familyconnect.katakarra.com`
