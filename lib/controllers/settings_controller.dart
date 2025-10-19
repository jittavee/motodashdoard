import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TemperatureUnit { celsius, fahrenheit }
enum SpeedUnit { kmh, mph }
enum Language { thai, english }
enum DashboardTemplate { template1, template2, template3, template4, template5 }

class SettingsController extends GetxController {
  final Rx<TemperatureUnit> temperatureUnit = TemperatureUnit.celsius.obs;
  final Rx<SpeedUnit> speedUnit = SpeedUnit.kmh.obs;
  final Rx<Language> language = Language.thai.obs;
  final Rx<DashboardTemplate> dashboardTemplate = DashboardTemplate.template1.obs;
  final RxBool autoDayNightMode = false.obs;
  final RxBool isDarkMode = true.obs;

  static const String _tempUnitKey = 'temperature_unit';
  static const String _speedUnitKey = 'speed_unit';
  static const String _languageKey = 'language';
  static const String _dashboardTemplateKey = 'dashboard_template';
  static const String _autoDayNightKey = 'auto_day_night';
  static const String _darkModeKey = 'dark_mode';

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final tempUnit = prefs.getInt(_tempUnitKey) ?? 0;
    temperatureUnit.value = TemperatureUnit.values[tempUnit];

    final spdUnit = prefs.getInt(_speedUnitKey) ?? 0;
    speedUnit.value = SpeedUnit.values[spdUnit];

    final lang = prefs.getInt(_languageKey) ?? 0;
    language.value = Language.values[lang];

    final dashTemplate = prefs.getInt(_dashboardTemplateKey) ?? 0;
    dashboardTemplate.value = DashboardTemplate.values[dashTemplate];

    autoDayNightMode.value = prefs.getBool(_autoDayNightKey) ?? false;
    isDarkMode.value = prefs.getBool(_darkModeKey) ?? true;
  }

  Future<void> setTemperatureUnit(TemperatureUnit unit) async {
    temperatureUnit.value = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_tempUnitKey, unit.index);
  }

  Future<void> setSpeedUnit(SpeedUnit unit) async {
    speedUnit.value = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_speedUnitKey, unit.index);
  }

  Future<void> setLanguage(Language lang) async {
    language.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, lang.index);
  }

  Future<void> setDashboardTemplate(DashboardTemplate template) async {
    dashboardTemplate.value = template;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dashboardTemplateKey, template.index);
  }

  String getDashboardRoute() {
    switch (dashboardTemplate.value) {
      case DashboardTemplate.template1:
        return '/template-1';
      case DashboardTemplate.template2:
        return '/template-2';
      case DashboardTemplate.template3:
        return '/template-3';
      case DashboardTemplate.template4:
        return '/template-4';
      case DashboardTemplate.template5:
        return '/template-5';
    }
  }

  Future<void> setAutoDayNightMode(bool enabled) async {
    autoDayNightMode.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoDayNightKey, enabled);

    if (enabled) {
      // ตรวจสอบเวลาและเปลี่ยนโหมดอัตโนมัติ
      _checkTimeAndUpdateMode();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    isDarkMode.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  void _checkTimeAndUpdateMode() {
    final now = DateTime.now();
    final hour = now.hour;

    // กลางวัน: 6:00 - 18:00, กลางคืน: 18:00 - 6:00
    if (hour >= 6 && hour < 18) {
      isDarkMode.value = false;
    } else {
      isDarkMode.value = true;
    }
  }

  // แปลงค่าอุณหภูมิ
  double convertTemperature(double celsius) {
    if (temperatureUnit.value == TemperatureUnit.fahrenheit) {
      return (celsius * 9 / 5) + 32;
    }
    return celsius;
  }

  String getTemperatureUnit() {
    return temperatureUnit.value == TemperatureUnit.celsius ? '°C' : '°F';
  }

  // แปลงค่าความเร็ว
  double convertSpeed(double kmh) {
    if (speedUnit.value == SpeedUnit.mph) {
      return kmh * 0.621371;
    }
    return kmh;
  }

  String getSpeedUnit() {
    return speedUnit.value == SpeedUnit.kmh ? 'km/h' : 'mph';
  }

  // ดึงข้อความตามภาษา
  String getText(String thaiText, String englishText) {
    return language.value == Language.thai ? thaiText : englishText;
  }
}