import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';

class DashboardController extends GetxController {
  var systemOn = false.obs;
  var progressStep = 0.obs;
  var isLoading = true.obs;

  // --- Variabel ESP1 (Arang) ---
  var arangTemp1 = 0.0.obs; // Suhu 1
  var arangTemp2 = 0.0.obs; // Suhu 2
  var arangTinggi = 0.0.obs; // Tinggi
  var arangVol = 0.0.obs;
  var sparkArangTemp1 = <double>[0.0].obs;
  var sparkArangTemp2 = <double>[0.0].obs;
  var sparkArangVol = <double>[0.0].obs;

  // --- Variabel ESP2 (Bleaching) ---
  var bleachTemp = 0.0.obs;
  var sparkBleachTemp = <double>[0.0].obs;
  var bleachValve = false.obs;
  var bleachP1 = false.obs;
  var bleachP2 = false.obs;
  var bleachP3 = false.obs;
  var bleachH1 = false.obs;
  var bleachH2 = false.obs;
  var bleachH3 = false.obs;
  var bleachH4 = false.obs;
  var bleachSpeed = 0.obs;

  // --- Variabel ESP3 (Validasi) ---
  var validasiTinggi = 0.0.obs;
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs; // Pengganti turbidity
  var freq = 0.0.obs; // Pengganti viskositas
  var tegangan = 0.0.obs;
  var r = 0.obs; // Red
  var g = 0.obs; // Green
  var b = 0.obs; // Blue
  var warnaLabel = '-'.obs; // Label warna otomatis dari RGB

  final ApiService _api = ApiService();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    // Auto-refresh setiap 3 detik
    _timer =
        Timer.periodic(const Duration(seconds: 3), (_) => fetchDashboardData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Helper aman untuk parse double
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Helper aman untuk parse integer (untuk RGB & Speed)
  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Helper konversi RGB menjadi Label Warna
  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return 'Menunggu Data';
    if (r > 200 && g > 200) return 'Kuning Cerah (Sangat Layak)';
    if (r > 170 && g > 150) return 'Kuning Kecoklatan (Layak)';
    if (r > 100 && g < 150) return 'Coklat (Kurang Layak)';
    return 'Coklat Pekat (Tidak Layak)';
  }

  Future<void> fetchDashboardData() async {
    try {
      final response = await _api.get('/dashboard');

      if (response != null && response['success'] == true) {
        systemOn.value =
            response['system_status'] == true || response['system_status'] == 1;

        var data = response;

        // --- MAPPING DATA UNIT 1 (ARANG) ---
        if (data['arang'] != null) {
          var d1 = data['arang'];
          arangTemp1.value = _toDouble(d1['suhu1']);
          arangTemp2.value = _toDouble(d1['suhu2']);
          arangTinggi.value = _toDouble(d1['tinggi']);
          arangVol.value = _toDouble(d1['volume']);

          _updateSparkline(sparkArangTemp1, arangTemp1.value);
          _updateSparkline(sparkArangTemp2, arangTemp2.value);
          _updateSparkline(sparkArangVol, arangVol.value);
        }

        // --- MAPPING DATA UNIT 2 (BLEACHING) ---
        if (data['bleaching'] != null) {
          var d2 = data['bleaching'];
          bleachTemp.value = _toDouble(d2['suhu']);
          bleachValve.value = d2['valve'] == 1 || d2['valve'] == true;
          bleachP1.value = d2['pompa_1'] == 1 || d2['pompa_1'] == true;
          bleachP2.value = d2['pompa_2'] == 1 || d2['pompa_2'] == true;
          bleachP3.value = d2['pompa_3'] == 1 || d2['pompa_3'] == true;
          bleachH1.value = d2['heater_1'] == 1 || d2['heater_1'] == true;
          bleachH2.value = d2['heater_2'] == 1 || d2['heater_2'] == true;
          bleachH3.value = d2['heater_3'] == 1 || d2['heater_3'] == true;
          bleachH4.value = d2['heater_4'] == 1 || d2['heater_4'] == true;
          bleachSpeed.value = _toInt(d2['motor_ac_speed']);

          _updateSparkline(sparkBleachTemp, bleachTemp.value);
        }

        // --- MAPPING DATA UNIT 3 (VALIDASI) ---
        if (data['validasi'] != null) {
          var d3 = data['validasi'];
          validasiTinggi.value = _toDouble(d3['tinggi']);
          validasiVol.value = _toDouble(d3['volume']);
          ntu.value = _toDouble(d3['ntu']);
          freq.value = _toDouble(d3['freq']);
          tegangan.value = _toDouble(d3['tegangan']);
          r.value = _toInt(d3['r']);
          g.value = _toInt(d3['g']);
          b.value = _toInt(d3['b']);

          // Update label warna otomatis tiap kali data masuk
          warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
        }

        // Hitung Progress Step Alur Kerja
        if (validasiVol.value > 0) {
          progressStep.value = 2;
        } else if (bleachTemp.value > 0 || bleachP1.value) {
          progressStep.value = 1;
        } else {
          progressStep.value = 0;
        }
      }
    } catch (e) {
      print("Dashboard Data Parsing Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _updateSparkline(RxList<double> list, double newValue) {
    list.add(newValue);
    if (list.length > 10) list.removeAt(0);
  }

  Future<void> toggleSystem() async {
    final newState = !systemOn.value;
    systemOn.value = newState;

    try {
      final response = await _api.post('/control', {'system_on': newState});

      if (response != null && response['success'] == true) {
        Get.snackbar('Berhasil',
            'Sistem berhasil di${newState ? 'nyalakan' : 'matikan'}');
      } else {
        systemOn.value = !newState; // Rollback
        Get.snackbar('Gagal', 'Tidak dapat mengubah status sistem');
      }
    } catch (e) {
      systemOn.value = !newState; // Rollback
      Get.snackbar('Error', 'Terjadi kesalahan jaringan: $e');
    }
  }
}
