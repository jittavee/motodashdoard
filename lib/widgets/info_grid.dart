import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/sensor_data.dart';
import 'info_card.dart';

class InfoGrid extends StatelessWidget {
  final SensorData sensorData;

  const InfoGrid({
    super.key,
    required this.sensorData,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: AppConstants.gridChildAspectRatio,
      crossAxisSpacing: AppConstants.gridSpacing,
      mainAxisSpacing: AppConstants.gridSpacing,
      children: [
        InfoCard(
          title: AppStrings.rpmLabel,
          value: sensorData.techo.toString(),
          icon: Icons.rotate_right,
        ),
        InfoCard(
          title: AppStrings.batteryLabel,
          value: "${sensorData.battery.toStringAsFixed(1)} ${AppStrings.voltageUnit}",
          icon: Icons.battery_full,
        ),
        InfoCard(
          title: AppStrings.waterTempLabel,
          value: "${sensorData.waterTemp.toStringAsFixed(0)} ${AppStrings.temperatureUnit}",
          icon: Icons.thermostat,
        ),
        InfoCard(
          title: AppStrings.afrLabel,
          value: sensorData.afr.toStringAsFixed(1),
          icon: Icons.local_gas_station,
        ),
        InfoCard(
          title: AppStrings.tpsLabel,
          value: "${sensorData.tps.toStringAsFixed(0)} ${AppStrings.percentageUnit}",
          icon: Icons.speed,
        ),
        InfoCard(
          title: AppStrings.mapLabel,
          value: sensorData.mapValue.toStringAsFixed(0),
          icon: Icons.compress,
        ),
        InfoCard(
          title: AppStrings.airTempLabel,
          value: "${sensorData.airTemp.toStringAsFixed(0)} ${AppStrings.temperatureUnit}",
          icon: Icons.air,
        ),
        InfoCard(
          title: AppStrings.injectionLabel,
          value: sensorData.injection.toStringAsFixed(1),
          icon: Icons.opacity,
        ),
      ],
    );
  }
}