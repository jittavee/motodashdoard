import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_themes.dart';

class ThemeController extends GetxController {
  final Rx<ThemeType> currentTheme = ThemeType.digital.obs;

  static const String _themeKey = 'selected_theme';

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 2; // default: digital
    currentTheme.value = ThemeType.values[themeIndex];
  }

  Future<void> changeTheme(ThemeType theme) async {
    currentTheme.value = theme;

    // บันทึกลง SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);

    // อัปเดต theme ของ GetMaterialApp
    Get.changeTheme(AppThemes.getTheme(theme));
  }

  String getThemeName(ThemeType theme) {
    switch (theme) {
      case ThemeType.classic:
        return 'คลาสสิค';
      case ThemeType.sport:
        return 'สปอร์ต';
      case ThemeType.digital:
        return 'ดิจิทัล';
    }
  }
}