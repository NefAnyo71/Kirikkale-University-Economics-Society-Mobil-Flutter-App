import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yönetici paneli aktivitelerini loglamak için bir servis sınıfı.
class AdminLoggingService {
  static final _firestore = FirebaseFirestore.instance;
  static const _collectionName = 'adminlogs';

  /// Yönetici paneline yapılan giriş denemelerini loglar.
  static Future<void> logLoginAttempt({
    required String adminUsername,
    required bool isSuccessful,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appUserName = prefs.getString('name') ?? 'N/A';
      final appUserEmail = prefs.getString('email') ?? 'N/A';

      await _firestore.collection(_collectionName).add({
        'type': 'login_attempt',
        'timestamp': FieldValue.serverTimestamp(),
        'admin_username_attempt': adminUsername,
        'is_successful': isSuccessful,
        'app_user_name': appUserName,
        'app_user_email': appUserEmail,
        'platform': 'mobile_app',
      });
    } catch (e) {
      print('Admin loglama hatası (giriş denemesi): $e');
    }
  }

  /// Yöneticinin panelde tıkladığı butonları ve yönlendirmeleri loglar.
  static Future<void> logNavigation({
    required String adminUsername,
    required String buttonLabel,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appUserName = prefs.getString('name') ?? 'N/A';
      final appUserEmail = prefs.getString('email') ?? 'N/A';

      await _firestore.collection(_collectionName).add({
        'type': 'navigation',
        'timestamp': FieldValue.serverTimestamp(),
        'admin_username': adminUsername,
        'button_label': buttonLabel,
        'app_user_name': appUserName,
        'app_user_email': appUserEmail,
      });
    } catch (e) {
      print('Admin loglama hatası (yönlendirme): $e');
    }
  }
}

