import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/ecu_data_controller.dart';
import '../../models/alert_threshold.dart';

class AlertSettingsScreen extends StatefulWidget {
  const AlertSettingsScreen({super.key});

  @override
  State<AlertSettingsScreen> createState() => _AlertSettingsScreenState();
}

class _AlertSettingsScreenState extends State<AlertSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // บังคับให้หน้า Alert Settings เป็นแนวตั้งเท่านั้น
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    // คืนค่าให้รองรับทุกแนว
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ecuController = Get.find<ECUDataController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('alert_settings'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddAlertDialog(context, ecuController),
          ),
        ],
      ),
      body: Obx(() {
        if (ecuController.alertThresholds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'ยังไม่มีการตั้งค่าแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'กดปุ่ม + เพื่อเพิ่มการแจ้งเตือน',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ecuController.alertThresholds.length,
          itemBuilder: (context, index) {
            final threshold = ecuController.alertThresholds[index];
            return _buildAlertCard(context, threshold, ecuController);
          },
        );
      }),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    AlertThreshold threshold,
    ECUDataController controller,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getParameterIcon(threshold.parameter),
                  color: threshold.enabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getParameterName(threshold.parameter),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Range: ${threshold.minValue} - ${threshold.maxValue}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: threshold.enabled,
                  onChanged: (value) {
                    final updated = AlertThreshold(
                      id: threshold.id,
                      parameter: threshold.parameter,
                      minValue: threshold.minValue,
                      maxValue: threshold.maxValue,
                      enabled: value,
                      soundAlert: threshold.soundAlert,
                      popupAlert: threshold.popupAlert,
                    );
                    controller.updateAlertThreshold(updated);
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.volume_up, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Sound',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Checkbox(
                        value: threshold.soundAlert,
                        onChanged: (value) {
                          if (value != null) {
                            final updated = AlertThreshold(
                              id: threshold.id,
                              parameter: threshold.parameter,
                              minValue: threshold.minValue,
                              maxValue: threshold.maxValue,
                              enabled: threshold.enabled,
                              soundAlert: value,
                              popupAlert: threshold.popupAlert,
                            );
                            controller.updateAlertThreshold(updated);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.message, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Popup',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      Checkbox(
                        value: threshold.popupAlert,
                        onChanged: (value) {
                          if (value != null) {
                            final updated = AlertThreshold(
                              id: threshold.id,
                              parameter: threshold.parameter,
                              minValue: threshold.minValue,
                              maxValue: threshold.maxValue,
                              enabled: threshold.enabled,
                              soundAlert: threshold.soundAlert,
                              popupAlert: value,
                            );
                            controller.updateAlertThreshold(updated);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditAlertDialog(
                    context,
                    controller,
                    threshold,
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, controller, threshold),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAlertDialog(BuildContext context, ECUDataController controller) {
    String selectedParameter = 'rpm';
    double minValue = 0;
    double maxValue = 10000;
    bool soundAlert = true;
    bool popupAlert = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('เพิ่มการแจ้งเตือน'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('พารามิเตอร์'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedParameter,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'rpm', child: Text('RPM')),
                        DropdownMenuItem(value: 'waterTemp', child: Text('Water Temp')),
                        DropdownMenuItem(value: 'battery', child: Text('Battery')),
                        DropdownMenuItem(value: 'tps', child: Text('TPS')),
                        DropdownMenuItem(value: 'afr', child: Text('AFR')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedParameter = value;
                            _setDefaultValues(value, (min, max) {
                              minValue = min;
                              maxValue = max;
                            });
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('ค่าต่ำสุด'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: minValue.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        minValue = double.tryParse(value) ?? minValue;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('ค่าสูงสุด'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: maxValue.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        maxValue = double.tryParse(value) ?? maxValue;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('เสียงแจ้งเตือน'),
                      value: soundAlert,
                      onChanged: (value) {
                        setState(() {
                          soundAlert = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Popup แจ้งเตือน'),
                      value: popupAlert,
                      onChanged: (value) {
                        setState(() {
                          popupAlert = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final threshold = AlertThreshold(
                      parameter: selectedParameter,
                      minValue: minValue,
                      maxValue: maxValue,
                      enabled: true,
                      soundAlert: soundAlert,
                      popupAlert: popupAlert,
                    );
                    controller.addAlertThreshold(threshold);
                    Navigator.pop(context);
                  },
                  child: const Text('เพิ่ม'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditAlertDialog(
    BuildContext context,
    ECUDataController controller,
    AlertThreshold threshold,
  ) {
    double minValue = threshold.minValue;
    double maxValue = threshold.maxValue;
    bool soundAlert = threshold.soundAlert;
    bool popupAlert = threshold.popupAlert;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('แก้ไข ${_getParameterName(threshold.parameter)}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ค่าต่ำสุด'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: minValue.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        minValue = double.tryParse(value) ?? minValue;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('ค่าสูงสุด'),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: maxValue.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        maxValue = double.tryParse(value) ?? maxValue;
                      },
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('เสียงแจ้งเตือน'),
                      value: soundAlert,
                      onChanged: (value) {
                        setState(() {
                          soundAlert = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Popup แจ้งเตือน'),
                      value: popupAlert,
                      onChanged: (value) {
                        setState(() {
                          popupAlert = value ?? true;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updated = AlertThreshold(
                      id: threshold.id,
                      parameter: threshold.parameter,
                      minValue: minValue,
                      maxValue: maxValue,
                      enabled: threshold.enabled,
                      soundAlert: soundAlert,
                      popupAlert: popupAlert,
                    );
                    controller.updateAlertThreshold(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    ECUDataController controller,
    AlertThreshold threshold,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text(
            'คุณต้องการลบการแจ้งเตือนสำหรับ ${_getParameterName(threshold.parameter)} หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                if (threshold.id != null) {
                  controller.deleteAlertThreshold(threshold.id!);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  void _setDefaultValues(String parameter, Function(double, double) callback) {
    switch (parameter) {
      case 'rpm':
        callback(0, 10000);
        break;
      case 'waterTemp':
        callback(0, 120);
        break;
      case 'battery':
        callback(11, 15);
        break;
      case 'tps':
        callback(0, 100);
        break;
      case 'afr':
        callback(12, 16);
        break;
    }
  }

  String _getParameterName(String parameter) {
    switch (parameter) {
      case 'rpm':
        return 'RPM';
      case 'waterTemp':
        return 'Water Temperature';
      case 'battery':
        return 'Battery Voltage';
      case 'tps':
        return 'Throttle Position (TPS)';
      case 'afr':
        return 'Air-Fuel Ratio (AFR)';
      default:
        return parameter;
    }
  }

  IconData _getParameterIcon(String parameter) {
    switch (parameter) {
      case 'rpm':
        return Icons.speed;
      case 'waterTemp':
        return Icons.thermostat;
      case 'battery':
        return Icons.battery_full;
      case 'tps':
        return Icons.tune;
      case 'afr':
        return Icons.local_gas_station;
      default:
        return Icons.notifications;
    }
  }
}
