import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_isolates/model/file_type.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Deliberately do not initialize intl's locale data: the English-only app
  // uses the default localization delegates, which do not initialize it.
  ReceiveHistoryEntry entry({String id = 'received-file', bool gallery = false, bool message = false}) => ReceiveHistoryEntry(
    id: id,
    fileName: message ? 'Hello from the sender' : '$id.pdf',
    fileType: message ? FileType.text : gallery ? FileType.image : FileType.pdf,
    path: gallery || message ? null : '/storage/emulated/0/Download/$id.pdf',
    savedToGallery: gallery,
    isMessage: message,
    fileSize: 1024,
    senderAlias: 'Sender phone',
    timestamp: DateTime.utc(2026, 10, 1, 12, 30),
  );

  Future<(RefenaContainer, PersistenceService)> openHistory(WidgetTester tester, List<ReceiveHistoryEntry> entries) async {
    SharedPreferences.setMockInitialValues({
      'ls_version': 4,
      'ls_alias': 'Receiver phone',
      'ls_show_token': 'token',
      'ls_security_context': '{}',
      'ls_receive_history': entries.map((e) => jsonEncode(e.toJson())).toList(),
    });
    final persistence = await PersistenceService.initialize();
    final container = RefenaContainer(overrides: [persistenceProvider.overrideWithValue(persistence)]);
    addTearDown(() => container.dispose(receiveHistoryProvider));
    await tester.pumpWidget(
      RefenaScope.withContainer(
        container: container,
        child: TranslationProvider(
          child: MaterialApp(
            theme: getOledTheme(),
            locale: const Locale('en'),
            home: const ReceiveHistoryPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, persistence);
  }

  testWidgets('saved receive history renders on a cold English-only app start', (tester) async {
    final saved = entry();
    await openHistory(tester, [saved]);

    expect(tester.takeException(), isNull);
    expect(find.text(saved.fileName), findsOneWidget);
    expect(find.textContaining('Sender phone'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text(t.receiveHistoryPage.empty), findsNothing);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a newly received file appears immediately and survives reloading history', (tester) async {
    final (container, persistence) = await openHistory(tester, []);
    expect(find.text(t.receiveHistoryPage.empty), findsOneWidget);

    final received = entry(id: 'new-file');
    await container.redux(receiveHistoryProvider).dispatchAsync(
      AddHistoryEntryAction(
        entryId: received.id,
        fileName: received.fileName,
        fileType: received.fileType,
        path: received.path,
        savedToGallery: received.savedToGallery,
        isMessage: received.isMessage,
        fileSize: received.fileSize,
        senderAlias: received.senderAlias,
        timestamp: received.timestamp,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(received.fileName), findsOneWidget);
    expect(persistence.getReceiveHistory(), [received]);
    final restarted = RefenaContainer(overrides: [persistenceProvider.overrideWithValue(persistence)]);
    addTearDown(() => restarted.dispose(receiveHistoryProvider));
    expect(restarted.read(receiveHistoryProvider), [received]);
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('gallery receipts and messages remain visible without a file path', (tester) async {
    final photo = entry(id: 'gallery-photo', gallery: true);
    final message = entry(id: 'message', message: true);
    await openHistory(tester, [photo, message]);

    expect(tester.takeException(), isNull);
    expect(find.text(photo.fileName), findsOneWidget);
    expect(find.text(message.fileName), findsOneWidget);
    expect(find.textContaining('Sender phone'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
