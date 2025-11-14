import 'package:flutter/material.dart';
import 'package:ket/notification_service.dart';

Future<void> testBildirimiGonder(BuildContext context) async {
  await NotificationService.sendTestNotification();
  await NotificationService.checkForEventsAndSendNotification();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('🔔 Test bildirimi gönderildi ve etkinlik kontrolü yapıldı!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }
}
