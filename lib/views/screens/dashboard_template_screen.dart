import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/settings_controller.dart';

class DashboardTemplateScreen extends StatefulWidget {
  const DashboardTemplateScreen({super.key});

  @override
  State<DashboardTemplateScreen> createState() =>
      _DashboardTemplateScreenState();
}

class _DashboardTemplateScreenState extends State<DashboardTemplateScreen>
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
    final settingsController = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard_template'.tr),
      ),
      body: Obx(() => ListView(
            children: [
              RadioListTile<DashboardTemplate>(
                title: Text('template_default'.tr),
                value: DashboardTemplate.template1,
                groupValue: settingsController.dashboardTemplate.value,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setDashboardTemplate(value);
                    Get.offAllNamed(settingsController.getDashboardRoute());
                  }
                },
              ),
              RadioListTile<DashboardTemplate>(
                title: Text('template_2'.tr),
                value: DashboardTemplate.template2,
                groupValue: settingsController.dashboardTemplate.value,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setDashboardTemplate(value);
                    Get.offAllNamed(settingsController.getDashboardRoute());
                  }
                },
              ),
              RadioListTile<DashboardTemplate>(
                title: Text('template_3'.tr),
                value: DashboardTemplate.template3,
                groupValue: settingsController.dashboardTemplate.value,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setDashboardTemplate(value);
                    Get.offAllNamed(settingsController.getDashboardRoute());
                  }
                },
              ),
              RadioListTile<DashboardTemplate>(
                title: Text('template_4'.tr),
                value: DashboardTemplate.template4,
                groupValue: settingsController.dashboardTemplate.value,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setDashboardTemplate(value);
                    Get.offAllNamed(settingsController.getDashboardRoute());
                  }
                },
              ),
              RadioListTile<DashboardTemplate>(
                title: Text('template_5'.tr),
                value: DashboardTemplate.template5,
                groupValue: settingsController.dashboardTemplate.value,
                onChanged: (value) {
                  if (value != null) {
                    settingsController.setDashboardTemplate(value);
                    Get.offAllNamed(settingsController.getDashboardRoute());
                  }
                },
              ),
            ],
          )),
    );
  }
}
