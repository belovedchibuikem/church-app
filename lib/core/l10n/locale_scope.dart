import 'package:flutter/material.dart';

import 'lookup.dart';
import 'supported_locales.dart';

/// Reactive locale for widgets. Rebuilds when [languageCode] changes.
final class FhcLocaleScope extends InheritedWidget {
  const FhcLocaleScope({
    super.key,
    required this.languageCode,
    required super.child,
  });

  final String languageCode;

  static FhcLocaleScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<FhcLocaleScope>();
    assert(
      scope != null,
      'FhcLocaleScope not found. Wrap the app with FamilyHouseConnectApp.',
    );
    return scope!;
  }

  static FhcLocaleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FhcLocaleScope>();
  }

  String t(String key, {Map<String, String>? args, String? fallback}) {
    return lookupFhcMessage(
      languageCode,
      key,
      args: args,
      fallback: fallback,
    );
  }

  bool get isRtl => isRtlLocale(languageCode);

  @override
  bool updateShouldNotify(FhcLocaleScope oldWidget) =>
      languageCode != oldWidget.languageCode;
}

String fhcT(
  BuildContext context,
  String key, {
  Map<String, String>? args,
  String? fallback,
}) {
  final scope = FhcLocaleScope.maybeOf(context);
  if (scope == null) {
    return lookupFhcMessage('en', key, args: args, fallback: fallback);
  }
  return scope.t(key, args: args, fallback: fallback);
}
