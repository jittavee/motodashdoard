# ECU Gauge (api_tech_moto)

แอป Flutter แสดงข้อมูลจากกล่อง ECU มอเตอร์ไซค์แบบ Real-time ผ่าน BLE dongle พร้อมบันทึกข้อมูล จับเวลาอัตราเร่ง และแจ้งเตือนเมื่อค่าเกินขีดจำกัด

UI เป็นภาษาไทยเป็นหลัก (locale สำรอง `th_TH`) และล็อคแนวนอน (landscape) ตลอดการใช้งาน

## คุณสมบัติหลัก

### 1. การเชื่อมต่อ BLE
- สแกนและเชื่อมต่อ ECU dongle ผ่าน `flutter_blue_plus` ที่ service/characteristic UUID ที่กำหนดไว้
- แสดงสถานะสองชั้นแยกกัน: แอป ↔ dongle และ dongle ↔ ECU ของรถ
- รองรับเชื่อมต่ออัตโนมัติกับอุปกรณ์ที่เคยใช้

### 2. เลือก ECU Model
Dongle รองรับ ECU หลายรุ่น เลือกได้จากหน้า ECU Model:

| ค่า | รุ่น |
|---|---|
| 0 | Simulation |
| 1 | Under 150cc (Wave125, Msx) |
| 2 | Higher 150cc (PCX) |
| 3 | Giorno, Lead, Click, Wave110 |

รุ่นที่เลือกล่าสุดถูกจำไว้ใน `SharedPreferences` และส่งกลับให้ dongle อัตโนมัติหลังเชื่อมต่อ

### 3. Dashboard 5 แบบ
เลือกเลย์เอาต์ได้จากหน้า Dashboard Template (`template1`..`template5`) แต่ละแบบใช้ gauge ชุดเดียวกันแต่จัดวางต่างกัน แสดง RPM, Speed, ECT, IAT, MAP, TPS, BATT, IGN, INJ, AFR, S.TRIM, L.TRIM, IACV

### 4. Theme
- **Classic** — โทนทอง/น้ำตาล
- **Sport** — โทนแดง/ดำ
- **Digital** — โทนฟ้า/ขาว

เปลี่ยนได้ทันทีไม่ต้องรีสตาร์ท เลือกธีมกับเลือกเลย์เอาต์ dashboard เป็นสองแกนแยกกัน

### 5. Settings
- หน่วยอุณหภูมิ (°C / °F) และความเร็ว (km/h / mph)
- ภาษา (ไทย / English)
- โหมดสว่าง/มืด และสลับกลางวัน-กลางคืนอัตโนมัติ
- ความหนืดการเคลื่อนของเข็มเกจ (`needleLerpSpeed`)

### 6. Smart Alerts
ตั้งค่า min/max ต่อพารามิเตอร์ เมื่อค่าหลุดช่วงจะแจ้งเตือนด้วยเสียง (`assets/sounds/alert.wav`) เกณฑ์เก็บในตาราง `alert_thresholds`

### 7. Performance Test
จับเวลา 0-100 ม., 201 ม., 402 ม., 1000 ม. โดยใช้ความเร็วจาก GPS หรือจาก ECU บันทึกผลไว้เปรียบเทียบย้อนหลัง

### 8. Data Logging และ Playback
- บันทึกค่าลงตาราง `ecu_logs` ทุก 1 วินาทีขณะเปิดโหมดบันทึก
- Export เป็น CSV หรือ JSON
- ดูกราฟย้อนหลัง และเล่นซ้ำ (playback) ผ่าน dashboard ตัวเดิม — widget ไม่ต้องรู้ว่าข้อมูลมาจากสดหรือจากล็อก

## โครงสร้างโปรเจค

```
lib/
├── config/                 # ค่าคอนฟิกรวม
├── constants/              # สี ขนาด และ Themes
├── controllers/            # State management (GetX)
│   ├── bluetooth_controller.dart      # BLE scan/connect, ECU model handshake
│   ├── ecu_data_controller.dart       # parse, throttle, alert, logging, playback
│   ├── gps_speed_controller.dart
│   ├── performance_test_controller.dart
│   ├── settings_controller.dart
│   ├── theme_controller.dart
│   └── language_controller.dart
├── models/                 # ecu_data, alert_threshold, performance_test
├── routes/                 # app_routes (ชื่อ route) + app_pages (GetPage)
├── services/
│   ├── database_helper.dart           # sqflite singleton + migrations
│   ├── permission_service.dart
│   └── alert_sound_player.dart
├── translations/           # th_th, en_us, app_translations
├── utils/                  # pure logic แยกจาก controller เพื่อเทสต์ได้
│   ├── ecu_parser.dart                # parse "KEY=VALUE" + range check
│   ├── ecu_packet_decoder.dart        # decode binary packet 20 ไบต์
│   ├── dongle_message.dart            # แยกประเภทข้อความจาก dongle
│   ├── debug_data_generator.dart
│   ├── formatters.dart / validators.dart / logger.dart
├── views/
│   ├── screens/
│   │   ├── dashboard/dashboard_1..5   # 5 เลย์เอาต์
│   │   ├── dashboard_template_screen.dart
│   │   ├── bluetooth_screen.dart / ecu_model_screen.dart
│   │   ├── settings_screen.dart / alert_settings_screen.dart
│   │   ├── data_log_screen.dart / data_log_chart_screen.dart
│   │   ├── performance_test_screen_v2.dart
│   │   └── splash_screen.dart
│   └── widgets/                       # gauge และ indicator ที่ dashboard ใช้ร่วมกัน
└── main.dart               # DI ทุก controller ก่อน runApp
```

