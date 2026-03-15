import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/bluetooth_controller.dart';

class EcuModelScreen extends StatefulWidget {
  const EcuModelScreen({super.key});

  @override
  State<EcuModelScreen> createState() => _EcuModelScreenState();
}

class _EcuModelScreenState extends State<EcuModelScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setLandscape();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setLandscape();
    }
  }

  void _setLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final btController = Get.find<BluetoothController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('ecu_model'.tr),
      ),
      body: Obx(() => Stack(
            children: [
              ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      btController.isEcuModelSynced.value
                          ? 'synced_with_dongle'.tr
                          : 'not_synced'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        color: btController.isEcuModelSynced.value
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ),
                  ...EcuModel.values.map((model) {
                    return RadioListTile<EcuModel>(
                      title: Text(model.description),
                      value: model,
                      groupValue: btController.currentEcuModel.value,
                      onChanged: btController.isSettingEcuModel.value
                          ? null
                          : (value) {
                              if (value != null) {
                                btController.setEcuModel(value);
                              }
                            },
                    );
                  }),
                ],
              ),
              if (btController.isSettingEcuModel.value)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'กำลังรอ ECU ตอบกลับ...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          )),
    );
  }
}
