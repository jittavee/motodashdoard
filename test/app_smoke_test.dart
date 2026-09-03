@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:api_tech_moto/routes/app_pages.dart';
import 'package:api_tech_moto/routes/app_routes.dart';
import 'package:api_tech_moto/translations/app_translations.dart';

void main() {
  // MyApp ต้องการ controller ถาวรทั้งชุด (BLE, GPS, permission) จึง pump
  // ไม่ได้ใน unit test — เทสต์ config ที่ผูก route/i18n เข้า GetMaterialApp แทน
  group('route table', () {
    test('every declared route has a unique name', () {
      final names = AppPages.routes.map((page) => page.name).toList();
      expect(names.toSet().length, names.length,
          reason: 'duplicate route names silently shadow each other');
    });

    test('the initial route is registered', () {
      final names = AppPages.routes.map((page) => page.name).toSet();
      expect(names, contains(AppPages.initial));
    });

    test('every dashboard template route is registered', () {
      final names = AppPages.routes.map((page) => page.name).toSet();
      for (final route in [
        AppRoutes.template1, AppRoutes.template2, AppRoutes.template3,
        AppRoutes.template4, AppRoutes.template5,
      ]) {
        expect(names, contains(route), reason: '$route must be routable');
      }
    });

    test('every route name starts with a slash', () {
      for (final page in AppPages.routes) {
        expect(page.name, startsWith('/'), reason: page.name);
      }
    });
  });

  group('translations', () {
    final keys = AppTranslations().keys;

    test('ships both supported locales', () {
      expect(keys.keys.toSet(), {'th_TH', 'en_US'});
    });

    test('Thai and English define the same key set', () {
      final thai = keys['th_TH']!.keys.toSet();
      final english = keys['en_US']!.keys.toSet();

      // key ที่ขาดฝั่งใดฝั่งหนึ่งจะแสดงเป็น raw key บน UI
      expect(thai.difference(english), isEmpty,
          reason: 'keys missing from en_US');
      expect(english.difference(thai), isEmpty,
          reason: 'keys missing from th_TH');
    });

    test('no translation value is empty', () {
      for (final locale in keys.entries) {
        for (final entry in locale.value.entries) {
          expect(entry.value, isNotEmpty,
              reason: '${locale.key}: "${entry.key}" is empty');
        }
      }
    });
  });
}
