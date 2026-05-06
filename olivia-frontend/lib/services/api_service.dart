import 'dart:convert';
import 'dart:io'; // Tambahkan ini untuk handle SocketException
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../../../network/api_config.dart'; // PERBAIKAN: Tambahkan ../ agar keluar folder services dulu

class ApiService {
  static String baseUrl = ApiConfig.baseUrl;

  /// Ambil header dengan token autentikasi
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}', // Cegah null token
    };
  }

  /// Handle respon dari server
  dynamic _handleResponse(http.Response response) {
    // Jika sesi habis (Token salah/expired)
    if (response.statusCode == 401 || response.statusCode == 403) {
      AuthStorage.clear();
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    // Jika respon sukses (200, 201)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    // Jika terjadi error (400, 404, 500, dll)
    try {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ??
          errorBody['error'] ??
          'Server Error: ${response.statusCode}');
    } catch (e) {
      // Jika body bukan JSON (misal Railway kirim HTML error)
      throw Exception('Terjadi kesalahan pada server (${response.statusCode})');
    }
  }

  /// METHOD GET
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _authHeaders(),
          )
          .timeout(const Duration(
              seconds: 15)); // Tambahkan timeout agar tidak loading selamanya

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

  /// METHOD POST (TANPA AUTH - LOGIN/REGISTER)
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
      throw Exception('Gagal terhubung ke server. Periksa sinyal anda.');
    } catch (e) {
      rethrow;
    }
  }
}
