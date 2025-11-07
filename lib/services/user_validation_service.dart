import 'package:cloud_firestore/cloud_firestore.dart';

class UserValidationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcının gerçek paylaşım sayısını kontrol et
  static Future<Map<String, dynamic>> validateUserShares(String userEmail) async {
    try {
      // Kullanıcı bilgilerini al
      final userDoc = await _firestore.collection('üyelercollection').doc(userEmail).get();
      
      if (!userDoc.exists) {
        return {
          'isValid': false,
          'reason': 'Kullanıcı bulunamadı',
          'actualShares': 0,
          'creditShares': 0,
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userName = userData['name'] ?? '';
      final userSurname = userData['surname'] ?? '';

      // Ders notları koleksiyonundan gerçek paylaşım sayısını al
      final notesQuery = await _firestore
          .collection('ders_notlari')
          .where('paylasan_kullanici_email', isEqualTo: userEmail)
          .get();

      final actualShares = notesQuery.docs.length;

      // Kredi sistemindeki paylaşım sayısını al
      final creditDoc = await _firestore.collection('user_credits').doc(userEmail).get();
      final creditShares = creditDoc.exists ? (creditDoc.data()?['totalShares'] ?? 0) : 0;

      // Doğrulama kaydı oluştur
      await _createValidationRecord(userEmail, userName, userSurname, actualShares, creditShares);

      return {
        'isValid': actualShares == creditShares,
        'reason': actualShares != creditShares ? 'Paylaşım sayısı uyuşmuyor' : 'Doğru',
        'actualShares': actualShares,
        'creditShares': creditShares,
        'userName': userName,
        'userSurname': userSurname,
      };
    } catch (e) {
      print('Kullanıcı doğrulama hatası: $e');
      return {
        'isValid': false,
        'reason': 'Doğrulama hatası: $e',
        'actualShares': 0,
        'creditShares': 0,
      };
    }
  }

  // Doğrulama kaydı oluştur
  static Future<void> _createValidationRecord(
    String userEmail,
    String userName,
    String userSurname,
    int actualShares,
    int creditShares,
  ) async {
    try {
      await _firestore.collection('user_validation_logs').add({
        'userEmail': userEmail,
        'userName': userName,
        'userSurname': userSurname,
        'actualShares': actualShares,
        'creditShares': creditShares,
        'isValid': actualShares == creditShares,
        'discrepancy': actualShares - creditShares,
        'validationDate': FieldValue.serverTimestamp(),
        'status': actualShares == creditShares ? 'valid' : 'invalid',
      });
    } catch (e) {
      print('Doğrulama kaydı oluşturma hatası: $e');
    }
  }

  // Tüm kullanıcıları toplu doğrula
  static Future<List<Map<String, dynamic>>> validateAllUsers() async {
    try {
      final results = <Map<String, dynamic>>[];
      
      // Tüm kullanıcıları al
      final usersSnapshot = await _firestore.collection('üyelercollection').get();
      
      for (final userDoc in usersSnapshot.docs) {
        final userEmail = userDoc.id;
        final validation = await validateUserShares(userEmail);
        results.add({
          'userEmail': userEmail,
          ...validation,
        });
      }
      
      return results;
    } catch (e) {
      print('Toplu doğrulama hatası: $e');
      return [];
    }
  }

  // Geçersiz kullanıcıları al
  static Future<List<Map<String, dynamic>>> getInvalidUsers() async {
    try {
      final snapshot = await _firestore
          .collection('user_validation_logs')
          .where('isValid', isEqualTo: false)
          .orderBy('validationDate', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Geçersiz kullanıcıları alma hatası: $e');
      return [];
    }
  }

  // Kullanıcı kredilerini düzelt
  static Future<bool> fixUserCredits(String userEmail) async {
    try {
      final validation = await validateUserShares(userEmail);
      
      if (!validation['isValid']) {
        final actualShares = validation['actualShares'] as int;
        final correctCredits = (actualShares * 15) + 4; // Her paylaşım 15 kredi + başlangıç 4 kredi
        
        await _firestore.collection('user_credits').doc(userEmail).update({
          'totalShares': actualShares,
          'totalCredits': correctCredits,
          'lastUpdated': FieldValue.serverTimestamp(),
          'fixedAt': FieldValue.serverTimestamp(),
        });

        // Düzeltme kaydı oluştur
        await _firestore.collection('credit_fixes').add({
          'userEmail': userEmail,
          'oldShares': validation['creditShares'],
          'newShares': actualShares,
          'oldCredits': 0, // Eski kredi bilgisi
          'newCredits': correctCredits,
          'fixedAt': FieldValue.serverTimestamp(),
          'fixedBy': 'system',
        });

        return true;
      }
      
      return false;
    } catch (e) {
      print('Kredi düzeltme hatası: $e');
      return false;
    }
  }

  // Doğrulama loglarını temizle
  static Future<void> clearValidationLogs() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection('user_validation_logs').get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Doğrulama logları temizleme hatası: $e');
    }
  }
}