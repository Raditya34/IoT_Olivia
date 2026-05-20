import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../network/api_config.dart';

class ApiService {
  static String baseUrl = ApiConfig.baseUrl;

  /// Ambil header dengan token autentikasi dari storage
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization':
          'Bearer ${token ?? ""}', // Mengirimkan Bearer Token ke Laravel
    };
  }

  /// Handle respon dari server secara terpusat
  dynamic _handleResponse(http.Response response) {
    // Jika sesi habis atau token tidak valid (401 / 403)
    if (response.statusCode == 401 || response.statusCode == 403) {
      AuthStorage.clear(); // Bersihkan token yang tidak valid
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    // Jika respon sukses (200, 201)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    // Jika terjadi error dari server (400, 500, dll)
    try {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Terjadi kesalahan server.');
    } catch (e) {
      throw Exception('Server error dengan status: ${response.statusCode}');
    }
  }

  /// METHOD GET (DENGAN AUTH) - Kunci Perbaikan Utama 🔑
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers:
                await _authHeaders(), // <-- WAJIB ADA AGAR TIDAK REJECTED 401
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } catch (e) {
      rethrow;
    }
  }

  /// METHOD POST (DENGAN AUTH)
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _authHeaders(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } catch (e) {
      rethrow;
    }
  }

  /// METHOD POST (TANPA AUTH - UNTUK LOGIN / REGISTER)
  Future<dynamic> postPublic(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } catch (e) {
      rethrow;
    }
  }
}
