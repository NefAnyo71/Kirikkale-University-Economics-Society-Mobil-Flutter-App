import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';

Future<void> kullaniciFirebaseKayit(
    String email, String password, String name, String surname) async {
  try {
    await firestore.collection('üyelercollection').doc(email).set({
      'email': email,
      'password': password,
      'name': name,
      'surname': surname,
      'hesapEngellendi': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('Kullanıcı Firestore\'a kaydedildi: $email');
  } catch (e) {
    print('Firestore kayıt hatası: $e');
  }
}