// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String baseUrl =
      'https://iotolivia-production.up.railway.app/api';

  // Ambil notifikasi unread
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Gagal ambil notifikasi');
  }

  // Ambil semua notifikasi
  Future<List<Map<String, dynamic>>> getAllNotifications({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/all?page=$page'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data']?['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Gagal ambil notifikasi');
  }

  // Hitung notifikasi unread (untuk badge)
  Future<int> getUnreadCount() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return 0;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      final data = jsonDecode(response.body);
      return data['unread_count'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Mark notifikasi sebagai read
  Future<void> markAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal mark notifikasi');
    }
  }

  // Mark semua notifikasi sebagai read
  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Gagal mark semua notifikasi');
    }
  }

  // Ambil riwayat proses (timeline)
  Future<Map<String, dynamic>> getProcessHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/process-history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      return data['data'] ?? {};
    }

    throw Exception(data['message'] ?? 'Gagal ambil riwayat proses');
  }

  // Ambil history cycle sekarang saja
  Future<List<Map<String, dynamic>>> getCurrentCycleHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) throw Exception('Token tidak ditemukan');

    final response = await http.get(
      Uri.parse('$baseUrl/process-history/current'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      return List<Map<String, dynamic>>.from(data['data'] ?? []);
    }

    throw Exception(data['message'] ?? 'Gagal ambil history');
  }
}
