# รายละเอียดการส่งข้อมูลของ ESP32 ผ่าน BLE

## โครงสร้างข้อมูล

ESP32 จะส่งข้อมูลเป็นชุด และมีการหน่วงเวลา (delay) ระหว่างการส่ง **15 ms ต่อ Packet**

ตัวอย่างข้อมูลที่ส่ง:

| Byte No. | Parameter | Formula |
|---|---|---|
| 0 | (Header) | `0x41` (Symbol A) |
| 1 | Current EcuModel | `0x30`=model 0, `0x31`=model 1, `0x32`=model 2, `0x33`=model 3 |
| 2 | ECU status | `0x30`=Connected, `0x31`=No response, `0x32`=Connecting... |
| 3 | (Header2) | `0x42` (Symbol B) |
| 4 | TECHO-H | Output = (H\*256) + L |
| 5 | TECHO-L | |
| 6 | SPEED | Output = SPEED |
| 7 | WATER | Output = WATER - 40 |
| 8 | AIR.T | Output = AIR.T - 30 |
| 9 | MAP | Output = MAP |
| 10 | TPS | Output = TPS |
| 11 | BATT | Output = BATT / 10 |
| 12 | IGNITI-H | Output = ((H\*256) + L - 640) / 10.0 |
| 13 | IGNITI-L | |
| 14 | INJECT | Output = INJECT / 10 |
| 15 | AFR | Output = AFR / 10 |
| 16 | S.TRIM | Output = S.TRIM - 128 |
| 17 | L.TRIM | Output = L.TRIM - 128 |
| 18 | IACV | Output = IACV |
| 19 | (End Byte) | `0x00` |

### รายละเอียด packet

- ความยาวของข้อมูลต่อ 1 packet ไม่เกิน **20 Byte**
- ข้อมูลถูกส่งในรูปแบบ **int8bit**
- Packet จะถูกส่งออกโดยใช้ **BLE Notify**

---

## การรับข้อมูล เพื่อเลือก ECU Model

ส่งข้อมูลการเลือก ECU Model จากมือถือเป็น:

- `BLECharacteristic::PROPERTY_WRITE`
- ประเภทข้อมูลที่ส่งมาเป็น **TEXT** เช่น `model=0`

โดยพิมพ์ข้อความเพื่อเลือก ECU Model ดังนี้:

1. `model=0` คือการเลือก **SIMULATION**
2. `model=1` คือการเลือก **Under 150cc** (Wave125, Msx)
3. `model=2` คือการเลือก **Higher 150cc** (PCX)
4. `model=3` คือการเลือก **Giorno, Lead, Click, Wave110**

เมื่อ Dongle ได้รับข้อมูล EcuModel จากมือถือ จะทำการบันทึก EcuModel ลงในตัว Dongle อัตโนมัติ แล้วจะส่งข้อความตอบกลับเป็น `EcuModel` รวมไปกับ Packet ด้วย โดยไม่ต้องส่งข้อมูลการเลือก EcuModel มาบ่อยๆ

รวมถึงตอนเชื่อมต่อ BLE ตอนเปิดเครื่อง จะมีการส่งข้อความ `EcuModel` รวมไปกับ Packet ด้วยเช่นกัน

---

## การตั้งค่า BLE ในการส่งข้อมูล

| รายการ | ค่า |
|---|---|
| ชื่ออุปกรณ์ (Device Name) | `API Bluetooth Dongle` |
| โหมดการทำงาน | BLE Server |
| Service | `PROPERTY_NOTIFY` |
| Service UUID | `2916f51f-3d75-4868-9214-396d9ebb82f1` |
| Characteristic UUID | `09e6f548-20c3-48cf-8b5c-897a2f683cc3` |
| BLE Descriptor | `BLE2902` |

---

## การเปลี่ยนความเร็วส่งข้อมูล BLE

กดปุ่ม **[กลาง]** เพื่อเปลี่ยนความเร็วการส่งข้อมูล BLE มี 2 โหมด (BLE Transfer speed):

1. ส่งข้อมูล หน่วงเวลา **500 ms** / parameter
2. ส่งข้อมูล หน่วงเวลา **15 ms** / parameter

เมื่อกดปุ่มครบทั้ง 2 โหมดแล้ว จะวนกลับไปเริ่มโหมดที่ 1 ใหม่
