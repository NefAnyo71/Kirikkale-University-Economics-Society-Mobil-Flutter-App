// notification_service.dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class NotificationService {
  // Bildirim sayacındaki değişiklikleri yayınlamak için StreamController
  static final StreamController<int> _notificationCountController =
      StreamController<int>.broadcast();
  static Stream<int> get notificationCountStream =>
      _notificationCountController.stream;

  // DEBUG: Tüm bildirim ayarlarını logla
  static Future<void> debugNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys =
          prefs.getKeys().where((key) => key.startsWith('notified_')).toList();

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

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        // Bildirime tıklandığında çalışacak fonksiyon
        onDidReceiveNotificationResponse: (notificationResponse) async {
          final String? payload = notificationResponse.payload;
          if (payload != null && payload.startsWith('http')) {
            print('🚀 Bildirim payload (URL) alındı: $payload');
            await launchUrl(Uri.parse(payload));
          }
        },
      );
      print("✅ Bildirimler başarıyla başlatıldı");
    } catch (e) {
      print("❌ Bildirim başlatma hatası: $e");
    }
  }

  static Future<void> checkForEventsAndSendNotification() async {
    try {
      print("\n🔔 BİLDİRİM KONTROLÜ BAŞLADI: ${DateTime.now()}");

      final now = DateTime.now();
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');
      final prefs = await SharedPreferences.getInstance();

      // Son kontrol zamanını al
      final lastCheckTime = prefs.getInt('last_notification_check') ?? 0;
      final lastCheck = DateTime.fromMillisecondsSinceEpoch(lastCheckTime);
      final timeSinceLastCheck = now.difference(lastCheck);

      // Eğer son kontrolden 30 dakika geçmemişse çık (spam önleme)
      if (timeSinceLastCheck.inMinutes < 30) {
        print("⏰ Son kontrolden ${timeSinceLastCheck.inMinutes} dakika geçti. Minimum 30 dakika bekleniyor.");
        return;
      }

      // Yaklaşan etkinlikleri al
      final querySnapshot = await collection
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .get();

      print("📊 ${querySnapshot.docs.length} yaklaşan etkinlik bulundu");

      // Badge'i etkinlik sayısına göre güncelle
      await updateBadgeCount(querySnapshot.docs.length);

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
          final eventDetails = data['details'] ?? 'Detaylar yakında...';
          final eventUrl = data['url'] as String?;

          print("\n📅 Etkinlik: $eventTitle");
          print("   ⏰ Kalan süre: ${difference.inDays}g ${difference.inHours.remainder(24)}s");

          // SADECE 3 KURAL: 7 gün, 2 gün, 2 saat
          bool shouldNotify7Days = (difference.inDays == 7 && difference.inHours.remainder(24) <= 2);
          bool shouldNotify2Days = (difference.inDays == 2 && difference.inHours.remainder(24) <= 2);
          bool shouldNotify2Hours = (difference.inHours == 2 && difference.inMinutes.remainder(60) <= 10);

          // 7 gün kala bildirimi
          if (shouldNotify7Days) {
            final notificationKey = 'notified_7days_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅ 7 GÜN BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode,
                '🗓️ 7 Gün Kaldı: $eventTitle',
                'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}\n$eventDetails',
                payload: eventUrl,
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            }
          }

          // 2 gün kala bildirimi
          if (shouldNotify2Days) {
            final notificationKey = 'notified_2days_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅ 2 GÜN BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode + 1,
                '⏰ 2 Gün Kaldı: $eventTitle',
                'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}\n$eventDetails',
                payload: eventUrl,
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            }
          }

          // 2 saat kala bildirimi
          if (shouldNotify2Hours) {
            final notificationKey = 'notified_2hours_$eventId';
            final alreadyNotified = prefs.getBool(notificationKey) ?? false;

            if (!alreadyNotified) {
              print("   ✅ 2 SAAT BİLDİRİMİ GÖNDERİLİYOR: $eventTitle");
              await _showNotification(
                eventId.hashCode + 2,
                '🔥 2 Saat Kaldı: $eventTitle',
                'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}\n$eventDetails',
                payload: eventUrl,
              );
              await _incrementNotificationBadge();
              await prefs.setBool(notificationKey, true);
              anyNotificationSent = true;
            }
          }
        }
      }

      // Son kontrol zamanını güncelle
      await prefs.setInt('last_notification_check', now.millisecondsSinceEpoch);

      if (anyNotificationSent) {
        print("✅ Bildirim(ler) gönderildi");
      } else {
        print("ℹ️ Bildirim gönderilmedi");
      }

      print("✅ Bildirim kontrolü tamamlandı\n");
    } catch (e) {
      print("❌ Bildirim kontrolünde hata: $e");
    }
  }

  static Future<void> _showNotification(int id, String title, String body,
      {String? payload}) async {
    try {
      final AndroidNotificationDetails androidPlatformChannelSpecifics =
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
        styleInformation: BigTextStyleInformation(body), // Uzun metinler için
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload, // Tıklama eylemi için URL'yi payload olarak ayarla
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
      _notificationCountController.add(newCount); // Stream'e yeni sayacı gönder
      print('🔔 Bildirim sayacı artırıldı: $currentCount → $newCount');
    } catch (e) {
      print('❌ Bildirim sayacı artırma hatası: $e');
    }
  }

  // Yeni etkinlik eklendiğinde otomatik bildirim gönder
  static Future<void> checkNewEventsAndNotify() async {
    try {
      print('🔔 Yeni etkinlik kontrolü başlatılıyor...');
      
      final now = DateTime.now();
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');
      
      // Gelecekteki etkinlikleri al
      final querySnapshot = await collection
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .get();
      
      print('📊 ${querySnapshot.docs.length} yaklaşan etkinlik bulundu');
      
      if (querySnapshot.docs.isNotEmpty) {
        // Tüm etkinlikler için bildirim gönder (daha agresif)
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final eventTitle = data['title'] ?? 'İsimsiz Etkinlik';
          final eventDetails = data['details'] ?? 'Detaylar yakında...';
          final eventDate = (data['date'] as Timestamp).toDate();
          
          final difference = eventDate.difference(now);
          
          // Eğer etkinlik 30 gün içindeyse bildirim gönder (daha geniş aralık)
          if (difference.inDays <= 30) {
            await _showNotification(
              (doc.id.hashCode + 999999), // Benzersiz ID
              '🎉 Yeni Etkinlik: $eventTitle',
              'Tarih: ${DateFormat('dd/MM/yyyy HH:mm').format(eventDate)}\n$eventDetails',
              payload: data['url'] as String?,
            );
            
            await _incrementNotificationBadge();
            print('✅ Yeni etkinlik bildirimi gönderildi: $eventTitle');
            
            // Bildirimler arasında kısa bekleme
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
    } catch (e) {
      print('❌ Yeni etkinlik kontrolü hatası: $e');
    }
  }

  // Etkinlik sayısına göre badge güncelle
  static Future<void> updateBadgeCount(int eventCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentBadge = prefs.getInt('event_notification_count') ?? 0;
      
      // Eğer etkinlik varsa ve badge 0 ise, badge'i etkinlik sayısı kadar yap
      if (eventCount > 0 && currentBadge == 0) {
        await prefs.setInt('event_notification_count', eventCount);
        _notificationCountController.add(eventCount);
        print('🔔 Badge güncellendi: $eventCount etkinlik');
      }
    } catch (e) {
      print('❌ Badge güncelleme hatası: $e');
    }
  }

  // Test için manuel bildirim gönderme
  static Future<void> sendTestNotification() async {
    final now = DateTime.now();
    await _showNotification(
      9999,
      '🔔 KET Test Bildirimi',
      'Bildirim sistemi çalışıyor! \nZaman: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(now)}',
      payload: 'https://www.google.com',
    );
    
    // Badge'i de artır
    await _incrementNotificationBadge();
    print('✅ Test bildirimi gönderildi ve badge artırıldı');
  }

  // Main.dart koduma test bildirimi butonu eklemiştim onun için ekledim 
  static Future<void> sendNearestEventTestNotification() async {
    try {
      final now = DateTime.now();
      final collection = FirebaseFirestore.instance.collection('yaklasan_etkinlikler');
      
      final querySnapshot = await collection
          .where('date', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('date', descending: false)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        final eventTitle = data['title'] ?? 'Test Etkinlik';
        final eventDetails = data['details'] ?? 'Test detayları';
        final eventDate = (data['date'] as Timestamp).toDate();
        final difference = eventDate.difference(now);
        
        await _showNotification(
          8888,
          '🎯 TEST: $eventTitle',
          'Kalan süre: ${difference.inDays}g ${difference.inHours.remainder(24)}s\n$eventDetails',
          payload: data['url'] as String?,
        );
        
        await _incrementNotificationBadge();
        print('✅ En yakın etkinlik test bildirimi gönderildi: $eventTitle');
      } else {
        await sendTestNotification(); // Etkinlik yoksa normal test bildirimi gönder
      }
    } catch (e) {
      print('❌ Test bildirimi hatası: $e');
      await sendTestNotification(); // Hata durumunda normal test bildirimi gönder
    }
  }
    // Main.dart koduma test bildirimi butonu eklemiştim onun için ekledim 

  // Eski bildirim verilerini temizleme metodu
  static Future<void> cleanOldNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final collection =
          FirebaseFirestore.instance.collection('yaklasan_etkinlikler');

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
      final collection =
          FirebaseFirestore.instance.collection('yaklasan_etkinlikler');
      final querySnapshot =
          await collection.orderBy('date', descending: false).get();

      print("\n📋 FIRESTORE'DAKİ TÜM ETKİNLİKLER:");
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        var date = data['date'] is Timestamp
            ? (data['date'] as Timestamp).toDate()
            : null;

        if (date != null) {
          final difference = date.difference(DateTime.now());
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
          print(
              "   - ${data['title']}: $formattedDate (${difference.inDays}g ${difference.inHours.remainder(24)}s kaldı) - ID: ${doc.id}");
        }
      }
    } catch (e) {
      print("❌ Etkinlik listeleme hatası: $e");
    }
  }

  // Belirli bir etkinliğin bildirim geçmişini temizleme
  static Future<void> clearEventNotificationHistory(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keysToRemove = [
        'notified_7days_$eventId',
        'notified_2days_$eventId',
        'notified_2hours_$eventId'
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
