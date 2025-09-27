import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class LocalStorageService {
  static const String _derslerKey = 'dersler';
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  LocalStorageService._();

  // Dersleri kaydet
  Future<void> saveDers(Map<String, dynamic> ders) async {
    final dersler = await getDersler();
    final index = dersler.indexWhere((d) => d['ad'] == ders['ad']);
    
    if (index != -1) {
      dersler[index] = ders;
    } else {
      dersler.add(ders);
    }

    await _prefs!.setString(_derslerKey, jsonEncode(dersler));
  }

  // Tüm dersleri getir
  Future<List<Map<String, dynamic>>> getDersler() async {
    final derslerJson = _prefs!.getString(_derslerKey);
    if (derslerJson == null) return [];

    final List<dynamic> decoded = jsonDecode(derslerJson);
    return List<Map<String, dynamic>>.from(decoded);
  }

  // Ders sil
  Future<void> deleteDers(String dersAdi) async {
    final dersler = await getDersler();
    dersler.removeWhere((d) => d['ad'] == dersAdi);
    await _prefs!.setString(_derslerKey, jsonEncode(dersler));
  }

  // Görselleri uygulama dizinine kopyala
  static Future<File> copyFileToAppDir(File sourceFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(sourceFile.path)}';
    final File newImage = await sourceFile.copy('${appDir.path}/$fileName');
    return newImage;
  }

  // Uygulama dizinindeki tüm dosyaları getir
  static Future<List<File>> getAppDirectoryFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);
      final List<File> files = [];
      
      await for (var entity in directory.list(recursive: false)) {
        if (entity is File) {
          files.add(entity);
        }
      }
      
      return files;
    } catch (e) {
      return [];
    }
  }

  // Kullanılmayan dosyaları temizle
  static Future<void> cleanUnusedFiles(List<String> usedFilePaths) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final directory = Directory(appDir.path);
      
      await for (var entity in directory.list(recursive: false)) {
        if (entity is File && !usedFilePaths.contains(entity.path)) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('Dosya temizleme hatası: $e');
    }
  }
}
