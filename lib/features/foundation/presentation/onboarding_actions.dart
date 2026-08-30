import 'package:flutter/material.dart';

import '../../../core/launch/app_launch_scope.dart';
import 'fhc_nav.dart';

Future<void> fhcCompleteOnboarding(BuildContext context) async {
  await AppLaunchScope.maybeOf(context)?.completeOnboarding();
  if (!context.mounted) return;
  fhcGo(context, '/language');
}
