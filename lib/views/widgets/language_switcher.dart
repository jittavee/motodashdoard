import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/language_controller.dart';

/// Widget สำหรับสลับภาษา - ใช้งานง่ายแค่เรียก LanguageSwitcher()
class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(
      () => IconButton(
        icon: const Icon(Icons.language),
        tooltip: 'language'.tr,
        onPressed: () => _showLanguageDialog(context, languageController),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text('thai'.tr),
              value: const Locale('th', 'TH'),
              groupValue: controller.currentLocale.value,
              onChanged: (locale) {
                if (locale != null) {
                  controller.changeLanguage(locale);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: Text('english'.tr),
              value: const Locale('en', 'US'),
              groupValue: controller.currentLocale.value,
              onChanged: (locale) {
                if (locale != null) {
                  controller.changeLanguage(locale);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget แบบ ListTile สำหรับหน้า Settings
class LanguageSettingTile extends StatelessWidget {
  const LanguageSettingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(
      () => ListTile(
        leading: const Icon(Icons.language),
        title: Text('language'.tr),
        subtitle: Text(languageController.currentLanguageName),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showLanguageDialog(context, languageController),
      ),
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    LanguageController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('language'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale>(
              title: Text('thai'.tr),
              value: const Locale('th', 'TH'),
              groupValue: controller.currentLocale.value,
              onChanged: (locale) {
                if (locale != null) {
                  controller.changeLanguage(locale);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<Locale>(
              title: Text('english'.tr),
              value: const Locale('en', 'US'),
              groupValue: controller.currentLocale.value,
              onChanged: (locale) {
                if (locale != null) {
                  controller.changeLanguage(locale);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget แบบ Toggle Switch สำหรับสลับไทย-อังกฤษอย่างรวดเร็ว
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(
      () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TH',
            style: TextStyle(
              fontWeight: languageController.isThaiLanguage
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          Switch(
            value: languageController.isEnglishLanguage,
            onChanged: (_) => languageController.toggleLanguage(),
          ),
          Text(
            'EN',
            style: TextStyle(
              fontWeight: languageController.isEnglishLanguage
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
