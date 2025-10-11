import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends GetxController {
  // Observable for current locale
  final Rx<Locale> currentLocale = const Locale('th', 'TH').obs;

  // Available locales
  static const List<Locale> supportedLocales = [
    Locale('th', 'TH'),
    Locale('en', 'US'),
  ];

  // Language names for display
  static const Map<String, String> languageNames = {
    'th_TH': 'ไทย',
    'en_US': 'English',
  };

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'th';
      final countryCode = prefs.getString('country_code') ?? 'TH';

      final locale = Locale(languageCode, countryCode);
      currentLocale.value = locale;
      Get.updateLocale(locale);
    } catch (e) {
      // If error, use default (Thai)
      currentLocale.value = const Locale('th', 'TH');
    }
  }

  // Change language
  Future<void> changeLanguage(Locale locale) async {
    try {
      // Save to preferences first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');

      // Update locale
      currentLocale.value = locale;
      await Get.updateLocale(locale);

      // Force rebuild all GetX widgets
      Get.forceAppUpdate();

      // Show success message (delayed to show in new language)
      Future.delayed(const Duration(milliseconds: 100), () {
        Get.snackbar(
          'success'.tr,
          'language_changed'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      });
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'language_change_failed'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Switch between Thai and English
  Future<void> toggleLanguage() async {
    if (currentLocale.value.languageCode == 'th') {
      await changeLanguage(const Locale('en', 'US'));
    } else {
      await changeLanguage(const Locale('th', 'TH'));
    }
  }

  // Get current language name
  String get currentLanguageName {
    final localeKey = '${currentLocale.value.languageCode}_${currentLocale.value.countryCode}';
    return languageNames[localeKey] ?? 'ไทย';
  }

  // Check if current language is Thai
  bool get isThaiLanguage => currentLocale.value.languageCode == 'th';

  // Check if current language is English
  bool get isEnglishLanguage => currentLocale.value.languageCode == 'en';
}
