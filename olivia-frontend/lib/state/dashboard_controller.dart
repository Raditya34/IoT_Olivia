// lib/state/dashboard_controller.dart
import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  var systemOn = false.obs;
  var progressStep = 0.obs;
  var isLoading = true.obs;

  // --- Variabel Proses 1 (Arang) ---
  var suhuArang = 0.0.obs;
  var sparkSuhuArang = <double>[0.0].obs;
  var arangVol = 0.0.obs;

  // --- Variabel Proses 2 (Bleaching) ---
  var suhuBleaching = 0.0.obs;
  var sparkSuhuBleaching = <double>[0.0].obs;
  var bleachValve = false.obs;
  var bleachP1 = false.obs;
  var bleachP2 = false.obs;
  var bleachP3 = false.obs;
  var bleachH1 = false.obs;
  var bleachH2 = false.obs;
  var bleachH3 = false.obs;
  var bleachH4 = false.obs;
  var bleachSpeed = 0.obs;

  // --- Variabel Proses 3 (Validasi / Filtrasi) ---
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;
  var warnaLabel = 'Menunggu Data...'.obs;

  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    // Jalankan pooling periodik jika sistem aktif untuk pemantauan real-time
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (systemOn.value) {
        fetchDashboardData();
      }
    });
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchDashboardData() async {
    try {
      if (isLoading.value && sparkSuhuArang.length <= 1) {
        isLoading.value = true;
      }

      final response = await _api.get('/dashboard/telemetry');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];

        systemOn.value = data['system_on'] ?? false;

        // Parsing Data Proses 1: Arang
        if (data['arang'] != null) {
          var d1 = data['arang'];
          suhuArang.value = _toDouble(d1['suhu_arang']);
          _updateSparkline(sparkSuhuArang, suhuArang.value);
        }

        // Parsing Data Proses 2: Bleaching
        if (data['bleaching'] != null) {
          var d2 = data['bleaching'];
          suhuBleaching.value = _toDouble(d2['suhu_bleaching']);
          _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);

          bleachValve.value = d2['valve'] ?? false;
          bleachP1.value = d2['p1'] ?? false;
          bleachP2.value = d2['p2'] ?? false;
          bleachP3.value = d2['p3'] ?? false;
          bleachH1.value = d2['h1'] ?? false;
          bleachH2.value = d2['h2'] ?? false;
          bleachH3.value = d2['h3'] ?? false;
          bleachH4.value = d2['h4'] ?? false;
          bleachSpeed.value = _toInt(d2['speed']);
        }

        // Parsing Data Proses 3: Validasi (Filtrasi)
        if (data['validasi'] != null) {
          var d3 = data['validasi'];
          validasiVol.value = _toDouble(d3['volume']);
          ntu.value = _toDouble(d3['turbidity']);
          viscosity.value = _toDouble(d3['viscosity']);
          r.value = _toInt(d3['r']);
          g.value = _toInt(d3['g']);
          b.value = _toInt(d3['b']);

          // Update label klasifikasi warna minyak otomatis
          warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
        }

        // Hitung Progress Step Alur Kerja Aktual
        if (validasiVol.value > 0 || ntu.value > 0) {
          progressStep.value = 2;
        } else if (suhuBleaching.value > 0 || bleachP1.value) {
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
        fetchDashboardData();
      } else {
        systemOn.value = !newState; // Rollback status
        Get.snackbar('Gagal', 'Gagal mengubah status kontrol sistem');
      }
    } catch (e) {
      systemOn.value = !newState; // Rollback status
      Get.snackbar('Error', 'Terjadi kesalahan jaringan: $e');
    }
  }

  // Fungsi Klasifikasi Range Kualitas Warna Minyak Goreng
  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return 'Menunggu Data...';
    int brightness = (r + g + b) ~/ 3;

    if (brightness > 180 && b > 100) {
      return 'Jernih (Sangat Layak)';
    } else if (brightness > 120) {
      return 'Agak Jernih (Cukup Layak)';
    } else if (brightness > 60) {
      return 'Coklat Kekuningan (Kurang Layak)';
    } else {
      return 'Coklat Kotor (Tidak Layak)';
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? 0;
  }
}
