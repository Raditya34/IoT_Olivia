// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      'https://iotolivia-production.up.railway.app/api';

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['status'] == 'success') {
      return; // Tidak perlu simpan, user diminta login dulu
    }

    throw Exception(data['message'] ?? 'Registrasi gagal');
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      // ✅ Simpan ke SharedPreferences agar ProfilePage bisa baca
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      await prefs.setString('user_name', data['user']['name']);
      await prefs.setString('user_email', data['user']['email']);
      return;
    }

    throw Exception(data['message'] ?? 'Login gagal');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}