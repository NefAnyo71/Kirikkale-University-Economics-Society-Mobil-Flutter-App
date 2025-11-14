import '../main.dart';

Future<Map<String, dynamic>> kullaniciFirebaseKontrol(
    String email, String password) async {
  try {
    final doc =
        await firestore.collection('üyelercollection').doc(email).get();
    if (doc.exists) {
      final userData = doc.data() as Map<String, dynamic>;
      final hesapEngellendi = userData['hesapEngellendi'] ?? 0;

      return {
        'isValid': userData['password'] == password,
        'hesapEngellendi': hesapEngellendi,
        'userData': userData
      };
    }
    return {'isValid': false, 'hesapEngellendi': 0};
  } catch (e) {
    print('Firestore doğrulama hatası: $e');
    return {'isValid': false, 'hesapEngellendi': 0};
  }
}