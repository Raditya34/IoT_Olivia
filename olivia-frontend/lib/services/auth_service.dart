import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../network/api_config.dart';

class AuthService {
  static String baseUrl = ApiConfig.baseUrl;

  Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan dari server');
      }
      await AuthStorage.saveToken(token);
      return;
    }

    throw Exception(_err(data));
  }

  Future<void> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 201) {
      // kamu bisa pilih:
      // 1) auto-login (simpan token jika ada)
      final token = data['token'] as String?;
      if (token != null && token.isNotEmpty) {
        await AuthStorage.saveToken(token);
      }
      return;
    }

    throw Exception(_err(data));
  }

  String _err(dynamic data) {
    if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final k = errors.keys.first;
        final v = errors[k];
        if (v is List && v.isNotEmpty) return v.first.toString();
      }
    }
    if (data is Map && data['message'] != null)
      return data['message'].toString();
    return 'Terjadi kesalahan';
  }
}
