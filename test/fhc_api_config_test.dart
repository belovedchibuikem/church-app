import 'package:family_house_connect_mobile/core/api/fhc_api_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production API host is the default /api/v1 base', () {
    expect(
      resolveFhcApiUrl(),
      'https://familyconnect.katakarra.com/api/v1',
    );
    expect(
      resolveFhcPublicApiBaseUrl(),
      'https://familyconnect.katakarra.com',
    );
  });

  test('override wins over the production default', () {
    expect(
      resolveFhcApiUrl(override: 'http://localhost:8000'),
      'http://localhost:8000/api/v1',
    );
  });
}
