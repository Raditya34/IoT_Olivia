import 'package:flutter/foundation.dart';

class ApiConfig {
  /// URL Backend local untuk development dan staging.
  /// Release mode akan menggunakan URL production.
  static final String baseUrl = kReleaseMode
      ? 'https://olivia-production.up.railway.app/api'
      : 'http://localhost:8000/api';

  /// Batas waktu tunggu koneksi (dalam milidetik).
  /// Sangat penting untuk mencegah aplikasi loading selamanya saat sinyal lemah.
  static const int connectTimeout = 15000; // 15 detik
  static const int receiveTimeout = 15000; // 15 detik

  /// Header standar untuk permintaan API
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
