import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Check camera permission
  static Future<PermissionStatus> checkCameraPermission() async {
    return await Permission.camera.status;
  }

  // Request camera permission
  static Future<PermissionStatus> requestCameraPermission() async {
    return await Permission.camera.request();
  }

  // Check location permission
  static Future<PermissionStatus> checkLocationPermission() async {
    return await Permission.location.status;
  }

  // Request location permission
  static Future<PermissionStatus> requestLocationPermission() async {
    return await Permission.location.request();
  }

  // Check multiple permissions
  static Future<Map<Permission, PermissionStatus>> checkMultiplePermissions(
      List<Permission> permissions) async {
    return await permissions.request();
  }

  // Open app settings
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Check if permission is granted
  static bool isGranted(PermissionStatus status) {
    return status.isGranted;
  }

  // Check if permission is permanently denied
  static bool isPermanentlyDenied(PermissionStatus status) {
    return status.isPermanentlyDenied;
  }

  // Get permission status text
  static String getStatusText(PermissionStatus status) {
    if (status.isGranted) return 'Diizinkan';
    if (status.isDenied) return 'Ditolak';
    if (status.isPermanentlyDenied) return 'Ditolak Permanen';
    if (status.isRestricted) return 'Dibatasi';
    if (status.isLimited) return 'Terbatas';
    return 'Tidak Diketahui';
  }
}