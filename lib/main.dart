import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/di/app_services.dart';
import 'core/launch/app_launch_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const visualReview = bool.fromEnvironment(
    'FHC_VISUAL_REVIEW',
    defaultValue: false,
  );

  final launchStore = await createAppLaunchStore();

  runApp(
    FamilyHouseConnectApp(
      initialRoute: '/splash',
      launchStore: launchStore,
      services: AppServices.bootstrap(visualReview: visualReview),
    ),
  );
}
