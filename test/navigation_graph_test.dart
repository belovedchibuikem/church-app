import 'package:family_house_connect_mobile/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRoute(WidgetTester tester, String route) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FamilyHouseConnectApp(initialRoute: route));
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 8),
      );
    } catch (_) {
      // Infinite / long animations: advance a frame instead of hanging.
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('/discover shows Find Churches OR Discover OR Lagos', (
    tester,
  ) async {
    await pumpRoute(tester, '/discover');
    expect(
      find.textContaining(RegExp(r'Find Churches|Discover|Lagos')),
      findsWidgets,
    );
  });

  testWidgets('/events shows Events', (tester) async {
    await pumpRoute(tester, '/events');
    expect(find.textContaining(RegExp(r'Events', caseSensitive: false)), findsWidgets);
  });

  testWidgets('/prayer shows Prayer', (tester) async {
    await pumpRoute(tester, '/prayer');
    expect(find.textContaining(RegExp(r'Prayer', caseSensitive: false)), findsWidgets);
  });

  testWidgets('/give shows Give', (tester) async {
    await pumpRoute(tester, '/give');
    expect(find.textContaining(RegExp(r'Give', caseSensitive: false)), findsWidgets);
  });

  testWidgets('/profile still shows Profile|Chibuikem', (tester) async {
    await pumpRoute(tester, '/profile');
    expect(find.textContaining(RegExp(r'Profile|Chibuikem')), findsWidgets);
  });

  testWidgets('/hub still shows CHURCH and PRESS', (tester) async {
    await pumpRoute(tester, '/hub');
    expect(find.text('CHURCH'), findsOneWidget);
    expect(find.text('PRESS'), findsOneWidget);
  });

  testWidgets('/church still shows Join Live|Members', (tester) async {
    await pumpRoute(tester, '/church');
    expect(find.textContaining(RegExp(r'Join Live|Members')), findsWidgets);
  });

  testWidgets('/sermons shows Sermons or FAITH', (tester) async {
    await pumpRoute(tester, '/sermons');
    expect(find.textContaining(RegExp(r'Sermons|FAITH')), findsWidgets);
  });

  testWidgets('/groups shows Groups or Fellowship', (tester) async {
    await pumpRoute(tester, '/groups');
    expect(find.textContaining(RegExp(r'Groups|Fellowship')), findsWidgets);
  });

  testWidgets('/bible shows Bible or Philippians', (tester) async {
    await pumpRoute(tester, '/bible');
    expect(find.textContaining(RegExp(r'Bible|Philippians')), findsWidgets);
  });

  testWidgets('/give/history shows Giving History or 125,000', (tester) async {
    await pumpRoute(tester, '/give/history');
    expect(
      find.textContaining(RegExp(r'Giving History|125,000')),
      findsWidgets,
    );
  });

  testWidgets('/church/home shows CHURCH or Members', (tester) async {
    await pumpRoute(tester, '/church/home');
    expect(find.textContaining(RegExp(r'CHURCH|Members')), findsWidgets);
  });

  testWidgets('/church/members shows Members or Add Member', (tester) async {
    await pumpRoute(tester, '/church/members');
    expect(find.textContaining(RegExp(r'Members|Add Member')), findsWidgets);
  });

  testWidgets('/events/detail shows Convention or Register', (tester) async {
    await pumpRoute(tester, '/events/detail');
    expect(find.textContaining(RegExp(r'Convention|Register')), findsWidgets);
  });

  testWidgets('/mission/souls shows Soul or Follow-up', (tester) async {
    await pumpRoute(tester, '/mission/souls');
    expect(find.textContaining(RegExp(r'Soul|Follow-up')), findsWidgets);
  });

  testWidgets('/media shows Media or Watch', (tester) async {
    await pumpRoute(tester, '/media');
    expect(find.textContaining(RegExp(r'Media|Watch')), findsWidgets);
  });
}
