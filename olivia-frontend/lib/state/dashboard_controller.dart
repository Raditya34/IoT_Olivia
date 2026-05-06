import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';

class DashboardController extends GetxController {
  // --- State Utama ---
  var systemOn = false.obs;
  var progressStep = 0.obs; // Memperbaiki error: 'progressStep' isn't defined
  var isLoading = true.obs;

  // --- Data Sensor (Unit 1: Arang) ---
  var arangTemp = 0.0.obs;
  var arangVol = 0.0.obs;
  // Memperbaiki error: 'sparkArangTemp' & 'sparkArangVol' isn't defined
  var sparkArangTemp = <double>[0.0].obs;
  var sparkArangVol = <double>[0.0].obs;

  // --- Data Sensor (Unit 2: Bleaching) ---
  var bleachTemp = 0.0.obs;
  // Memperbaiki error: 'sparkBleachTemp' isn't defined
  var sparkBleachTemp = <double>[0.0].obs;
  var bleachValve = false.obs;
  var bleachP1 = false.obs;
  var bleachP2 = false.obs;
  var bleachP3 = false.obs;
  var bleachH1 = false.obs;
  var bleachH2 = false.obs;
  var bleachSpeed = 0.obs;

  // --- Data Sensor (Unit 3: Validasi) ---
  var validasiVol = 0.0.obs;
  var turb = 0.0.obs;
  var visc = 0.0.obs;
  var warna = '-'.obs;

  final ApiService _api = ApiService();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    // Polling setiap 3 detik
    _timer =
        Timer.periodic(const Duration(seconds: 3), (_) => fetchDashboardData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> fetchDashboardData() async {
    try {
      final response = await _api.get('/dashboard');

      if (response['success'] == true) {
        systemOn.value = response['system_status'] ?? false;

        // Update Unit 1 & Riwayat Grafik
        var d1 = response['arang'];
        arangTemp.value = (d1['suhu'] ?? 0).toDouble();
        arangVol.value = (d1['volume'] ?? 0).toDouble();
        _updateSparkline(sparkArangTemp, arangTemp.value);
        _updateSparkline(sparkArangVol, arangVol.value);

        // Update Unit 2 & Riwayat Grafik
        var d2 = response['bleaching'];
        bleachTemp.value = (d2['suhu'] ?? 0).toDouble();
        _updateSparkline(sparkBleachTemp, bleachTemp.value);
        bleachValve.value = d2['valve'] ?? false;
        bleachP1.value = d2['pompa_1'] ?? false;
        bleachP2.value = d2['pompa_2'] ?? false;
        bleachP3.value = d2['pompa_3'] ?? false;
        bleachH1.value = d2['heater_1'] ?? false;
        bleachH2.value = d2['heater_2'] ?? false;
        bleachSpeed.value = d2['motor_ac_speed'] ?? 0;

        // Update Unit 3
        var d3 = response['validasi'];
        validasiVol.value = (d3['volume'] ?? 0).toDouble();
        turb.value = (d3['turbidity'] ?? 0).toDouble();
        visc.value = (d3['viskositas'] ?? 0).toDouble();
        warna.value = d3['warna'] ?? '-';

        // Logika sederhana penentu Step di Timeline
        if (validasiVol.value > 0) {
          progressStep.value = 2;
        } else if (bleachTemp.value > 30) {
          progressStep.value = 1;
        } else {
          progressStep.value = 0;
        }
      }
    } catch (e) {
      print("Error fetching dashboard: $e");
    } finally {
      isLoading(false);
    }
  }

  void _updateSparkline(RxList<double> list, double newValue) {
    list.add(newValue);
    if (list.length > 10) list.removeAt(0);
  }

  Future<void> toggleSystem() async {
    final newState = !systemOn.value;
    try {
      final response = await _api.post('/control', {'system_on': newState});
      if (response['success'] == true) {
        systemOn.value = response['system_on'];
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengubah status sistem');
    }
  }
}
