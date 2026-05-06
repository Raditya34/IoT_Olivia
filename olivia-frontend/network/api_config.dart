import 'package:flutter/foundation.dart';

class ApiConfig {
  /// URL Backend Production di Railway
  static final String baseUrl = kReleaseMode
      ? 'https://iotolivia-production.up.railway.app/api'
      : 'https://iotolivia-production.up.railway.app/api'; // Diset sama agar saat debug data tetap muncul

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
