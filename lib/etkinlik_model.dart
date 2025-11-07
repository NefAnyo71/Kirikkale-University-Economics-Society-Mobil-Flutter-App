 import 'package:cloud_firestore/cloud_firestore.dart';
 
 class Etkinlik {
   final String id;
   final String title;
   final String details;
   final DateTime date;
   final String url;
 
   Etkinlik({
     required this.id,
     required this.title,
     required this.details,
     required this.date,
     required this.url,
   });
 
   factory Etkinlik.fromFirestore(DocumentSnapshot doc) {
     Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
     return Etkinlik(
       id: doc.id,
       title: data['title'] ?? 'Başlıksız',
       details: data['details'] ?? 'Detay yok',
       date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
       url: data['url'] ?? '',
     );
   }
 }
