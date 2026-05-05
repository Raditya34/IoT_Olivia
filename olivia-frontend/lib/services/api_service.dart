import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../network/api_config.dart';

class ApiService {
  static String baseUrl = ApiConfig.baseUrl;

  /// Header untuk endpoint yang BUTUH login
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token tidak tersedia, silakan login ulang');
    }

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// 🔥 HANDLE RESPONSE & DECODE JSON
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      AuthStorage.clear(); // Hapus token jika kadaluarsa
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    if (response.statusCode >= 400) {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ??
            errorBody['error'] ??
            'API Error: ${response.statusCode}');
      } catch (e) {
        throw Exception('Terjadi kesalahan server (${response.statusCode})');
      }
    }

    // Langsung kembalikan data berupa Map/List
    return jsonDecode(response.body);
  }

  /// GET dengan auth
  Future<dynamic> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: await _authHeaders(),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Koneksi timeout - server tidak merespons'),
          );

      return _handleResponse(response);
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception(
            'Tidak dapat terhubung ke server - periksa koneksi internet');
      }
      rethrow;
    }
  }

  /// POST dengan auth
  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// POST TANPA auth (login / register)
  Future<dynamic> postPublic(String endpoint, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw Exception('Koneksi timeout - server tidak merespons'),
          );

      if (response.statusCode >= 400) {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['message'] ??
              errorBody['error'] ??
              'API Error: ${response.statusCode}');
        } catch (e) {
          throw Exception('Gagal menghubungi server (${response.statusCode})');
        }
      }

      return jsonDecode(response.body);
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception(
            'Tidak dapat terhubung ke server - periksa koneksi internet');
      }
      rethrow;
    }
  }
}
