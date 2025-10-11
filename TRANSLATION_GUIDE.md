# คู่มือการใช้ระบบหลายภาษา (Translation Guide)

## ภาพรวม (Overview)

โปรเจกต์นี้ใช้ระบบ Internationalization (i18n) ของ GetX เพื่อรองรับภาษาไทยและอังกฤษ

## โครงสร้างไฟล์ (File Structure)

```
lib/
├── translations/
│   ├── th_th.dart         # คำแปลภาษาไทย
│   ├── en_us.dart         # คำแปลภาษาอังกฤษ
│   └── app_translations.dart  # จัดการคำแปลทั้งหมด
└── controllers/
    └── language_controller.dart  # ควบคุมการเปลี่ยนภาษา
```

## วิธีใช้งาน (Usage)

### 1. แสดงข้อความที่แปลภาษาได้

แทนที่การใช้:
```dart
Text('Alert Settings')
```

ด้วย:
```dart
Text('alert_settings'.tr)
```

### 2. ตัวอย่างในไฟล์ต่างๆ

#### ตัวอย่างที่ 1: AppBar
```dart
AppBar(
  title: Text('settings'.tr),
)
```

#### ตัวอย่างที่ 2: Button
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr),
)
```

#### ตัวอย่างที่ 3: Dialog
```dart
AlertDialog(
  title: Text('confirm'.tr),
  content: Text('confirm_clear'.tr),
  actions: [
    TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('cancel'.tr),
    ),
    ElevatedButton(
      onPressed: () {
        // ทำงาน
      },
      child: Text('ok'.tr),
    ),
  ],
)
```

### 3. เปลี่ยนภาษาใน UI

```dart
import '../../controllers/language_controller.dart';

// ในหน้า Settings
final langController = Get.find<LanguageController>();

// แสดงปุ่มเปลี่ยนภาษา
ListTile(
  leading: const Icon(Icons.language),
  title: Text('language'.tr),
  subtitle: Text(langController.currentLanguageName),
  onTap: () => _showLanguagePicker(context),
)

// ฟังก์ชันแสดง Dialog เลือกภาษา
void _showLanguagePicker(BuildContext context) {
  final langController = Get.find<LanguageController>();

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
            groupValue: langController.currentLocale.value,
            onChanged: (locale) {
              if (locale != null) {
                langController.changeLanguage(locale);
                Navigator.pop(context);
              }
            },
          ),
          RadioListTile<Locale>(
            title: Text('english'.tr),
            value: const Locale('en', 'US'),
            groupValue: langController.currentLocale.value,
            onChanged: (locale) {
              if (locale != null) {
                langController.changeLanguage(locale);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    ),
  );
}

// หรือใช้ Toggle ง่ายๆ
IconButton(
  icon: const Icon(Icons.language),
  onPressed: () => langController.toggleLanguage(),
)
```

### 4. เพิ่มคำแปลใหม่

#### ในไฟล์ `lib/translations/th_th.dart`:
```dart
const Map<String, String> thTh = {
  // เพิ่มคำแปลใหม่ที่นี่
  'your_new_key': 'ข้อความภาษาไทย',
};
```

#### ในไฟล์ `lib/translations/en_us.dart`:
```dart
const Map<String, String> enUs = {
  // เพิ่มคำแปลใหม่ที่นี่
  'your_new_key': 'English Text',
};
```

## คำแปลที่มีอยู่แล้ว (Available Translations)

### ทั่วไป (General)
- `app_name` - ชื่อแอป
- `loading` - กำลังโหลด
- `save` - บันทึก
- `cancel` - ยกเลิก
- `delete` - ลบ
- `edit` - แก้ไข
- `confirm` - ยืนยัน
- `ok` - ตกลง
- `yes` - ใช่
- `no` - ไม่

### Dashboard
- `dashboard` - แดชบอร์ด
- `rpm` - รอบเครื่องยนต์
- `speed` - ความเร็ว
- `km_h` - กม./ชม.
- `engine_temp` - อุณหภูมิเครื่องยนต์
- `fuel` - เชื้อเพลิง
- `voltage` - แรงดันไฟ
- `throttle` - เปิดสูบ
- `gear` - เกียร์

### Bluetooth
- `bluetooth` - บลูทูธ
- `scan_devices` - ค้นหาอุปกรณ์
- `connect` - เชื่อมต่อ
- `disconnect` - ตัดการเชื่อมต่อ
- `connecting` - กำลังเชื่อมต่อ

### Settings
- `settings` - ตั้งค่า
- `theme` - ธีม
- `language` - ภาษา
- `thai` - ไทย
- `english` - อังกฤษ

### Alert Settings
- `alert_settings` - ตั้งค่าการแจ้งเตือน
- `rpm_limit` - ขีดจำกัดรอบเครื่องยนต์
- `speed_limit` - ขีดจำกัดความเร็ว
- `temp_limit` - ขีดจำกัดอุณหภูมิ
- `enable_alerts` - เปิดใช้การแจ้งเตือน
- `alert_sound` - เสียงแจ้งเตือน
- `alert_vibration` - สั่นเตือน

## API ของ LanguageController

```dart
final langController = Get.find<LanguageController>();

// เปลี่ยนภาษา
await langController.changeLanguage(Locale('en', 'US'));

// สลับภาษาไทย-อังกฤษ
await langController.toggleLanguage();

// ดึงชื่อภาษาปัจจุบัน
String name = langController.currentLanguageName; // 'ไทย' หรือ 'English'

// เช็คภาษาปัจจุบัน
bool isThaiLanguage = langController.isThaiLanguage;
bool isEnglishLanguage = langController.isEnglishLanguage;

// ดึง Locale ปัจจุบัน
Locale current = langController.currentLocale.value;
```

## ข้อควรระวัง (Important Notes)

1. **ต้องมีคีย์เดียวกันในทุกภาษา** - ถ้าเพิ่มคำแปลใหม่ใน `th_th.dart` ต้องเพิ่มใน `en_us.dart` ด้วย
2. **ใช้ `.tr` กับ String** - `'key'.tr` จะแปลงเป็นคำแปลตามภาษาปัจจุบัน
3. **Fallback เป็นภาษาไทย** - ถ้าไม่พบคำแปล จะใช้ภาษาไทยเป็นค่าเริ่มต้น
4. **บันทึกอัตโนมัติ** - ภาษาที่เลือกจะถูกบันทึกลง SharedPreferences อัตโนมัติ

## ตัวอย่างการแปลงหน้าเดิมให้รองรับหลายภาษา

### Before:
```dart
AppBar(
  title: const Text('Alert Settings'),
)

ElevatedButton(
  onPressed: () {},
  child: const Text('บันทึก'),
)
```

### After:
```dart
AppBar(
  title: Text('alert_settings'.tr),
)

ElevatedButton(
  onPressed: () {},
  child: Text('save'.tr),
)
```

## การทดสอบ (Testing)

1. รันแอป
2. ไปที่หน้า Settings
3. กดเปลี่ยนภาษา
4. ตรวจสอบว่าข้อความทั้งหมดเปลี่ยนตามภาษาที่เลือก

---

สร้างโดย: GetX Internationalization
อัปเดตล่าสุด: 2025
