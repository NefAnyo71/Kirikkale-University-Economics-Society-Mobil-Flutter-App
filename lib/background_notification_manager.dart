import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';
import 'dart:async';

class BackgroundNotificationManager {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Workmanager başlatma
  static Future<void> initializeWorkmanager() async {
    try {
      Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
      
      // 1 saatte bir kontrol
      Workmanager().registerPeriodicTask(
        "eventNotificationTask",
        "eventNotificationCheck",
        frequency: const Duration(hours: 1),
        initialDelay: const Duration(minutes: 5),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
      );
      
      print('✅ Workmanager başlatıldı (1 saatlik periyot)');
    } catch (e) {
      print('❌ Workmanager başlatma hatası: $e');
    }
  }

  // Bildirim sistemi başlatma
  static Future<void> initializeNotifications() async {
    try {
      await NotificationService.initializeNotifications();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      final InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);
      
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      print('✅ Bildirim sistemi başlatıldı');
    } catch (e) {
      print('❌ Bildirim başlatma hatası: $e');
    }
  }

  // Firebase mesaj dinleyicileri kurma
  static void setupFirebaseMessageListeners({
    required Function(int) onNotificationCountUpdate,
  }) {
    // Foreground mesajları dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Bildirim geldi: ${message.notification?.title}');
      
      if (_isEventNotification(message)) {
        print('🔔 Etkinlik bildirimi tespit edildi');
        onNotificationCountUpdate(1);
      }
    });

    // Background/terminated durumdan gelen mesajları dinle
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 Arka plan bildirim açıldı: ${message.notification?.title}');
      if (_isEventNotification(message)) {
        onNotificationCountUpdate(1);
      }
    });

    // Uygulama kapalıyken gelen mesajları kontrol et
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && _isEventNotification(message)) {
        print('📱 Uygulama kapalıyken gelen etkinlik mesajı');
        onNotificationCountUpdate(1);
      }
    });
  }

  // Etkinlik bildirimi kontrolü
  static bool _isEventNotification(RemoteMessage message) {
    return message.data['type'] == 'event' ||
           message.notification?.title?.contains('Etkinlik') == true ||
           message.notification?.title?.contains('etkinlik') == true;
  }

  // İlk bildirim kontrolü
  static Future<void> performInitialNotificationCheck() async {
    Future.delayed(const Duration(seconds: 10), () {
      NotificationService.checkForEventsAndSendNotification();
    });
  }
}

// Arka plan görevi için top-level fonksiyon
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) {
    if (taskName == "eventNotificationTask") {
      NotificationService.checkForEventsAndSendNotification();
    }
    return Future.value(true);
  });
}

// Firebase arka plan mesaj handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Arka plan mesajı: ${message.messageId}');
}