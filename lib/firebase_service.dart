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

  // Turnuva başvuru ekleme
  Future<void> insertTournamentRegistration(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('tournament_registrations').add(data);
    } catch (e) {
      throw Exception('Turnuva başvurusu eklenirken bir hata oluştu: $e');
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
          'email': data?['email'] ??
              'Email Bulunamadı', // Eğer 'email' yoksa boş string döner
          'feedback': data?['feedback'] ??
              'Geri bildirim Bulunamadı', // Eğer 'feedback' yoksa boş string döner
        };
      }).toList();
    } catch (e) {
      // Hata durumunda istisna fırlatıyoruz
      throw Exception('Geri bildirimler alınamadı: $e');
    }
  }
}
