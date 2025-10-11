# ECU Gauge Application

แอปพลิเคชัน ECU Gauge สำหรับแสดงข้อมูลจากกล่อง ECU แบบ Real-time ผ่าน Bluetooth

## คุณสมบัติหลัก

### 1. การเชื่อมต่อ Bluetooth
- ค้นหาและเชื่อมต่อกับกล่อง ECU ผ่าน Bluetooth
- แสดงสถานะการเชื่อมต่อแบบ Real-time
- รองรับการเชื่อมต่ออัตโนมัติ

### 2. Dashboard แสดงข้อมูล
- แสดงค่า RPM, Speed, Temperature, TPS, AFR และอื่นๆ
- Gauge แบบ Analog สำหรับ RPM และ Speed
- Info Cards สำหรับข้อมูลเพิ่มเติม
- รองรับทั้งแนวตั้งและแนวนอน (Portrait & Landscape)

### 3. Theme (3 แบบ)
- **Classic** - โทนสีทอง/น้ำตาล (คลาสสิค)
- **Sport** - โทนสีแดง/ดำ (สปอร์ต)
- **Digital** - โทนสีฟ้า/ขาว (ดิจิทัล)
- เปลี่ยน Theme ได้ทันทีโดยไม่ต้องรีสตาร์ทแอป

### 4. Settings
- เลือกหน่วยวัดอุณหภูมิ (°C / °F)
- เลือกหน่วยวัดความเร็ว (km/h / mph)
- เลือกภาษา (ไทย / English)
- โหมดกลางวัน/กลางคืนอัตโนมัติ

### 5. Smart Alerts
- ตั้งค่าขีดจำกัดสำหรับแต่ละพารามิเตอร์
- แจ้งเตือนด้วยเสียง, popup, และไฟกระพริบ
- ป้องกันความเสียหายของเครื่องยนต์

### 6. Performance Test
- จับเวลา 0-100ม., 201ม., 402ม., 1000ม.
- ใช้ GPS หรือความเร็วจาก ECU
- บันทึกผลการทดสอบไว้เปรียบเทียบ

### 7. Data Logging
- บันทึกข้อมูลการขับขี่
- Export เป็น CSV หรือ JSON
- ดูกราฟย้อนหลัง

## โครงสร้างโปรเจค

```
lib/
├── constants/           # ค่าคงที่และ Themes
│   └── app_themes.dart
├── controllers/         # State Management (GetX)
│   ├── bluetooth_controller.dart
│   ├── ecu_data_controller.dart
│   ├── theme_controller.dart
│   ├── settings_controller.dart
│   └── performance_test_controller.dart
├── models/             # Data Models
│   ├── ecu_data.dart
│   ├── alert_threshold.dart
│   └── performance_test.dart
├── services/           # Services (Database, etc.)
│   └── database_helper.dart
├── views/
│   ├── screens/        # หน้าจอต่างๆ
│   │   ├── dashboard_screen.dart
│   │   ├── bluetooth_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/        # Widget ต่างๆ
│       ├── rpm_gauge.dart
│       ├── speed_gauge.dart
│       └── info_card.dart
└── main.dart
```

## การติดตั้ง

1. Clone โปรเจค
```bash
git clone <repository-url>
cd api_tech_moto
```

2. ติดตั้ง dependencies
```bash
flutter pub get
```

3. รันแอป
```bash
flutter run
```

## Dependencies หลัก

- **get**: State Management
- **flutter_blue_plus**: Bluetooth connectivity
- **sqflite**: Local database
- **syncfusion_flutter_gauges**: Gauge widgets
- **fl_chart**: Charts and graphs
- **geolocator**: GPS/Location
- **shared_preferences**: Settings storage

## รูปแบบข้อมูลจาก ECU

แอปรองรับข้อมูลในรูปแบบ:
```
TECHO=15000,SPEED=255,WATER=150,AIR.T=100,MAP=200,TPS=100,BATT=13.5,IGNITI=75.0,INJECT=20.0,AFR=14.7,S.TRIM=100,L.TRIM=100,IACV=100
```

## การตั้งค่า Permission

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Need Bluetooth to connect to ECU</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Need Location for performance test</string>
```

## การทดสอบ

สำหรับการทดสอบโดยไม่มีกล่อง ECU:
1. เปิดแอป
2. กดปุ่ม "สร้างข้อมูลทดสอบ" บนหน้า Dashboard
3. แอปจะสร้างข้อมูล dummy ทุก 1 วินาที เป็นเวลา 30 วินาที

## License

MIT License

## Author

Created for ECU monitoring and diagnostics
