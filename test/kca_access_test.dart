import 'package:family_house_connect_mobile/features/foundation/presentation/fhc_nav.dart';
import 'package:family_house_connect_mobile/features/kca/kca_access.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('KCA destinations map to live routes', () {
    expect(kcaRouteForDestination('overview'), FhcRoutes.kcaEnroll);
    expect(kcaRouteForDestination('resume_application'), FhcRoutes.kcaEnroll);
    expect(kcaRouteForDestination('admission_progress'), FhcRoutes.kcaAdmission);
    expect(
      kcaRouteForDestination('information_required'),
      FhcRoutes.kcaAdmission,
    );
    expect(kcaRouteForDestination('orientation'), FhcRoutes.kcaOrientation);
    expect(
      kcaRouteForDestination('admission_letter'),
      FhcRoutes.kcaAdmissionLetter,
    );
    expect(kcaRouteForDestination('student_dashboard'), FhcRoutes.kca);
    expect(kcaRouteForDestination('deferred'), FhcRoutes.kcaAdmission);
    expect(kcaRouteForDestination('not_admitted'), FhcRoutes.kcaAdmission);
    expect(kcaRouteForDestination('restricted'), FhcRoutes.kcaAdmission);
  });
}
