import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> fCMTokeniAl() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print("Firebase Token: $token");
  } catch (e) {
    print('FCM Token alma hatası: $e');
  }
}