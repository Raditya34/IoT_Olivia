// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';

class AuthService {
  static const String baseUrl =
      'https://iotolivia-production.up.railway.app/api';

  Future<void> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['status'] == 'success') {
      return; // Registrasi sukses, user diarahkan ke halaman login
    }

    throw Exception(data['message'] ?? 'Registrasi gagal');
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      // ✅ SINKRONISASI: Simpan token via AuthStorage terpusat
      await AuthStorage.saveAuthData(
        token: data['token'],
        name: data['user']['name'],
        email: data['user']['email'],
      );
      return;
    }

    throw Exception(data['message'] ?? 'Email atau password salah.');
  }

  Future<void> logout() async {
    // ✅ SINKRONISASI: Bersihkan storage terpusat
    await AuthStorage.clear();
  }
}
