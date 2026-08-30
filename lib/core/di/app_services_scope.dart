import 'package:flutter/material.dart';

import 'app_services.dart';

/// Exposes [AppServices] to the widget tree below [FamilyHouseConnectApp].
final class AppServicesScope extends InheritedWidget {
  const AppServicesScope({
    super.key,
    required this.services,
    required super.child,
  });

  final AppServices services;

  static AppServices of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppServicesScope>();
    assert(
      scope != null,
      'AppServicesScope not found. Wrap the app with FamilyHouseConnectApp '
      'or provide AppServices explicitly in tests.',
    );
    return scope!.services;
  }

  static AppServices? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppServicesScope>()
        ?.services;
  }

  @override
  bool updateShouldNotify(AppServicesScope oldWidget) =>
      services != oldWidget.services;
}
