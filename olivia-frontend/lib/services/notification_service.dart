import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../storage/auth_storage.dart';
import '../network/api_config.dart';

class NotificationService {
  final String baseUrl = ApiConfig.baseUrl;

  Future<Map<String, String>> _headers() async {
    final token = await AuthStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ""}',
    };
  }

  /// Mengambil semua riwayat pemberitahuan (Paginasi Laravel)
  Future<List<Map<String, dynamic>>> getAllNotifications({int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/all?page=$page'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final rawData = data['data'];
          if (rawData is Map && rawData['data'] is List) {
            return List<Map<String, dynamic>>.from(rawData['data']);
          } else if (rawData is List) {
            return List<Map<String, dynamic>>.from(rawData);
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error getAllNotifications: $e");
      return [];
    }
  }

  /// Mengambil notifikasi yang belum dibaca saja
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error getUnreadNotifications: $e");
      return [];
    }
  }

  /// Mengambil jumlah notifikasi yang belum dibaca
  Future<int> getUnreadCount() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/count'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['unread_count'] != null) {
          return int.parse(data['unread_count'].toString());
        }
      }
      return 0;
    } catch (e) {
      debugPrint("Error getUnreadCount: $e");
      return 0;
    }
  }

  /// Menandai satu notifikasi telah dibaca
  Future<bool> markAsRead(String id) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$id/read'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error markAsRead: $e");
      return false;
    }
  }

  /// Menandai semua notifikasi telah dibaca
  Future<bool> markAllAsRead() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error markAllAsRead: $e");
      return false;
    }
  }

  /// Mengambil riwayat proses pemurnian yang dikelompokkan berdasarkan nomor siklus
  Future<Map<String, List<dynamic>>> getProcessHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/process-history'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] is Map) {
          final Map<String, dynamic> rawMap = data['data'];
          Map<String, List<dynamic>> structuredData = {};
          rawMap.forEach((key, value) {
            if (value is List) {
              structuredData[key] = value;
            }
          });
          return structuredData;
        }
      }
      return {};
    } catch (e) {
      debugPrint("Error getProcessHistory: $e");
      return {};
    }
  }
}
