import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Geri bildirim ekleme
  Future<void> insertFeedback(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('feedback').add(data);
    } catch (e) {
      throw Exception('Geri bildirim eklenirken bir hata oluştu: $e');
    }
  }

  Future<void> addLog(String adminUsername, String action) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminUsername': adminUsername,
        'action': action,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Log eklenirken hata oluştu: $e');
    }
  }

  // Geri bildirimleri çekme
  Future<List<Map<String, dynamic>>> getFeedback() async {
    try {
      // "feedback" koleksiyonunu al
      QuerySnapshot querySnapshot =
          await _firestore.collection('feedback').get();

      // Her bir dokümanı döngüye alıp, email ve feedback verilerini map olarak döndürüyoruz
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'email': data?['email'] ?? 'Email Bulunamadı',
          'feedback': data?['feedback'] ?? 'Geri bildirim Bulunamadı'
        };
      }).toList();
    } catch (e) {
      // Hata durumunda istisna fırlatıyoruz
      throw Exception('Geri bildirimler alınamadı: $e');
    }
  }
}
