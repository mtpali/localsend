import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localsend_app/model/persistence/quick_save_mode.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  Map<String, Object> seed({int? version}) => {'ls_version': ?version, 'ls_alias': 'Device', 'ls_show_token': 'token', 'ls_security_context': '{}'};

  test('Fresh settings enable quick save and auto finish without requiring a PIN', () async {
    SharedPreferences.setMockInitialValues(seed());
    final service = await PersistenceService.initialize();
    expect(service.getQuickSave(), QuickSaveMode.on);
    expect(service.isAutoFinish(), isTrue);
    expect(service.getReceivePin(), isNull);
  });

  test('Migration removes obsolete settings and preserves manual acceptance', () async {
    SharedPreferences.setMockInitialValues({
      ...seed(version: 3),
      'ls_quick_save': 'paired',
      'ls_favorites': <String>['legacy'],
      'ls_color': 'custom',
      'ls_theme': 'light',
      'ls_locale': 'fa',
    });
    final service = await PersistenceService.initialize();
    final prefs = await SharedPreferences.getInstance();
    expect(service.getQuickSave(), QuickSaveMode.off);
    expect(prefs.getStringList('ls_favorites'), isNull);
    expect(prefs.getString('ls_color'), isNull);
    expect(prefs.getString('ls_theme'), isNull);
    expect(prefs.getString('ls_locale'), isNull);
  });

  test('Existing explicit settings remain user controlled', () async {
    SharedPreferences.setMockInitialValues({...seed(version: 3), 'ls_quick_save': 'off', 'ls_auto_finish': false, 'ls_receive_pin': '4321'});
    final service = await PersistenceService.initialize();
    expect(service.getQuickSave(), QuickSaveMode.off);
    expect(service.isAutoFinish(), isFalse);
    expect(service.getReceivePin(), '4321');
  });
}
