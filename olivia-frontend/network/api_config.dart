import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Flutter Web (Chrome)
      return 'http://localhost:8000/api';
    }
    // Mobile / device fisik (WiFi sama dengan backend)
    return 'http://192.168.1.3:8000/api';
  }
}
