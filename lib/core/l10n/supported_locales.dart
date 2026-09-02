const kFhcSupportedLocales = <String>[
  'en',
  'yo',
  'ig',
  'ha',
  'fr',
  'ar',
  'zh',
  'sw',
];

const kFhcDefaultLocale = 'en';

/// Locales supported by flutter_localizations Material/Cupertino delegates.
const kFhcFlutterMaterialLocales = <String>{'en', 'fr', 'ar', 'zh'};

/// MaterialApp locale for TextField and other Material widgets. Custom catalog
/// locales (yo, ig, ha, sw) fall back to English for widget chrome only.
String materialLocaleCodeFor(String fhcLanguageCode) {
  final code = normalizeFhcLocale(fhcLanguageCode);
  return kFhcFlutterMaterialLocales.contains(code) ? code : kFhcDefaultLocale;
}

class FhcLocaleMeta {
  const FhcLocaleMeta({
    required this.endonym,
    required this.englishName,
    required this.direction,
  });

  final String endonym;
  final String englishName;
  final TextDirectionCode direction;
}

enum TextDirectionCode { ltr, rtl }

const kFhcLocaleMeta = <String, FhcLocaleMeta>{
  'en': FhcLocaleMeta(
    endonym: 'English',
    englishName: 'English',
    direction: TextDirectionCode.ltr,
  ),
  'yo': FhcLocaleMeta(
    endonym: 'Yorùbá',
    englishName: 'Yoruba',
    direction: TextDirectionCode.ltr,
  ),
  'ig': FhcLocaleMeta(
    endonym: 'Igbo',
    englishName: 'Igbo',
    direction: TextDirectionCode.ltr,
  ),
  'ha': FhcLocaleMeta(
    endonym: 'Hausa',
    englishName: 'Hausa',
    direction: TextDirectionCode.ltr,
  ),
  'fr': FhcLocaleMeta(
    endonym: 'Français',
    englishName: 'French',
    direction: TextDirectionCode.ltr,
  ),
  'ar': FhcLocaleMeta(
    endonym: 'العربية',
    englishName: 'Arabic',
    direction: TextDirectionCode.rtl,
  ),
  'zh': FhcLocaleMeta(
    endonym: '中文',
    englishName: 'Chinese',
    direction: TextDirectionCode.ltr,
  ),
  'sw': FhcLocaleMeta(
    endonym: 'Kiswahili',
    englishName: 'Swahili',
    direction: TextDirectionCode.ltr,
  ),
};

String normalizeFhcLocale(String? value) {
  if (value == null) return kFhcDefaultLocale;
  final trimmed = value.trim().replaceAll('_', '-');
  if (trimmed.isEmpty) return kFhcDefaultLocale;
  final lower = trimmed.toLowerCase();
  if (kFhcSupportedLocales.contains(lower)) return lower;
  final primary = lower.split('-').first;
  if (kFhcSupportedLocales.contains(primary)) return primary;
  return kFhcDefaultLocale;
}

bool isRtlLocale(String locale) {
  return kFhcLocaleMeta[normalizeFhcLocale(locale)]?.direction ==
      TextDirectionCode.rtl;
}
