import 'package:flutter/material.dart';

import 'app_launch_store.dart';

/// Exposes [AppLaunchStore] below [FamilyHouseConnectApp].
final class AppLaunchScope extends InheritedWidget {
  const AppLaunchScope({
    super.key,
    required this.store,
    required super.child,
  });

  final AppLaunchStore store;

  static AppLaunchStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLaunchScope>();
    assert(
      scope != null,
      'AppLaunchScope not found. Wrap the app with FamilyHouseConnectApp.',
    );
    return scope!.store;
  }

  static AppLaunchStore? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppLaunchScope>()
        ?.store;
  }

  @override
  bool updateShouldNotify(AppLaunchScope oldWidget) => store != oldWidget.store;
}
