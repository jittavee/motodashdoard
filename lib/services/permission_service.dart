import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/logger.dart';

class PermissionService extends GetxService {
  // Singleton pattern
  static PermissionService get instance => Get.find<PermissionService>();

  // Permission status observables
  final RxBool hasBluetoothPermission = false.obs;
  final RxBool hasLocationPermission = false.obs;
  final RxBool isLocationServiceEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAllPermissions();
  }

  // Check all permissions at once (เช็คแค่ Bluetooth ตอน init)
  Future<void> checkAllPermissions() async {
    await checkBluetoothPermissions();
  }

  // Bluetooth Permissions
  Future<bool> checkBluetoothPermissions() async {
    try {
      if (GetPlatform.isAndroid) {
        // Android 12+ requires multiple permissions
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        final allGranted = statuses.values.every(
          (status) => status.isGranted,
        );

        hasBluetoothPermission.value = allGranted;
        return allGranted;
      } else if (GetPlatform.isIOS) {
        final status = await Permission.bluetooth.request();
        hasBluetoothPermission.value = status.isGranted;
        return status.isGranted;
      }

      return false;
    } catch (e) {
      logger.e('Error checking Bluetooth permissions', error: e);
      return false;
    }
  }

  Future<bool> requestBluetoothPermissions() async {
    try {
      if (GetPlatform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();

        final allGranted = statuses.values.every(
          (status) => status.isGranted || status.isLimited,
        );

        hasBluetoothPermission.value = allGranted;

        if (!allGranted) {
          _showPermissionDeniedDialog('Bluetooth');
        }

        return allGranted;
      } else if (GetPlatform.isIOS) {
        final status = await Permission.bluetooth.request();
        hasBluetoothPermission.value = status.isGranted;

        if (!status.isGranted) {
          _showPermissionDeniedDialog('Bluetooth');
        }

        return status.isGranted;
      }

      return false;
    } catch (e) {
      logger.e('Error requesting Bluetooth permissions', error: e);
      return false;
    }
  }

  // Open app settings
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // Location Permissions (ไม่เรียกตอน init แต่ให้เรียกตอนต้องการใช้งาน)
  Future<bool> checkLocationPermissions() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isLocationServiceEnabled.value = serviceEnabled;

      if (!serviceEnabled) {
        logger.w('Location services are disabled');
        return false;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      final hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      hasLocationPermission.value = hasPermission;
      return hasPermission;
    } catch (e) {
      logger.e('Error checking location permissions', error: e);
      return false;
    }
  }

  Future<bool> requestLocationPermissions() async {
    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isLocationServiceEnabled.value = serviceEnabled;

      if (!serviceEnabled) {
        _showLocationServiceDialog();
        return false;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermanentlyDeniedDialog('Location');
        return false;
      }

      final hasPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      hasLocationPermission.value = hasPermission;

      if (!hasPermission) {
        _showPermissionDeniedDialog('Location');
      }

      return hasPermission;
    } catch (e) {
      logger.e('Error requesting location permissions', error: e);
      return false;
    }
  }

  // Helper methods for showing dialogs
  void _showPermissionDeniedDialog(String permissionName) {
    Get.snackbar(
      'Permission Required',
      '$permissionName permission is required for this feature to work',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  void _showPermanentlyDeniedDialog(String permissionName) {
    Get.defaultDialog(
      title: 'Permission Required',
      middleText:
          '$permissionName permission has been permanently denied. Please enable it in app settings.',
      textConfirm: 'Open Settings',
      textCancel: 'Cancel',
      onConfirm: () {
        Get.back();
        openSettings();
      },
    );
  }

  void _showLocationServiceDialog() {
    Get.snackbar(
      'Location Service Disabled',
      'Please enable location services in your device settings',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  // Check if a specific permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status.isPermanentlyDenied;
  }

  // Request multiple permissions at once
  Future<Map<Permission, PermissionStatus>> requestMultiplePermissions(
    List<Permission> permissions,
  ) async {
    try {
      return await permissions.request();
    } catch (e) {
      logger.e('Error requesting multiple permissions', error: e);
      return {};
    }
  }
}
