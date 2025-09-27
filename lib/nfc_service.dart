import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class NFCService {
  static const MethodChannel _channel = MethodChannel('com.arifozdemir.ekos/nfc');
  
  // NFC özelliklerini kontrol et
  static Future<bool> isNFCAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isNFCAvailable');
      return result;
    } catch (e) {
      print('NFC kontrol hatası: $e');
      return false;
    }
  }
  
  // NFC aktif mi kontrol et
  static Future<bool> isNFCEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isNFCEnabled');
      return result;
    } catch (e) {
      print('NFC durum hatası: $e');
      return false;
    }
  }
  
  // TC Kimlik kartını oku
  static Future<Map<String, String>?> readTCKimlik() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('readTCKimlik');
      if (result != null) {
        return {
          'tcNo': result['tcNo']?.toString() ?? '',
          'ad': result['ad']?.toString() ?? '',
          'soyad': result['soyad']?.toString() ?? '',
          'dogumTarihi': result['dogumTarihi']?.toString() ?? '',
        };
      }
    } catch (e) {
      print('TC Kimlik okuma hatası: $e');
    }
    return null;
  }
  
  // NFC ayarlarına yönlendir
  static Future<void> openNFCSettings() async {
    try {
      await _channel.invokeMethod('openNFCSettings');
    } catch (e) {
      print('NFC ayarları açma hatası: $e');
    }
  }
  
  // Yetkili admin TC listesini kaydet
  static Future<void> saveAuthorizedAdmins(List<String> tcNumbers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('authorized_admin_tc_list', tcNumbers);
  }
  
  // Firebase'den yetkili admin kontrolü
  static Future<bool> isAuthorizedAdmin(String tcNo) async {
    try {
      print('🔍 Firebase\'de TC kontrol ediliyor: $tcNo');
      
      final doc = await FirebaseFirestore.instance
          .collection('yönetici_tc')
          .doc(tcNo)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final isActive = data['aktif'] ?? false;
        final adminName = data['ad_soyad'] ?? 'Bilinmeyen';
        
        print('✅ TC bulundu: $adminName, Aktif: $isActive');
        return isActive;
      } else {
        print('❌ TC bulunamadı: $tcNo');
        return false;
      }
    } catch (e) {
      print('❌ Firebase TC kontrol hatası: $e');
      return false;
    }
  }
  
  // Firebase'e örnek yetkili admin ekle
  static Future<void> addAuthorizedAdminToFirebase(String tcNo, String adSoyad) async {
    try {
      await FirebaseFirestore.instance
          .collection('yönetici_tc')
          .doc(tcNo)
          .set({
        'tc_no': tcNo,
        'ad_soyad': adSoyad,
        'aktif': true,
        'ekleme_tarihi': FieldValue.serverTimestamp(),
        'son_giris': null,
      });
      print('✅ Yetkili admin Firebase\'e eklendi: $adSoyad ($tcNo)');
    } catch (e) {
      print('❌ Firebase admin ekleme hatası: $e');
    }
  }
  
  // Son giriş tarihini güncelle
  static Future<void> updateLastLogin(String tcNo) async {
    try {
      await FirebaseFirestore.instance
          .collection('yönetici_tc')
          .doc(tcNo)
          .update({
        'son_giris': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Son giriş güncelleme hatası: $e');
    }
  }
}