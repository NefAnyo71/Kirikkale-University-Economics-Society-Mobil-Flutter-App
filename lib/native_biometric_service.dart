import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NativeBiometricService {
  static const MethodChannel _channel = MethodChannel('com.arifozdemir.ekos/biometric');
  
  // Native biometric özelliklerini kontrol et
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool result = await _channel.invokeMethod('isBiometricAvailable');
      return result;
    } catch (e) {
      print('Native biometric kontrol hatası: $e');
      return false;
    }
  }
  
  // Native biometric authentication
  static Future<bool> authenticateWithBiometric() async {
    try {
      final bool result = await _channel.invokeMethod('authenticateWithBiometric');
      return result;
    } catch (e) {
      print('Native biometric authentication hatası: $e');
      return false;
    }
  }
  
  // Admin bilgilerini kaydet
  static Future<void> saveAdminCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final credentials = {
      'username': username,
      'password': password,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('admin_native_biometric_credentials', json.encode(credentials));
    await prefs.setBool('admin_native_biometric_enabled', true);
  }
  
  // Kayıtlı admin bilgilerini al
  static Future<Map<String, String>?> getSavedAdminCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final credentialsJson = prefs.getString('admin_native_biometric_credentials');
    if (credentialsJson != null) {
      final credentials = json.decode(credentialsJson);
      return {
        'username': credentials['username'],
        'password': credentials['password'],
      };
    }
    return null;
  }
  
  // Biometric giriş durumunu kontrol et
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('admin_native_biometric_enabled') ?? false;
  }
  
  // Biometric ayarlarını temizle
  static Future<void> clearBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_native_biometric_credentials');
    await prefs.setBool('admin_native_biometric_enabled', false);
  }
}