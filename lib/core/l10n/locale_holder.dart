/// Process-wide active locale for API `Accept-Language` headers.
///
/// Updated by [AppLaunchStore] whenever the persisted language changes.
class FhcLocaleHolder {
  FhcLocaleHolder._();

  static String languageCode = 'en';
}
