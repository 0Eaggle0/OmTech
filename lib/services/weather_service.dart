import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_prefs.dart';

/// Текущая погода в Омске.
class WeatherInfo {
  final double tempC;
  final int weatherCode;
  final DateTime fetchedAt;

  const WeatherInfo({
    required this.tempC,
    required this.weatherCode,
    required this.fetchedAt,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) => WeatherInfo(
        tempC: (json['tempC'] as num).toDouble(),
        weatherCode: (json['weatherCode'] as num).toInt(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'tempC': tempC,
        'weatherCode': weatherCode,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  /// Иконка по коду погоды (стандарт WMO, его же отдаёт Open-Meteo).
  IconData get icon {
    if (weatherCode == 0) return Icons.wb_sunny_outlined;
    if (weatherCode <= 3) return Icons.cloud_outlined;
    if (weatherCode <= 48) return Icons.foggy;
    if (weatherCode <= 67) return Icons.water_drop_outlined;
    if (weatherCode <= 77) return Icons.ac_unit;
    if (weatherCode <= 82) return Icons.grain;
    if (weatherCode <= 99) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }
}

/// Погода в Омске с сайта Open-Meteo — без ключа API, без новой зависимости
/// (используется уже подключённый `dio`).
///
/// Кэшируется на 30 минут в `SharedPreferences`; при любой ошибке сети
/// вызывающий получает `null` и просто не показывает строку погоды.
class WeatherService {
  static const _lat = 54.9924;
  static const _lon = 73.3686;
  static const _cacheKey = 'weather_cache_v1';
  static const _ttl = Duration(minutes: 30);

  final Dio _client;

  WeatherService({Dio? client}) : _client = client ?? Dio();

  Future<WeatherInfo?> fetch() async {
    final prefs = appPrefs;
    final cached = await _readCache(prefs);
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < _ttl) {
      return cached;
    }

    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': _lat.toString(),
        'longitude': _lon.toString(),
        'current': 'temperature_2m,weather_code',
        'timezone': 'Asia/Omsk',
      });
      final res = await _client.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          validateStatus: (_) => true,
        ),
      );
      if (res.statusCode != 200) return cached;

      final data = jsonDecode(res.data ?? '') as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final info = WeatherInfo(
        tempC: (current['temperature_2m'] as num).toDouble(),
        weatherCode: (current['weather_code'] as num).toInt(),
        fetchedAt: DateTime.now(),
      );
      await prefs.setString(_cacheKey, jsonEncode(info.toJson()));
      return info;
    } catch (_) {
      return cached;
    }
  }

  Future<WeatherInfo?> _readCache(SharedPreferencesAsync prefs) async {
    final raw = await prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return WeatherInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
