import '../foundation/presentation/fhc_nav.dart';

String kcaRouteForDestination(String? destination) {
  switch (destination) {
    case 'student_dashboard':
      return FhcRoutes.kca;
    case 'resume_application':
      return FhcRoutes.kcaEnroll;
    case 'admission_progress':
    case 'information_required':
    case 'provisional_offer':
    case 'deferred':
    case 'not_admitted':
    case 'withdrawn':
    case 'restricted':
      return FhcRoutes.kcaAdmission;
    case 'orientation':
      return FhcRoutes.kcaOrientation;
    case 'admission_letter':
      return FhcRoutes.kcaAdmissionLetter;
    case 'overview':
    default:
      return FhcRoutes.kcaEnroll;
  }
}

String kcaCtaLabel(String? destination) {
  switch (destination) {
    case 'resume_application':
      return 'Resume application';
    case 'information_required':
      return 'Provide information';
    case 'orientation':
      return 'Open orientation';
    case 'admission_letter':
      return 'View admission letter';
    case 'student_dashboard':
      return 'Open dashboard';
    case 'overview':
      return 'Enroll Now';
    default:
      return 'View admission status';
  }
}
