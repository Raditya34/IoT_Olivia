import 'dart:convert';
import 'api_service.dart';

class TelemetryService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> fetchTelemetry() async {
    final res = await _api.get('/telemetry');

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception('Gagal ambil telemetry');
  }
}
