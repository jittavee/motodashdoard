import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../core/constants.dart';

class SpeedGauge extends StatelessWidget {
  final double speed;

  const SpeedGauge({
    super.key,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: AppConstants.speedGaugeMinimum,
          maximum: AppConstants.speedGaugeMaximum,
          interval: AppConstants.speedGaugeInterval,
          axisLineStyle: const AxisLineStyle(
            thickness: AppConstants.gaugeAxisLineThickness,
            thicknessUnit: GaugeSizeUnit.factor,
            color: Colors.grey,
          ),
          majorTickStyle: const MajorTickStyle(
            length: AppConstants.gaugeMajorTickLength,
            thickness: 2,
            lengthUnit: GaugeSizeUnit.factor,
          ),
          minorTickStyle: const MinorTickStyle(
            length: AppConstants.gaugeMinorTickLength,
            thickness: 1.5,
            lengthUnit: GaugeSizeUnit.factor,
          ),
          axisLabelStyle: const GaugeTextStyle(fontSize: 12),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: speed,
              enableAnimation: true,
              animationDuration: AppConstants.animationDurationMs,
              needleStartWidth: 1,
              needleEndWidth: 5,
              needleLength: AppConstants.gaugeNeedleLength,
              knobStyle: const KnobStyle(knobRadius: AppConstants.gaugeKnobRadius),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    speed.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    AppStrings.speedUnit,
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
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
}