## การติดตั้ง

โปรเจคใช้ FVM (Flutter Version Management) — `.fvmrc` pin Flutter `3.32.7` ใช้ `fvm flutter` แทน `flutter` เปล่าเพื่อให้ได้ SDK เวอร์ชันที่ pin ไว้

```bash
git clone <repository-url>
cd api_tech_moto
fvm flutter pub get
fvm flutter run
```

## คำสั่งที่ใช้บ่อย

```bash
fvm flutter pub get                 # ติดตั้ง dependencies
fvm flutter run                     # รันบนเครื่อง/emulator ที่ต่ออยู่
fvm flutter analyze                 # static analysis (flutter_lints)
fvm flutter test                    # รันเทสต์ทั้งหมด
fvm flutter build apk --release     # build release APK
```

รันเทสต์เฉพาะไฟล์หรือเฉพาะชื่อ:

```bash
fvm flutter test test/utils/ecu_parser_test.dart
fvm flutter test --plain-name "should reject empty data"
```

## Dependencies หลัก

| Package | ใช้ทำอะไร |
|---|---|
| `get` | State management, routing, DI, i18n |
| `flutter_blue_plus` | BLE |
| `permission_handler` | ขอ permission ตอนรันไทม์ |
| `sqflite` | ฐานข้อมูลในเครื่อง |
| `syncfusion_flutter_gauges` | Gauge widgets |
| `fl_chart` | กราฟย้อนหลัง |
| `geolocator` | GPS สำหรับ performance test |
| `csv` / `share_plus` | Export และแชร์ไฟล์ |
| `audioplayers` | เสียงแจ้งเตือน |
| `shared_preferences` | เก็บ settings |
| `logger` | Console log |

## รูปแบบข้อมูลจาก ECU

Dongle ส่งข้อมูลได้สองรูปแบบบน characteristic เดียวกัน

### Text mode — หนึ่งพารามิเตอร์ต่อ notification

ส่งทีละตัว ห่างกันประมาณ 15 ms ครบรอบ 13 ตัว:

```
TECHO=3500
SPEED=62
WATER=88
```

Key ที่รองรับ: `TECHO, SPEED, WATER, AIR.T, MAP, TPS, BATT, IGNITI, INJECT, AFR, S.TRIM, L.TRIM, IACV`

Dongle ยังส่งข้อความที่ไม่ใช่ค่าเกจมาบนช่องเดียวกัน — `EcuModel=N` (ACK การเลือกรุ่น ECU), `ECU=Connected|No_response|Connecting...` (สถานะลิงก์ dongle ↔ ECU) และ echo ของคำสั่งที่แอปส่งไปเอง (เช่น `model=N` ซึ่งถูกกรองทิ้ง)

### Binary mode — 20 ไบต์ต่อ packet

```
byte0     = 0x41 'A'   header
byte1      = EcuModel   ASCII '0'..'3'
byte2      = ECU status ASCII '0'=Connected 1=No_response 2=Connecting
byte3      = 0x42 'B'   header2
byte4-18   = ค่าเซนเซอร์ 13 ตัว
byte19     = 0x00       end
```

ทุกค่ามี scaling ของตัวเอง เช่น RPM = `b4*256+b5`, WATER = `b7-40`, BATT = `b11/10` ดูทั้งหมดที่ [lib/utils/ecu_packet_decoder.dart](lib/utils/ecu_packet_decoder.dart)

ค่าที่ parse ได้จะถูก range check กัน noise จาก BLE ทำให้เกจกระโดด แล้ว throttle การอัพเดต UI ที่ ~20fps (50 ms) โดย RPM มี buffer 1000 ms เพิ่มอีกชั้นเพื่อให้เข็มเดินนิ่ง

## การตั้งค่า Permission

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need Bluetooth to connect to ECU</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Need Location for performance test</string>
```

## การทดสอบ

เทสต์อยู่ใน `test/` ครอบทั้ง pure logic และ controller:

```
test/
├── utils/ecu_parser_test.dart              # parse + range check
├── utils/ecu_packet_decoder_test.dart      # byte offset + scaling
├── utils/dongle_message_test.dart          # แยกประเภทข้อความ
├── controllers/ecu_data_controller_test.dart
├── controllers/bluetooth_controller_test.dart
├── controllers/performance_test_controller_test.dart
├── services/database_migration_test.dart
├── helpers/fakes.dart
└── app_smoke_test.dart
```

Controller test สร้าง controller ตรงๆ ด้วย `Get.testMode = true` และเรียก `Get.reset()` ใน `tearDown` แทนการ pump widget tree ทั้งต้น — ดู `ecu_data_controller_test.dart` เป็นตัวอย่างอ้างอิง

ทดสอบโดยไม่มีกล่อง ECU: เลือก ECU Model เป็น `0` (Simulation) แล้ว dongle จะส่งค่าจำลองมาให้ หรือใช้ `DebugDataGenerator` ใน [lib/utils/debug_data_generator.dart](lib/utils/debug_data_generator.dart) เพื่อป้อนค่า dummy เข้า `ECUDataController` ตรงๆ

## License

MIT License

## Author

Created for ECU monitoring and diagnostics
