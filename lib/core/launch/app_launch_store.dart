import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/locale_holder.dart';
import '../l10n/supported_locales.dart';

/// Persists first-run onboarding/setup so intro screens do not reappear.
///
/// Production flow: splash → onboarding (once) → language/location setup
/// → sign-in → optional MFA → role selection (once per install) → hub.
///
/// Extends [ChangeNotifier] so [MaterialApp] can rebuild when the locale
/// changes after setup or from Settings.
abstract class AppLaunchStore extends ChangeNotifier {
  AppLaunchStore({this.splashDuration = const Duration(milliseconds: 1800)});

  /// Minimum time the branded splash stays visible before routing.
  /// Tests use [Duration.zero] so `pumpAndSettle` does not stall.
  final Duration splashDuration;

  bool get isHydrated;
  bool get onboardingCompleted;
  bool get setupCompleted;
  String get languageCode;
  String get languageLabel;
  String? get locationLabel;
  String? get selectedRole;

  Future<void> hydrate();

  Future<void> completeOnboarding();

  Future<void> completeSetup({
    required String languageCode,
    required String languageLabel,
    String? locationLabel,
  });

  /// Updates the active UI locale without re-running first-run setup.
  Future<void> setLanguage({
    required String languageCode,
    required String languageLabel,
  });

  Future<void> saveRole(String role);

  /// Next named route after splash, given whether opaque tokens exist.
  String nextRoute({required bool hasSession}) {
    if (!onboardingCompleted) return '/onboarding/discover';
    if (!setupCompleted) return '/language';
    if (!hasSession) return '/sign-in';
    if (selectedRole == null || selectedRole!.trim().isEmpty) {
      return '/role-selection';
    }
    return '/hub';
  }
}

/// In-memory store for widget tests and web fallbacks.
final class MemoryAppLaunchStore extends AppLaunchStore {
  MemoryAppLaunchStore({
    super.splashDuration = Duration.zero,
    bool onboardingCompleted = false,
    bool setupCompleted = false,
    String languageCode = 'en',
    String languageLabel = 'English',
    String? locationLabel,
    String? selectedRole,
  }) : _onboardingCompleted = onboardingCompleted,
       _setupCompleted = setupCompleted,
       _languageCode = normalizeFhcLocale(languageCode),
    _languageLabel = languageLabel,
    _locationLabel = locationLabel,
    _selectedRole = selectedRole {
    FhcLocaleHolder.languageCode = normalizeFhcLocale(languageCode);
  }

  bool _hydrated = true;
  bool _onboardingCompleted;
  bool _setupCompleted;
  String _languageCode;
  String _languageLabel;
  String? _locationLabel;
  String? _selectedRole;

  @override
  bool get isHydrated => _hydrated;

  @override
  bool get onboardingCompleted => _onboardingCompleted;

  @override
  bool get setupCompleted => _setupCompleted;

  @override
  String get languageCode => _languageCode;

  @override
  String get languageLabel => _languageLabel;

  @override
  String? get locationLabel => _locationLabel;

  @override
  String? get selectedRole => _selectedRole;

  @override
  Future<void> hydrate() async {
    _hydrated = true;
  }

  @override
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
  }

  @override
  Future<void> completeSetup({
    required String languageCode,
    required String languageLabel,
    String? locationLabel,
  }) async {
    _onboardingCompleted = true;
    _setupCompleted = true;
    _languageCode = normalizeFhcLocale(languageCode);
    _languageLabel = languageLabel;
    _locationLabel = locationLabel;
    FhcLocaleHolder.languageCode = _languageCode;
    notifyListeners();
  }

  @override
  Future<void> setLanguage({
    required String languageCode,
    required String languageLabel,
  }) async {
    _languageCode = normalizeFhcLocale(languageCode);
    _languageLabel = languageLabel;
    FhcLocaleHolder.languageCode = _languageCode;
    notifyListeners();
  }

  @override
  Future<void> saveRole(String role) async {
    _selectedRole = role;
    notifyListeners();
  }
}

