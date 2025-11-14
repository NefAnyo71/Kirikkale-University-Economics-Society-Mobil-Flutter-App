import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAdminSetup {
  static Future<void> createAdminCollection() async {
    try {

      await FirebaseFirestore.instance
          .collection('admincollection')
          .doc('admin1') 
          .set({
        'kullanici_adi': 'admin',
        'sifre': 'admin123',
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Admin collection başarıyla oluşturuldu!');
    } catch (e) {
      print('Admin collection oluşturulurken hata: $e');
    }
  }


  static Future<void> addAdminUser(String username, String password) async {
    try {
      await FirebaseFirestore.instance
          .collection('admincollection')
          .add({
        'kullanici_adi': username,
        'sifre': password,
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Yeni admin kullanıcısı eklendi: $username');
    } catch (e) {
      print('Admin kullanıcısı eklenirken hata: $e');
    }
  }
}