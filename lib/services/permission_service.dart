import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart';

class PermissionService extends GetxService {
  // Singleton pattern
  static PermissionService get instance => Get.find<PermissionService>();

  // Permission status observables
  final RxBool hasBluetoothPermission = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAllPermissions();
  }

  // Check all permissions at once
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

  // Helper methods for showing dialogs
  void _showPermissionDeniedDialog(String permissionName) {
    Get.snackbar(
      'Permission Required',
      '$permissionName permission is required for this feature to work',
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
