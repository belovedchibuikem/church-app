import 'package:family_house_connect_mobile/core/api/app_failure.dart';
import 'package:family_house_connect_mobile/core/contracts/mobile_repository_contracts.dart';
import 'package:family_house_connect_mobile/core/design_system/fhc_tokens.dart';
import 'package:family_house_connect_mobile/features/community/data/livestream_repository.dart';
import 'package:family_house_connect_mobile/features/community/presentation/screens/live_fellowship_screen.dart';
import 'package:family_house_connect_mobile/features/press/presentation/screens/press_book_screen.dart';
import 'package:family_house_connect_mobile/features/press/presentation/screens/press_library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakePressRepository implements PressRepository {
  _FakePressRepository(this.items);

  final List<JsonObject> items;
  JsonObject? lastSearch;

  @override
  Future<AppResult<List<JsonObject>>> search(JsonObject filters) async {
    lastSearch = filters;
    return AppSuccess(items);
  }

  @override
  Future<AppResult<JsonObject>> getPublication(String id) async {
    final match = items.cast<JsonObject?>().firstWhere(
      (item) => '${item?['id']}' == id,
      orElse: () => null,
    );
    if (match == null) {
      return const AppError(NotFoundFailure('Publication was not found.'));
    }
    return AppSuccess(match);
  }

  @override
  Future<AppResult<JsonObject>> download(String id) async {
    return const AppError(NotFoundFailure('No file has been published yet.'));
  }

  @override
  Future<AppResult<JsonObject>> uploadAdminFile({
    required List<int> bytes,
    required String filename,
    String purpose = 'press_content',
    String classification = 'internal',
  }) async {
    return const AppError(
      IntegrationUnavailableFailure('Upload is not used in this test.'),
    );
  }

  @override
  Future<AppResult<JsonObject>> createPublication(JsonObject body) async {
    return const AppError(
      IntegrationUnavailableFailure('Create is not used in this test.'),
    );
  }
}

final class _FakeLivestream implements LivestreamSource {
  _FakeLivestream({this.stream, this.comments = const []});

  final JsonObject? stream;
  final List<JsonObject> comments;

  @override
  Future<AppResult<JsonObject?>> getCurrent() async => AppSuccess(stream);

  @override
  Future<AppResult<List<JsonObject>>> listComments(
    String livestreamId, {
    String? since,
  }) async => AppSuccess(comments);

  @override
  Future<AppResult<JsonObject>> postComment(
    String livestreamId,
    String body,
  ) async {
    return AppSuccess({
      'id': 'c1',
      'person_name': 'Ada',
      'body': body,
      'created_at': '2026-08-31T20:00:00Z',
    });
  }

  @override
  Future<AppResult<JsonObject>> react(String livestreamId) async {
    return const AppSuccess({'reaction_count': 1});
  }
}

Widget _app(Widget home) {
  return MaterialApp(
    theme: buildFhcTheme(),
    home: home,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final publications = <JsonObject>[
    {
      'id': '01PRESS000000000000000001',
      'title': 'Hope and Faith',
      'subtitle': 'A published title from the catalogue API.',
      'publisher': 'Family House Press',
      'format': 'pdf',
      'publication_type': 'book',
      'slug': 'hope-and-faith',
      'language': 'en',
      'availability': 'available',
    },
  ];

  testWidgets('press library filter opens a catalogue sheet, not a stub', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(PressLibraryScreen(repository: _FakePressRepository(publications))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hope and Faith'), findsWidgets);
    expect(find.text('Devotionals'), findsOneWidget);
    expect(find.text('Study Manuals'), findsNothing);
    expect(find.text('Integration required'), findsNothing);

    await tester.tap(find.byIcon(Icons.tune));
    await tester.pumpAndSettle();

    expect(find.text('Filter publications'), findsOneWidget);
    expect(find.text('Integration required'), findsNothing);
    expect(find.text('Apply'), findsOneWidget);
  });

  testWidgets('press book share copies a link instead of a stub sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        PressBookScreen(
          publicationId: '01PRESS000000000000000001',
          repository: _FakePressRepository(publications),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hope and Faith'), findsWidgets);
    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pump();

    expect(find.text('Integration required'), findsNothing);
    expect(find.textContaining('Laravel/OpenAPI'), findsNothing);
  });

  testWidgets('live screen uses a professional comment field', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        LiveFellowshipScreen(
          repository: _FakeLivestream(
            stream: const {
              'id': '01LIVE0000000000000000001',
              'title': 'Sunday Celebration',
              'status': 'live',
              'church_name': 'Family House Ikeja',
              'watch_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            },
            comments: const [
              {
                'id': 'c0',
                'person_name': 'Ada',
                'body': 'Amen.',
                'created_at': '2026-08-31T20:00:00Z',
              },
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Write a comment'), findsOneWidget);
    expect(find.text('Amen.'), findsOneWidget);
    expect(find.text('No comments yet.'), findsNothing);
    expect(find.text('Type a message...'), findsNothing);
    expect(find.text('Be the first to share a word of faith.'), findsNothing);
    expect(find.text('128'), findsNothing);
    expect(find.text('42'), findsNothing);
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Comments'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

