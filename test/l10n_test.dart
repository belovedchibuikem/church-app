import 'package:family_house_connect_mobile/core/l10n/lookup.dart';
import 'package:family_house_connect_mobile/core/l10n/supported_locales.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supported locales include Arabic RTL and eight platform languages', () {
    expect(
      kFhcSupportedLocales,
      ['en', 'yo', 'ig', 'ha', 'fr', 'ar', 'zh', 'sw'],
    );
    expect(normalizeFhcLocale('en-NG'), 'en');
    expect(isRtlLocale('ar'), isTrue);
    expect(isRtlLocale('en'), isFalse);
  });

  test('material locale falls back to English for unsupported Flutter delegates', () {
    expect(materialLocaleCodeFor('en'), 'en');
    expect(materialLocaleCodeFor('fr'), 'fr');
    expect(materialLocaleCodeFor('ar'), 'ar');
    expect(materialLocaleCodeFor('zh'), 'zh');
    expect(materialLocaleCodeFor('yo'), 'en');
    expect(materialLocaleCodeFor('ig'), 'en');
    expect(materialLocaleCodeFor('ha'), 'en');
    expect(materialLocaleCodeFor('sw'), 'en');
  });

  test('lookup interpolates and falls back to English', () {
    expect(
      lookupFhcMessage('fr', 'common.continueWith', args: {'language': 'Français'}),
      'Continuer en Français',
    );
    expect(lookupFhcMessage('yo', 'common.save'), isNot('Save'));
    expect(
      lookupFhcMessage('fr', 'does.not.exist', fallback: 'Fallback'),
      'Fallback',
    );
  });

  test('non-English catalogs are authored, not English copies', () {
    const keys = [
      'common.save',
      'nav.home',
      'auth.signIn',
      'onboarding.chooseLanguage',
    ];
    for (final locale in kFhcSupportedLocales.where((code) => code != 'en')) {
      for (final key in keys) {
        expect(
          lookupFhcMessage(locale, key),
          isNot(lookupFhcMessage('en', key)),
          reason: '$locale $key',
        );
      }
    }
  });
}