const _onboardingKey = 'fhc.launch.onboarding_completed';
const _setupKey = 'fhc.launch.setup_completed';
const _languageCodeKey = 'fhc.launch.language_code';
const _languageLabelKey = 'fhc.launch.language_label';
const _locationKey = 'fhc.launch.location_label';
const _roleKey = 'fhc.launch.selected_role';

/// Durable first-run flags via [SharedPreferences].
final class SharedPrefsAppLaunchStore extends AppLaunchStore {
  SharedPrefsAppLaunchStore({
    super.splashDuration,
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  SharedPreferences? _preferences;
  bool _hydrated = false;
  bool _onboardingCompleted = false;
  bool _setupCompleted = false;
  String _languageCode = 'en';
  String _languageLabel = 'English';
  String? _locationLabel;
  String? _selectedRole;

  @override
  bool get isHydrated => _hydrated;

  @override
  bool get onboardingCompleted => _onboardingCompleted;

  @override
  bool get setupCompleted => _setupCompleted;

  @override
  String get languageCode => _languageCode;

  @override
  String get languageLabel => _languageLabel;

  @override
  String? get locationLabel => _locationLabel;

  @override
  String? get selectedRole => _selectedRole;

  @override
  Future<void> hydrate() async {
    _preferences ??= await SharedPreferences.getInstance();
    _onboardingCompleted = _preferences!.getBool(_onboardingKey) ?? false;
    _setupCompleted = _preferences!.getBool(_setupKey) ?? false;
    _languageCode = normalizeFhcLocale(
      _preferences!.getString(_languageCodeKey) ?? 'en',
    );
    _languageLabel = _preferences!.getString(_languageLabelKey) ?? 'English';
    _locationLabel = _preferences!.getString(_locationKey);
    _selectedRole = _preferences!.getString(_roleKey);
    FhcLocaleHolder.languageCode = _languageCode;
    _hydrated = true;
  }

  @override
  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    await _prefs().setBool(_onboardingKey, true);
  }

  @override
  Future<void> completeSetup({
    required String languageCode,
    required String languageLabel,
    String? locationLabel,
  }) async {
    _onboardingCompleted = true;
    _setupCompleted = true;
    _languageCode = normalizeFhcLocale(languageCode);
    _languageLabel = languageLabel;
    _locationLabel = locationLabel;
    FhcLocaleHolder.languageCode = _languageCode;
    final prefs = _prefs();
    await Future.wait([
      prefs.setBool(_onboardingKey, true),
      prefs.setBool(_setupKey, true),
      prefs.setString(_languageCodeKey, _languageCode),
      prefs.setString(_languageLabelKey, languageLabel),
      if (locationLabel != null)
        prefs.setString(_locationKey, locationLabel)
      else
        prefs.remove(_locationKey),
    ]);
    notifyListeners();
  }

  @override
  Future<void> setLanguage({
    required String languageCode,
    required String languageLabel,
  }) async {
    _languageCode = normalizeFhcLocale(languageCode);
    _languageLabel = languageLabel;
    FhcLocaleHolder.languageCode = _languageCode;
    final prefs = _prefs();
    await Future.wait([
      prefs.setString(_languageCodeKey, _languageCode),
      prefs.setString(_languageLabelKey, languageLabel),
    ]);
    notifyListeners();
  }

  @override
  Future<void> saveRole(String role) async {
    _selectedRole = role;
    await _prefs().setString(_roleKey, role);
    notifyListeners();
  }

  SharedPreferences _prefs() {
    final prefs = _preferences;
    if (prefs == null) {
      throw StateError('AppLaunchStore.hydrate() must run before writes.');
    }
    return prefs;
  }
}

/// SharedPreferences on native/desktop; memory store on web.
Future<AppLaunchStore> createAppLaunchStore({AppLaunchStore? override}) async {
  if (override != null) {
    await override.hydrate();
    return override;
  }
  if (kIsWeb) {
    final store = MemoryAppLaunchStore(
      splashDuration: const Duration(milliseconds: 1800),
    );
    await store.hydrate();
    return store;
  }
  final store = SharedPrefsAppLaunchStore();
  await store.hydrate();
  return store;
}
