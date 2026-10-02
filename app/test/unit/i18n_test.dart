import 'package:flutter/widgets.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:test/test.dart';

void main() {
  test('Only English is bundled and supported', () {
    expect(AppLocale.values, [AppLocale.en]);
    expect(AppLocaleUtils.supportedLocales, [const Locale('en')]);
    expect(AppLocale.en.translations.general.accept, 'Accept');
  });
}
