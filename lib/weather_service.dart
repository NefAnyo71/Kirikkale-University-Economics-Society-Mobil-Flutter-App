import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Weather API constants - wttr.in
const String WEATHER_BASE_URL = 'https://wttr.in/Kirikkale';
const String WEATHER_FORMAT = '?format=j1';

// Weather data model
class WeatherData {
  final double temperature;
  final String description;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // wttr.in JSON format
    final current = json['current_condition'][0];
    return WeatherData(
      temperature: double.parse(current['temp_C']),
      description: current['weatherDesc'][0]['value'],
      icon: _getIconFromDescription(current['weatherDesc'][0]['value']),
    );
  }

  static String _getIconFromDescription(String desc) {
    final lower = desc.toLowerCase();
    if (lower.contains('sunny') || lower.contains('clear')) return '01d';
    if (lower.contains('cloudy')) return '03d';
    if (lower.contains('rain')) return '10d';
    if (lower.contains('snow')) return '13d';
    if (lower.contains('thunder')) return '11d';
    return '02d';
  }
}

// Weather service
class WeatherService {
  static Future<WeatherData?> getCurrentWeather() async {
    try {
      final url = '$WEATHER_BASE_URL$WEATHER_FORMAT';
      print('🌤️ wttr.in URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'curl/7.68.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['current_condition'][0]['temp_C'];
        print('✅ wttr.in Başarılı: Kırıkkale - ${temp}°C');
        return WeatherData.fromJson(data);
      } else {
        print('❌ wttr.in Error ${response.statusCode}');
        return _getMockWeatherData();
      }
    } catch (e) {
      print('❌ wttr.in hatası: $e');
      return _getMockWeatherData();
    }
  }

  static WeatherData _getMockWeatherData() {
    final random = DateTime.now().millisecond;
    final temp = 15 + (random % 20);
    final icons = ['01d', '02d', '03d', '04d', '09d', '10d'];

    return WeatherData(
      temperature: temp.toDouble(),
      description: 'Clear',
      icon: icons[random % icons.length],
    );
  }

  static IconData getWeatherIcon(String iconCode) {
    switch (iconCode.substring(0, 2)) {
      case '01':
        return Icons.wb_sunny; // clear sky
      case '02':
        return Icons.wb_cloudy; // few clouds
      case '03':
        return Icons.cloud; // scattered clouds
      case '04':
        return Icons.cloud; // broken clouds
      case '09':
        return Icons.grain; // shower rain
      case '10':
        return Icons.grain; // rain
      case '11':
        return Icons.flash_on; // thunderstorm
      case '13':
        return Icons.ac_unit; // snow
      case '50':
        return Icons.blur_on; // mist
      default:
        return Icons.wb_cloudy;
    }
  }
}