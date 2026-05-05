import 'package:get/get.dart';
import '../services/telemetry_service.dart';

class HistoryController extends GetxController {
  // --- State Variables ---
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // --- Data Lists ---
  var arangHistory = <dynamic>[].obs;
  var bleachingHistory = <dynamic>[].obs;
  var validasiHistory = <dynamic>[].obs;

  final TelemetryService _telemetryService = TelemetryService();

  @override
  void onInit() {
    super.onInit();
    // Tarik data saat controller dipanggil
    fetchHistoryData();
  }

  // --- Fungsi Tarik Data dari API ---
  Future<void> fetchHistoryData() async {
    try {
      isLoading(true);
      errorMessage('');

      // Memanggil fungsi fetchHistory() dari TelemetryService
      final data = await _telemetryService.fetchHistory();

      // Memasukkan data ke dalam list observable
      if (data['arang'] != null) {
        arangHistory.assignAll(data['arang']);
      }
      if (data['bleaching'] != null) {
        bleachingHistory.assignAll(data['bleaching']);
      }
      if (data['validasi'] != null) {
        validasiHistory.assignAll(data['validasi']);
      }
    } catch (e) {
      errorMessage('Gagal mengambil data riwayat.');
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    } finally {
      isLoading(false);
    }
  }

  // Fungsi untuk refresh manual via RefreshIndicator di UI
  Future<void> refreshData() async {
    await fetchHistoryData();
  }
}
