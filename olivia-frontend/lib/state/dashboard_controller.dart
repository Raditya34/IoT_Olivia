import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';

class DashboardController extends GetxController {
  // --- State Utama ---
  var systemOn = false.obs;
  var progressStep = 0.obs;

  // --- Data Sensor ---
  var arangTemp = 0.0.obs;
  var arangVol = 0.0.obs;
  var bleachTemp = 0.0.obs;
  var turb = 0.0.obs;
  var visc = 0.0.obs;
  var warna = '-'.obs;

  // --- History untuk Sparkline (Opsional, jika UI butuh array data) ---
  var sparkArangTemp = <double>[].obs;
  var sparkArangVol = <double>[].obs;
  var sparkBleachTemp = <double>[].obs;

  final ApiService _api = ApiService();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // Ambil data pertama kali saat aplikasi dibuka
    fetchDashboardData();

    // Polling API setiap 3 detik agar real-time
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      fetchDashboardData();
    });
  }

  @override
  void onClose() {
    _timer?.cancel(); // Matikan polling saat keluar aplikasi/halaman
    super.onClose();
  }

  // --- Tarik Data dari Laravel ---
  Future<void> fetchDashboardData() async {
    try {
      final response = await _api.get('/dashboard');

      // Update status sistem
      systemOn.value = response['system_status'] ?? false;

      // Update Sensor Arang
      arangTemp.value = (response['arang']['suhu'] ?? 0).toDouble();
      arangVol.value = (response['arang']['volume'] ?? 0).toDouble();
      _pushHistory(sparkArangTemp, arangTemp.value);
      _pushHistory(sparkArangVol, arangVol.value);

      // Update Sensor Bleaching
      bleachTemp.value = (response['bleaching']['suhu'] ?? 0).toDouble();
      _pushHistory(sparkBleachTemp, bleachTemp.value);

      // Update Sensor Validasi
      turb.value = (response['validasi']['turbidity'] ?? 0).toDouble();
      visc.value = (response['validasi']['viskositas'] ?? 0).toDouble();
      warna.value = response['validasi']['warna'] ?? '-';
    } catch (e) {
      // Print error di console saja agar tidak spam popup di layar user
      print("Error fetching data: $e");
    }
  }

  // --- Update Kontrol Aktuator ---
  Future<void> toggleSystem() async {
    final newState = !systemOn.value;
    systemOn.value = newState; // Ubah di UI langsung biar terasa cepat

    try {
      await _api.post('/control', {'system_on': newState});
    } catch (e) {
      systemOn.value = !newState; // Kembalikan nilai jika gagal
      Get.snackbar('Gagal', 'Tidak dapat terhubung ke server kontrol.');
    }
  }

  // --- Helper untuk grafik sparkline (Maks 10 data) ---
  void _pushHistory(RxList<double> list, double value) {
    if (list.length >= 10) list.removeAt(0);
    list.add(value);
  }
}
