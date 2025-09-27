import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAdminCollectionPage extends StatelessWidget {
  const CreateAdminCollectionPage({Key? key}) : super(key: key);

  Future<void> _createAdminCollection() async {
    try {
      // Firebase'de admincollection koleksiyonunu oluştur
      await FirebaseFirestore.instance
          .collection('admincollection')
          .doc('admin1')
          .set({
        'kullanici_adi': 'admin',
        'sifre': 'admin123',
        'created_at': FieldValue.serverTimestamp(),
      });

      // İkinci admin kullanıcısı ekle
      await FirebaseFirestore.instance
          .collection('admincollection')
          .doc('admin2')
          .set({
        'kullanici_adi': 'kkuekonomi',
        'sifre': 'kkuekonomi2024',
        'created_at': FieldValue.serverTimestamp(),
      });

      print('Admin collection başarıyla oluşturuldu!');
    } catch (e) {
      print('Admin collection oluşturulurken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Collection Oluştur'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _createAdminCollection();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin collection oluşturuldu!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: const Text('Admin Collection Oluştur'),
        ),
      ),
    );
  }
}