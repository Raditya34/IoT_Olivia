import 'api_service.dart';

class TelemetryService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> fetchHistory() async {
    try {
      // Mengambil data history dari endpoint Laravel
      final res = await _api.get('/history');

      // Karena ApiService sudah melakukan jsonDecode, langsung return res
      return res as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Gagal ambil data history: $e');
    }
  }
}
