import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../services/permission_service.dart';
import '../utils/logger.dart';

class GpsSpeedController extends GetxController with WidgetsBindingObserver {
  final RxDouble gpsSpeed = 0.0.obs;
  final RxBool isGpsActive = false.obs;

  StreamSubscription<Position>? _positionSubscription;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  );

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _startListening();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopListening();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopListening();
    } else if (state == AppLifecycleState.resumed) {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_positionSubscription != null) return;

    final hasPermission =
        await PermissionService.instance.requestLocationPermissions();
    if (!hasPermission) {
      logger.w('GPS permission denied - speed will remain 0');
      return;
    }

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen(
      (Position position) {
        final speedKmh = (position.speed < 0) ? 0.0 : position.speed * 3.6;
        gpsSpeed.value = speedKmh;
        isGpsActive.value = true;
      },
      onError: (error) {
        logger.e('GPS stream error: $error');
        isGpsActive.value = false;
      },
    );
  }

  void _stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    isGpsActive.value = false;
  }
}
