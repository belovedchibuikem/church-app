import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_house_connect_mobile/core/design_system/fhc_tokens.dart';
import 'package:family_house_connect_mobile/features/account/presentation/screens/profile_screen.dart';
import 'package:family_house_connect_mobile/features/account/presentation/screens/settings_screen.dart';
import 'package:family_house_connect_mobile/features/community/presentation/screens/bible_screen.dart';
import 'package:family_house_connect_mobile/features/community/presentation/screens/giving_history_screen.dart';

void main() {
  final screens = <String, Widget>{
    'Profile': const ProfileScreen(),
    'Bible': const BibleScreen(),
    'Giving History': const GivingHistoryScreen(),
    'Settings': const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('${entry.key} renders at 390x844 without layout errors', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(theme: buildFhcTheme(), home: entry.value),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  }
}
