import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  final BluetoothDevice device;
  const DashboardScreen({super.key, required this.device});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // UUIDs ที่เรา "คาดว่า" ESP32 จะส่งมา (ตรวจสอบความถูกต้องจาก Log ที่ได้)
  // static const String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  // static const String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  // ตัวแปรเพื่อเช็คว่าเจอหรือไม่

    static const String serviceUUID = "2916f51f-3d75-4868-9214-396d9ebb82f1";
    static const String characteristicUUID = "09e6f548-20c3-48cf-8b5c-897a2f683cc3";

  StreamSubscription<List<int>>? _valueSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  @override
  void initState() {
    super.initState();
    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        debugPrint("Device disconnected unexpectedly.");
        _handleDisconnection();
      }
    });

    _discoverServicesAndSubscribe();
  }

  void _handleDisconnection() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection Lost'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Disconnected from ${widget.device.platformName}.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  // --- ฟังก์ชันที่แก้ไขเพื่อเพิ่มการ Debug ---
  void _discoverServicesAndSubscribe() async {
    try {
      debugPrint("Starting service discovery for ${widget.device.platformName}");
      List<BluetoothService> services = await widget.device.discoverServices();
      debugPrint("Found ${services.length} services.");

      // --- [DEBUG] ส่วนที่เพิ่มเข้ามา: พิมพ์ UUIDs ทั้งหมดที่เจอ ---
      debugPrint("--- Discovered Services and Characteristics ---");
      for (var s in services) {
        debugPrint("[INFO] Found Service: ${s.uuid.toString().toLowerCase()}");
        for (var c in s.characteristics) {
          debugPrint("  > Found Characteristic: ${c.uuid.toString().toLowerCase()}");
        }
      }
      debugPrint("---------------------------------------------");
      // --- สิ้นสุดส่วน Debug ---

      bool found = false; // ตัวแปรเพื่อเช็คว่าเจอหรือไม่
      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID) {
          debugPrint("✅ Matching Service Found: ${service.uuid}");
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() == characteristicUUID) {
              debugPrint("✅ Matching Characteristic Found: ${characteristic.uuid}");
              await characteristic.setNotifyValue(true);
              debugPrint("🟢 Subscribed to characteristic successfully!");

              _valueSubscription = characteristic.value.listen((value) {
                String data = utf8.decode(value);
                debugPrint(">> RAW DATA RECEIVED: $data");
                if (mounted) {
                  Provider.of<DashboardProvider>(context, listen: false).updateValue(data);
                }
              });
              found = true;
              break; 
            }
          }
        }
        if (found) break;
      }

      if (!found) {
        debugPrint("❌ ERROR: Did not find matching service/characteristic. Please check UUIDs.");
      }

    } catch (e) {
      debugPrint("🔴 EXCEPTION during discovery/subscription: $e");
    }
  }

  @override
  void dispose() {
    _valueSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    debugPrint("DashboardScreen disposed.");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint("Back button pressed. Disconnecting...");
        widget.device.disconnect();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.device.platformName),
          backgroundColor: Colors.black,
          actions: [
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              tooltip: 'Disconnect',
              onPressed: () {
                debugPrint("Manual disconnect pressed.");
                widget.device.disconnect();
                Navigator.of(context).pop();
              },
            )
          ],
        ),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSpeedGauge(provider.speed),
                const SizedBox(height: 20),
                _buildInfoGrid(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ... (ฟังก์ชัน _buildSpeedGauge, _buildInfoGrid, _buildInfoCard เหมือนเดิม ไม่ต้องแก้ไข) ...

  Widget _buildSpeedGauge(double speed) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 260,
          interval: 20,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.1,
            thicknessUnit: GaugeSizeUnit.factor,
            color: Colors.grey,
          ),
          majorTickStyle: const MajorTickStyle(length: 0.1, thickness: 2, lengthUnit: GaugeSizeUnit.factor),
          minorTickStyle: const MinorTickStyle(length: 0.05, thickness: 1.5, lengthUnit: GaugeSizeUnit.factor),
          axisLabelStyle: const GaugeTextStyle(fontSize: 12),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: speed,
              enableAnimation: true,
              animationDuration: 500,
              needleStartWidth: 1,
              needleEndWidth: 5,
              needleLength: 0.7,
              knobStyle: const KnobStyle(knobRadius: 0.08),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    speed.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text('km/h', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
              angle: 90,
              positionFactor: 0.5,
            )
          ],
        ),
      ],
    );
  }

  Widget _buildInfoGrid(DashboardProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildInfoCard("RPM", provider.techo.toString(), Icons.rotate_right),
        _buildInfoCard("Battery", "${provider.battery.toStringAsFixed(1)} V", Icons.battery_full),
        _buildInfoCard("Water Temp", "${provider.waterTemp.toStringAsFixed(0)} °C", Icons.thermostat),
        _buildInfoCard("AFR", provider.afr.toStringAsFixed(1), Icons.local_gas_station),
        _buildInfoCard("TPS", "${provider.tps.toStringAsFixed(0)} %", Icons.speed),
        _buildInfoCard("MAP", provider.mapValue.toStringAsFixed(0), Icons.compress),
        _buildInfoCard("Air Temp", "${provider.airTemp.toStringAsFixed(0)} °C", Icons.air),
        _buildInfoCard("Injection", provider.injection.toStringAsFixed(1), Icons.opacity),
      ],
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}