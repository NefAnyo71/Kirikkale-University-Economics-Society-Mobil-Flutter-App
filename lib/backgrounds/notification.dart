import 'package:permission_handler/permission_handler.dart';

Future<void> bildirimIzinleri() async {
  try {
    PermissionStatus notificationStatus =
        await Permission.notification.request();
    if (notificationStatus.isGranted) {
      print("Bildirim izni verildi!");
    }

    PermissionStatus storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) {
      print("Depolama izni verildi!");
    }
  } catch (e) {
    print('İzin hatası: $e');
  }
}