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

  /// 🔥 HANDLE RESPONSE (INI KUNCI AUTH V2)
  http.Response _handleResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized');
    }

    if (response.statusCode >= 400) {
      throw Exception(
        'API Error ${response.statusCode}: ${response.body}',
      );
    }

    return response;
  }

  /// GET dengan auth
  Future<http.Response> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
    );

    return _handleResponse(response);
  }

  /// POST dengan auth
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _authHeaders(),
      body: jsonEncode(body),
    );

    return _handleResponse(response);
  }

  /// POST TANPA auth (login / register)
  Future<http.Response> postPublic(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'Public API Error ${response.statusCode}: ${response.body}',
      );
    }

    return response;
  }
}
