import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../constants/app_themes.dart';

class SpeedGauge extends StatelessWidget {
  final double value;
  final ThemeType theme;
  final String unit;

  const SpeedGauge({
    Key? key,
    required this.value,
    required this.theme,
    this.unit = 'km/h',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      axes: <RadialAxis>[
        RadialAxis(
          minimum: 0,
          maximum: 250,
          interval: 25,
          minorTicksPerInterval: 5,
          axisLineStyle: AxisLineStyle(
            thickness: 0.15,
            thicknessUnit: GaugeSizeUnit.factor,
            color: AppThemes.getGaugeBackgroundColor(theme),
          ),
          majorTickStyle: MajorTickStyle(
            length: 0.15,
            lengthUnit: GaugeSizeUnit.factor,
            color: AppThemes.getGaugeColor(theme),
            thickness: 2,
          ),
          minorTickStyle: MinorTickStyle(
            length: 0.08,
            lengthUnit: GaugeSizeUnit.factor,
            color: AppThemes.getGaugeColor(theme).withOpacity(0.5),
          ),
          axisLabelStyle: GaugeTextStyle(
            color: AppThemes.getTextColor(theme),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          pointers: <GaugePointer>[
            NeedlePointer(
              value: value,
              needleColor: AppThemes.getGaugeColor(theme),
              needleStartWidth: 0,
              needleEndWidth: 5,
              needleLength: 0.7,
              knobStyle: KnobStyle(
                color: AppThemes.getGaugeColor(theme),
                borderColor: AppThemes.getTextColor(theme),
                borderWidth: 0.03,
                knobRadius: 0.08,
              ),
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppThemes.getTextColor(theme),
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemes.getTextColor(theme).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              angle: 90,
              positionFactor: 0.5,
            ),
          ],
        ),
      ],
    );
  }
}