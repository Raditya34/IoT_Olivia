import 'package:flutter/foundation.dart';

class ApiConfig {
  /// URL Backend sudah diarahkan ke Railway sesuai .env kamu
  static final String baseUrl = kReleaseMode
      ? 'https://iotolivia-production.up.railway.app/api'
      : 'https://iotolivia-production.up.railway.app/api';
  // Catatan: Saya ubah mode lokal dan release sama-sama ke online
  // agar kamu bisa langsung testing dari laptop ke server asli.

  static const int connectTimeout = 15000; // 15 detik
  static const int receiveTimeout = 15000; // 15 detik

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
