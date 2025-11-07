import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const Duration _updateCheckInterval = Duration(hours: 6);

  /// Uygulama güncellemesi kontrolü yapar
  static Future<void> checkForUpdate({
    bool forceCheck = false,
    BuildContext? context,
  }) async {
    try {
      // Eğer zorunlu kontrol değilse, son kontrol zamanını kontrol et
      if (!forceCheck && !await _shouldCheckForUpdate()) {
        print('⏰ Güncelleme kontrolü için henüz erken');
        return;
      }

      print('🔍 Uygulama güncellemesi kontrol ediliyor...');
      
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      
      // Son kontrol zamanını kaydet
      await _saveLastUpdateCheck();
      
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        print('📱 Güncelleme mevcut: ${info.availableVersionCode}');
        
        // Güncelleme türünü belirle
        if (info.immediateUpdateAllowed) {
          await _performImmediateUpdate(context);
        } else if (info.flexibleUpdateAllowed) {
          await _performFlexibleUpdate(context);
        }
      } else {
        print('✅ Uygulama güncel');
      }
    } catch (e) {
      print('❌ Güncelleme kontrolü hatası: $e');
      _handleUpdateError(e, context);
    }
  }

  /// Zorunlu güncelleme (Immediate Update)
  static Future<void> _performImmediateUpdate(BuildContext? context) async {
    try {
      print('🚀 Zorunlu güncelleme başlatılıyor...');
      
      if (context != null) {
        await _showUpdateDialog(
          context,
          'Zorunlu Güncelleme',
          'Uygulamanın yeni sürümü mevcut. Devam etmek için güncelleme gerekli.',
          isRequired: true,
        );
      }
      
      final AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
      
      if (result == AppUpdateResult.success) {
        print('✅ Güncelleme başarılı');
      } else {
        print('❌ Güncelleme başarısız: $result');
      }
    } catch (e) {
      print('❌ Zorunlu güncelleme hatası: $e');
      _handleUpdateError(e, context);
    }
  }

  /// Esnek güncelleme (Flexible Update)
  static Future<void> _performFlexibleUpdate(BuildContext? context) async {
    try {
      print('📥 Esnek güncelleme başlatılıyor...');
      
      if (context != null) {
        final shouldUpdate = await _showUpdateDialog(
          context,
          'Güncelleme Mevcut',
          'Uygulamanın yeni sürümü mevcut. Şimdi güncellemek ister misiniz?',
          isRequired: false,
        );
        
        if (!shouldUpdate) {
          print('👤 Kullanıcı güncellemeyi reddetti');
          return;
        }
      }
      
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
      
      if (result == AppUpdateResult.success) {
        print('📥 Güncelleme indiriliyor...');
        _listenToUpdateProgress(context);
      } else {
        print('❌ Esnek güncelleme başarısız: $result');
      }
    } catch (e) {
      print('❌ Esnek güncelleme hatası: $e');
      _handleUpdateError(e, context);
    }
  }

  /// Güncelleme ilerlemesini dinle
  static void _listenToUpdateProgress(BuildContext? context) {
    InAppUpdate.completeFlexibleUpdate().then((_) {
      print('✅ Güncelleme tamamlandı');
      if (context != null) {
        _showRestartDialog(context);
      }
    }).catchError((e) {
      print('❌ Güncelleme tamamlama hatası: $e');
    });
  }

  /// Güncelleme dialog'u göster
  static Future<bool> _showUpdateDialog(
    BuildContext context,
    String title,
    String message, {
    required bool isRequired,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: !isRequired,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.system_update, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            if (!isRequired)
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Daha Sonra'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  /// Yeniden başlatma dialog'u göster
  static void _showRestartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.restart_alt, color: Colors.green),
              SizedBox(width: 8),
              Text('Güncelleme Tamamlandı'),
            ],
          ),
          content: const Text(
            'Güncelleme başarıyla tamamlandı. Değişikliklerin etkili olması için uygulamayı yeniden başlatın.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                InAppUpdate.completeFlexibleUpdate().then((_) {
                  // Güncelleme tamamlandı
                }).catchError((e) {
                  print('❌ Yeniden başlatma hatası: $e');
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yeniden Başlat'),
            ),
          ],
        );
      },
    );
  }

  /// Güncelleme hatalarını yönet
  static void _handleUpdateError(dynamic error, BuildContext? context) {
    String errorMessage = 'Güncelleme sırasında bir hata oluştu.';
    
    if (error.toString().contains('ERROR_PLAY_STORE_NOT_FOUND')) {
      errorMessage = 'Google Play Store bulunamadı.';
    } else if (error.toString().contains('ERROR_UPDATE_UNAVAILABLE')) {
      errorMessage = 'Güncelleme şu anda mevcut değil.';
    } else if (error.toString().contains('ERROR_INVALID_REQUEST')) {
      errorMessage = 'Geçersiz güncelleme isteği.';
    }
    
    print('❌ Güncelleme hatası: $errorMessage');
    
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Son güncelleme kontrolü zamanını kontrol et
  static Future<bool> _shouldCheckForUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getInt(_lastUpdateCheckKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      return (now - lastCheck) > _updateCheckInterval.inMilliseconds;
    } catch (e) {
      print('❌ Son kontrol zamanı okuma hatası: $e');
      return true; // Hata durumunda kontrol yap
    }
  }

  /// Son güncelleme kontrolü zamanını kaydet
  static Future<void> _saveLastUpdateCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastUpdateCheckKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Son kontrol zamanı kaydetme hatası: $e');
    }
  }

  /// Manuel güncelleme kontrolü (kullanıcı tarafından tetiklenen)
  static Future<void> manualUpdateCheck(BuildContext context) async {
    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await checkForUpdate(forceCheck: true, context: context);
    } finally {
      // Loading'i kapat
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Güncelleme durumunu kontrol et
  static Future<UpdateAvailability> getUpdateStatus() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability;
    } catch (e) {
      print('❌ Güncelleme durumu kontrol hatası: $e');
      return UpdateAvailability.unknown;
    }
  }
}