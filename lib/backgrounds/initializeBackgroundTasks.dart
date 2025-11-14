import 'package:ket/backgrounds/fCMTokenTake.dart';
import 'package:ket/services/app_update_service.dart';

import 'notification.dart';

Future<void> initializeBackgroundTasks() async {
  try {
    AppUpdateService.checkForUpdate();
    bildirimIzinleri();
    fCMTokeniAl();
    print('✅ Arka plan görevleri başlatıldı');
  } catch (e) {
    print('❌ Arka plan görev hatası: $e');
  }
}