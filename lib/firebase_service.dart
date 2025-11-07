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

  // Log ekleme
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
          'email': data?['email'] ?? 'Email Bulunamadı',
          'feedback': data?['feedback'] ?? 'Geri bildirim Bulunamadı'
        };
      }).toList();
    } catch (e) {
      // Hata durumunda istisna fırlatıyoruz
      throw Exception('Geri bildirimler alınamadı: $e');
    }
  }

  // Gezi formu başvurusu ekleme
  Future<void> insertTripApplication(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('bolu_yedigoller_trip').add({
        ...data,
        'paymentStatus': false, // Varsayılan olarak ödenmedi
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gezi başvurusu eklenirken bir hata oluştu: $e');
    }
  }

  // Gezi başvurularını çekme
  Future<List<Map<String, dynamic>>> getTripApplications() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('bolu_yedigoller_trip').get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {
          'id': doc.id,
          'department': data?['department'] ?? 'Bilinmiyor',
          'name': data?['name'] ?? 'Bilinmiyor',
          'phone': data?['phone'] ?? 'Bilinmiyor',
          'studentNumber': data?['studentNumber'] ?? 'Bilinmiyor',
          'tcNumber': data?['tcNumber'] ?? 'Bilinmiyor',
          'paymentStatus': data?['paymentStatus'] ?? false,
          'createdAt': data?['createdAt'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Gezi başvuruları alınamadı: $e');
    }
  }

  // Ödeme durumunu güncelleme
  Future<void> updatePaymentStatus(String docId, bool paymentStatus) async {
    try {
      await _firestore.collection('bolu_yedigoller_trip').doc(docId).update({
        'paymentStatus': paymentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ödeme durumu güncellenirken hata oluştu: $e');
    }
  }
}
