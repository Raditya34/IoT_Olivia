// lib/storage/auth_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'token';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';

  /// Menyimpan data autentikasi setelah login
  static Future<void> saveAuthData({
    required String token,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setBool('logged_in', true);
  }

  /// Mengambil token untuk Authorization Header
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Mengambil Nama User
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  /// Mengambil Email User
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Menghapus semua data session saat logout atau token expired
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.setBool('logged_in', false);
  }
}
