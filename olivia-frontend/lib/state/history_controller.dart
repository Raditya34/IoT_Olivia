import 'package:get/get.dart';
import '../services/telemetry_service.dart';

class HistoryController extends GetxController {
  var isLoading = true.obs;
  var arangHistory = <dynamic>[].obs;
  var bleachingHistory = <dynamic>[].obs;
  var validasiHistory = <dynamic>[].obs;

  final TelemetryService _service = TelemetryService();

  @override
  void onInit() {
    super.onInit();
    fetchHistoryData();
  }

  Future<void> fetchHistoryData() async {
    try {
      isLoading(true);
      final data = await _service
          .fetchHistory(); // Pastikan API mengembalikan data modular

      arangHistory.assignAll(data['arang'] ?? []);
      bleachingHistory.assignAll(data['bleaching'] ?? []);
      validasiHistory.assignAll(data['validasi'] ?? []);
    } catch (e) {
      print("Error History: $e");
    } finally {
      isLoading(false);
    }
  }
}
