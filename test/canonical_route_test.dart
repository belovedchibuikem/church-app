import 'package:family_house_connect_mobile/core/routing/fhc_route_args.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveCanonicalRoute preserves church ULID', () {
    const ulid = '01JABC2DEF3GHI4JKL5MNO6PQR';
    final resolved = resolveCanonicalRoute('/discover/church/$ulid');
    expect(resolved.canonical, '/church/detail');
    expect(resolved.entityId, ulid);
  });

  test('resolveCanonicalRoute preserves event slug on register', () {
    final resolved = resolveCanonicalRoute('/events/kingdom-impact/register');
    expect(resolved.canonical, '/events/register');
    expect(resolved.entityId, 'kingdom-impact');
  });

  test('resolveCanonicalRoute preserves payment id on receipt', () {
    final resolved = resolveCanonicalRoute('/payments/PAY-123/receipt');
    expect(resolved.canonical, '/payments/receipt');
    expect(resolved.entityId, 'PAY-123');
  });

  test('resolveCanonicalRoute preserves crusade ULID', () {
    const ulid = '01JCRUSADE0000000000000001';
    final resolved = resolveCanonicalRoute('/mission/crusade/$ulid');
    expect(resolved.canonical, '/mission/crusade');
    expect(resolved.entityId, ulid);
  });
}
