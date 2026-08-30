import 'package:family_house_connect_mobile/core/geography/geography_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatLocationLine joins locality, region, country', () {
    expect(
      GeographyCatalog.formatLocationLine(
        locality: 'Ikeja',
        region: 'Lagos',
        country: 'NG',
        countryLabel: 'Nigeria',
      ),
      'Ikeja, Lagos, Nigeria',
    );
  });

  test('locality label is LGA for Nigeria', () {
    expect(GeographyCatalog.localityLabelFor('NG'), 'LGA / City');
    expect(GeographyCatalog.localityLabelFor('GH'), 'City / Area');
  });

  test('fallback countries include Nigeria', () {
    expect(
      GeographyCatalog.fallbackCountries.any((c) => c.code == 'NG'),
      isTrue,
    );
  });
}
