// notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class NotificationService {
  // DEBUG: Tüm bildirim ayarlarını logla
  static Future<void> debugNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().where((key) => key.startsWith('notified_')).toList();

      print("📋 Kayıtlı bildirim ayarları:");
      for (var key in allKeys) {
        final value = prefs.getBool(key);
        print("   - $key: $value");
      }

      if (allKeys.isEmpty) {
        print("   ❌ Hiç kayıtlı bildirim ayarı bulunamadı");
      }
    } catch (e) {
      print("❌ Bildirim ayarlarını debug etme hatası: $e");
    }
  }

  // Bildirimleri başlatma fonksiyonu
  static Future<void> initializeNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      print("✅ Bildirimler başarıyla başlatıldı");
    } catch (e) {
      print("❌ Bildirim başlatma hatası: $e");
    }
  }

  static Future<void> checkForEventsAndSendNotification() async {
    try {
      print("\n🔔🔔🔔 BİLDİRİM KONTROLÜ BAŞLADI: ${DateTime.now()} 🔔🔔🔔");

      final now = DateTime.now();
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');

      // ÖNCE: Tüm etkinlikleri debug için göster
      final allEvents = await collection.orderBy('date', descending: false).get();
      print("📋 Tüm etkinlikler (${allEvents.docs.length} adet):");

      for (var doc in allEvents.docs) {
        var data = doc.data();
        var date = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null;

        if (date != null) {
          final difference = date.difference(now);
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
          print("   - ${data['title']}: $formattedDate (${difference.inDays}g ${difference.inHours.remainder(24)}s kaldı)");
        }
      }

      // SONRA: Filtrelenmiş sorgu
      final querySnapshot = await collection
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .get();

      print("\n📊 Filtrelenmiş ${querySnapshot.docs.length} yaklaşan etkinlik bulundu");

      final prefs = await SharedPreferences.getInstance();
      bool anyNotificationSent = false;

      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        var date = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null;

        if (date != null) {
          final difference = date.difference(now);
          final eventId = doc.id;
          final eventTitle = data['title'] ?? 'İsimsiz Etkinlik';

          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
          print("\n📅 Etkinlik: $eventTitle");
          print("   📅 Tarih: $formattedDate");
          print("   ⏰ Kalan süre: ${difference.inDays}g ${difference.inHours.remainder(24)}s ${difference.inMinutes.remainder(60)}dk");

          // GENİŞLETİLMİŞ ZAMAN ARALIKLARI (daha esnek)
          bool shouldNotify7Days = (difference.inHours >= 150 && difference.inHours <= 186); // 6.25-7.75 gün
          bool shouldNotify1Day = (difference.inHours >= 18 && difference.inHours <= 30);   // 0.75-1.25 gün
          bool shouldNotify1Hour = (difference.inMinutes >= 50 && difference.inMinutes <= 70); // 50-70 dakika

          print("   🔍 7 gün kontrol: $shouldNotify7Days (150-186 saat)");
          print("   🔍 1 gün kontrol: $shouldNotify1Day (18-30 saat)");
          print("   🔍 1 saat kontrol: $shouldNotify1Hour (50-70 dakika)");

          // ✅ DEĞİŞİKLİK: else if yerine BAĞIMSIZ if yapısı
          // Böylece bir etkinlik hem 7 gün hem 1 gün hem de 1 saat bildirimi alabilir

          // 7 gün kala kontrolü - BAĞIMSIZ
          if (shouldNotify7Days) {
            final notificationKey = 'notified_7days_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅✅✅ 7 GÜN BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode,
                'Yaklaşan Etkinlik! 🗓️',
                '$eventTitle etkinliğine 7 gün kaldı. Hazırlıklarınızı yapın!',
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            } else {
              print("   ℹ️  7 gün bildirimi zaten gönderilmiş: $eventTitle");
            }
          }

          // 1 gün kala kontrolü - BAĞIMSIZ
          if (shouldNotify1Day) {
            final notificationKey = 'notified_1day_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅✅✅ 1 GÜN BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode + 1,
                'Etkinlik Yaklaşıyor! ⏰',
                '$eventTitle etkinliğine sadece 1 gün kaldı. Kaçırmayın!',
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            } else {
              print("   ℹ️  1 gün bildirimi zaten gönderilmiş: $eventTitle");
            }
          }

          // 1 saat kala bildirimi - BAĞIMSIZ
          if (shouldNotify1Hour) {
            final notificationKey = 'notified_1hour_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅✅✅ 1 SAAT BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode + 2,
                'Etkinlik Başlamak Üzere! 🔥',
                '$eventTitle etkinliği 1 saat içinde başlayacak.',
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            } else {
              print("   ℹ️  1 saat bildirimi zaten gönderilmiş: $eventTitle");
            }
          }

          if (!shouldNotify7Days && !shouldNotify1Day && !shouldNotify1Hour) {
            print("   ➡️  Bildirim zamanı değil: $eventTitle");
          }
        }
      }

      if (!anyNotificationSent) {
        print("\nℹ️  Hiçbir etkinlik için bildirim gönderilmedi");
      }

      // Debug: Kayıtlı bildirim ayarlarını göster
      await debugNotificationSettings();

      print("\n✅ Bildirim kontrolü tamamlandı");

    } catch (e) {
      print("❌ Bildirim kontrolünde hata: $e");
    }
  }

  static Future<void> _showNotification(int id, String title, String body) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'event_channel_id',
        'Etkinlik Bildirimleri',
        channelDescription: 'Yaklaşan etkinlikler hakkında bildirimler',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: 'event_notification', // Etkinlik bildirimi olduğunu belirt
      );



      print("📨 Bildirim gönderildi: $title - $body");
    } catch (e) {
      print("❌ Bildirim gönderme hatası: $e");
    }
  }

  // Bildirim sayacını artırma fonksiyonu
  static Future<void> _incrementNotificationBadge() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt('event_notification_count') ?? 0;
      final newCount = currentCount + 1;
      await prefs.setInt('event_notification_count', newCount);
      print('🔔 Bildirim sayacı artırıldı: $currentCount → $newCount');
    } catch (e) {
      print('❌ Bildirim sayacı artırma hatası: $e');
    }
  }

  // Test için manuel bildirim gönderme
  static Future<void> sendTestNotification() async {
    await _showNotification(
      9999,
      'Test Bildirimi',
      'Bu bir test bildirimidir. ${DateTime.now().toString()}',
    );
  }

  // Eski bildirim verilerini temizleme metodu
  static Future<void> cleanOldNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');

      final querySnapshot = await collection.get();
      final existingEventIds = querySnapshot.docs.map((doc) => doc.id).toSet();

      final allKeys = prefs.getKeys();
      int removedCount = 0;

      for (var key in allKeys) {
        if (key.startsWith('notified_')) {
          final parts = key.split('_');
          if (parts.length >= 3 && !existingEventIds.contains(parts[2])) {
            await prefs.remove(key);
            removedCount++;
            print("🧹 Eski bildirim temizlendi: $key");
          }
        }
      }

      print("✅ $removedCount eski bildirim kaydı temizlendi");
    } catch (e) {
      print("❌ Bildirim temizleme hatası: $e");
    }
  }

  // Tüm bildirim ayarlarını sıfırla (debug için)
  static Future<void> resetAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      int removedCount = 0;

      for (var key in allKeys) {
        if (key.startsWith('notified_')) {
          await prefs.remove(key);
          removedCount++;
          print("🧹 Bildirim ayarı kaldırıldı: $key");
        }
      }

      print("✅ $removedCount bildirim ayarı sıfırlandı");
    } catch (e) {
      print("❌ Bildirim sıfırlama hatası: $e");
    }
  }

  // Firestore'daki tüm etkinlikleri listele (debug için)
  static Future<void> listAllEvents() async {
    try {
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');
      final querySnapshot = await collection.orderBy('date', descending: false).get();

      print("\n📋 FIRESTORE'DAKİ TÜM ETKİNLİKLER:");
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        var date = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null;

        if (date != null) {
          final difference = date.difference(DateTime.now());
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
          print("   - ${data['title']}: $formattedDate (${difference.inDays}g ${difference.inHours.remainder(24)}s kaldı) - ID: ${doc.id}");
        }
      }
    } catch (e) {
      print("❌ Etkinlik listeleme hatası: $e");
    }
  }

  // ✅ YENİ: Belirli bir etkinliğin bildirim geçmişini temizleme
  static Future<void> clearEventNotificationHistory(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keysToRemove = [
        'notified_7days_$eventId',
        'notified_1day_$eventId',
        'notified_1hour_$eventId'
      ];

      int removedCount = 0;
      for (var key in keysToRemove) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          removedCount++;
          print("🧹 Etkinlik bildirim geçmişi temizlendi: $key");
        }
      }

      print("✅ $removedCount etkinlik bildirim ayarı temizlendi");
    } catch (e) {
      print("❌ Etkinlik bildirim geçmişi temizleme hatası: $e");
    }
  }
}