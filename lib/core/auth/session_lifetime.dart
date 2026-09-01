/// Mobile access and refresh credentials stay valid for 30 days (matches
/// Laravel `MobileCredentialTtl::MIN_SESSION_SECONDS`).
const kMobileSessionLifetime = Duration(days: 30);

/// Re-fetch `/user/capabilities` in the background after this window.
/// Stale snapshots stay usable so idle time does not lock screens.
const kCapabilityRevalidateAfter = Duration(hours: 6);
