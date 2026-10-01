import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/pages/internal_gallery_page.dart';

const _channel = MethodChannel('com.fluttercandies/photo_manager');
final _album = {
  'data': [
    {'id': 'isAll', 'name': 'Recent', 'assetCount': 2, 'isAll': true},
  ],
};
final _media = {
  'data': [
    {'id': 'photo1', 'type': 1, 'width': 400, 'height': 300},
    {'id': 'video1', 'type': 2, 'width': 400, 'height': 300, 'duration': 5},
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, null);
  });

  Future<void> openGallery(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: InternalGalleryPage()));
    await tester.pumpAndSettle();
  }

  testWidgets('broken album names do not block the All media grid', (tester) async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'requestPermissionExtend':
          return 3;
        case 'getAssetPathList':
          if ((call.arguments as Map)['onlyAll'] == true) return _album;
          // A MediaStore provider may have media with an absent bucket name.
          return {
            'data': [
              {'id': 'broken', 'name': null, 'assetCount': 2, 'isAll': false},
            ],
          };
        case 'getAssetListPaged':
          return _media;
        default:
          return null;
      }
    });

    await openGallery(tester);
    expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
    expect(find.byKey(const ValueKey('video1')), findsOneWidget);
    expect(calls.where((c) => c.method == 'getAssetPathList').length, 1);
    final query = (calls.firstWhere((c) => c.method == 'getAssetPathList').arguments as Map)['option'] as Map;
    expect((calls.firstWhere((c) => c.method == 'getAssetListPaged').arguments as Map)['option'], query);
    expect(query['child']['orders'], isEmpty); // Native classical filters use _id DESC.
    expect(query['child']['createDate']['ignore'], true);
    expect(query['child']['image']['size']['ignoreSize'], true);
    if (const bool.fromEnvironment('EXPORT_MEDIA_QUERY')) {
      // Feed the actual Dart channel payload to the Kotlin/SQLite regression
      // suite, so it exercises the plugin with the same query as this screen.
      final fixture = File('build/gallery-tests/gallery-query.json');
      fixture.parent.createSync(recursive: true);
      fixture.writeAsStringSync(jsonEncode(query));
    }
    expect((calls.firstWhere((c) => c.method == 'requestPermissionExtend').arguments as Map)['androidPermission']['mediaLocation'], false);

    await tester.tap(find.text('All photos and videos'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
    expect(find.text('Could not load photos and videos.'), findsNothing);
    expect(find.text('Could not load albums. All photos and videos are still available.'), findsOneWidget);
    expect((calls.lastWhere((c) => c.method == 'getAssetPathList').arguments as Map)['option'], query);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('returning from settings reloads media after permission is granted', (tester) async {
    var permission = 2;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
        case 'getPermissionState':
          return permission;
        case 'getAssetPathList':
          return _album;
        case 'getAssetListPaged':
          return _media;
        default:
          return null;
      }
    });

    await openGallery(tester);
    expect(find.text('Allow access to photos and videos to use the gallery.'), findsOneWidget);
    permission = 3;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
    expect(find.byKey(const ValueKey('video1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failed All query can be retried without reopening the gallery', (tester) async {
    var fail = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_channel, (call) async {
      switch (call.method) {
        case 'requestPermissionExtend':
        case 'getPermissionState':
          return 3;
        case 'getAssetPathList':
          if (fail) throw PlatformException(code: 'query', message: 'Media provider unavailable');
          return _album;
        case 'getAssetListPaged':
          return _media;
        default:
          return null;
      }
    });

    await openGallery(tester);
    expect(find.text('Could not load photos and videos.'), findsOneWidget);
    await tester.tap(find.text('Error details'));
    await tester.pumpAndSettle();
    expect(find.text('Gallery error details'), findsOneWidget);
    final details = tester.widget<SelectableText>(find.byType(SelectableText)).data!;
    expect(details, contains('Stage: media index'));
    expect(details, contains('Media provider unavailable'));
    expect(find.text('Copy'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
    expect(find.byKey(const ValueKey('video1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
