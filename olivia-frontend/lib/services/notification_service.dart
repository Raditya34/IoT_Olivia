import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl =
      'https://iotolivia-production.up.railway.app/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Ambil semua notifikasi
  Future<List<Map<String, dynamic>>> getAllNotifications({int page = 1}) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/all?page=$page'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // Handle Laravel Paginate structure
        if (data['data'] is Map && data['data']['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']['data']);
        }
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // FIX: Tambahkan method markAsRead
  Future<void> markAsRead(String id) async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      print("Error markAsRead: $e");
    }
  }

  // FIX: Sesuaikan dengan api.php (Route::put('/read-all'))
  Future<void> markAllAsRead() async {
    try {
      final token = await _getToken();
      await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      print("Error markAllAsRead: $e");
    }
  }

  Future<Map<String, dynamic>> getProcessHistory() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/process-history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        var rawData = responseData['data'];
        if (rawData is Map) return Map<String, dynamic>.from(rawData);
        if (rawData is List) {
          Map<String, List<dynamic>> grouped = {};
          for (var item in rawData) {
            String cycle = item['cycle_number']?.toString() ?? "0";
            if (!grouped.containsKey(cycle)) grouped[cycle] = [];
            grouped[cycle]!.add(item);
          }
          return grouped;
        }
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
