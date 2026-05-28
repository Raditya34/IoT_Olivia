import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();
  final MqttService _mqttService = Get.find<MqttService>();

  // =========================================
  // STATE VARIABEL
  // =========================================
  var systemOn = false.obs;
  var isLoading = true.obs;
  var progressStep = 0.obs;

  // --- Proses 1 (Arang) ---
  var suhuArang = 0.0.obs;
  var sparkSuhuArang = <double>[0.0].obs;
  var arangVol = 0.0.obs;

  // --- Proses 2 (Bleaching) ---
  var suhuBleaching = 0.0.obs;
  var sparkSuhuBleaching = <double>[0.0].obs;

  // PENYESUAIAN KEY: Nama variabel Rx disamakan maknanya,
  // namun nanti saat parsing dipastikan menggunakan key pendek (valve, p1, dll)
  var bleachValve = false.obs;
  var bleachP1 = false.obs;
  var bleachP2 = false.obs;
  var bleachP3 = false.obs;
  var bleachH1 = false.obs;
  var bleachH2 = false.obs;
  var bleachH3 = false.obs;
  var bleachH4 = false.obs;
  var bleachSpeed = 0.obs;

  // --- Proses 3 (Validasi) ---
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;
  var warnaLabel = 'Menunggu Data...'.obs;

  @override
  void onInit() {
    super.onInit();
    // 1. Ambil data pertama kali dari API (Database Laravel)
    fetchDashboardData();

    // 2. Dengarkan data real-time dari MQTT
    _mqttService.onMessageReceived = _handleIncomingMqttData;
    _mqttService.subscribe('olivia/master/telemetry');
  }

  // =========================================
  // FUNGSI MENGAMBIL DATA DARI API (HTTP GET)
  // =========================================
  Future<void> fetchDashboardData() async {
    try {
      isLoading(true);
      final response = await _api.get('/dashboard/telemetry');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];

        // Parsing Data System On
        systemOn.value = data['system_on'] ?? false;

        // Parsing Data Arang
        if (data['arang'] != null) {
          suhuArang.value = _toDouble(data['arang']['suhu_arang']);
          arangVol.value = _toDouble(data['arang']['volume_arang']);
          _updateSparkline(sparkSuhuArang, suhuArang.value);
        }

        // Parsing Data Bleaching (SINKRONISASI KEY MISMATCH)
        if (data['bleaching'] != null) {
          final d2 = data['bleaching'];
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
          bleachSpeed.value = d2['speed'] ?? 0;
        }

        // Parsing Data Validasi
        if (data['validasi'] != null) {
          final d3 = data['validasi'];
          validasiVol.value = _toDouble(d3['volume_validasi']);
          ntu.value = _toDouble(d3['turbidity']);
          viscosity.value = _toDouble(d3['viscosity']);
          r.value = d3['r'] ?? 0;
          g.value = d3['g'] ?? 0;
          b.value = d3['b'] ?? 0;
          warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
        }

        _updateProgressStep();
      }
    } catch (e) {
      debugPrint("Error Fetch Dashboard: $e");
    } finally {
      isLoading(false);
    }
  }

  // =========================================
  // FUNGSI MENDENGARKAN DATA REAL-TIME MQTT
  // =========================================
  void _handleIncomingMqttData(String topic, Map<String, dynamic> data) {
    if (topic == 'olivia/master/telemetry') {
      // Update Control System
      if (data.containsKey('system_on')) {
        systemOn.value = data['system_on'];
      }

      // Update Arang
      if (data.containsKey('arang')) {
        final d1 = data['arang'];
        if (d1.containsKey('suhu_arang')) {
          suhuArang.value = _toDouble(d1['suhu_arang']);
          _updateSparkline(sparkSuhuArang, suhuArang.value);
        }
        if (d1.containsKey('volume_arang')) {
          arangVol.value = _toDouble(d1['volume_arang']);
        }
      }

      // Update Bleaching (SINKRONISASI KEY MISMATCH)
      if (data.containsKey('bleaching')) {
        final d2 = data['bleaching'];
        if (d2.containsKey('suhu_bleaching')) {
          suhuBleaching.value = _toDouble(d2['suhu_bleaching']);
          _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
        }
        if (d2.containsKey('valve')) bleachValve.value = d2['valve'];
        if (d2.containsKey('p1')) bleachP1.value = d2['p1'];
        if (d2.containsKey('p2')) bleachP2.value = d2['p2'];
        if (d2.containsKey('p3')) bleachP3.value = d2['p3'];
        if (d2.containsKey('h1')) bleachH1.value = d2['h1'];
        if (d2.containsKey('h2')) bleachH2.value = d2['h2'];
        if (d2.containsKey('h3')) bleachH3.value = d2['h3'];
        if (d2.containsKey('h4')) bleachH4.value = d2['h4'];
        if (d2.containsKey('speed')) bleachSpeed.value = d2['speed'];
      }

      // Update Validasi
      if (data.containsKey('validasi')) {
        final d3 = data['validasi'];
        if (d3.containsKey('volume_validasi'))
          validasiVol.value = _toDouble(d3['volume_validasi']);
        if (d3.containsKey('turbidity')) ntu.value = _toDouble(d3['turbidity']);
        if (d3.containsKey('viscosity'))
          viscosity.value = _toDouble(d3['viscosity']);
        if (d3.containsKey('r')) r.value = d3['r'];
        if (d3.containsKey('g')) g.value = d3['g'];
        if (d3.containsKey('b')) b.value = d3['b'];
        warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
      }

      _updateProgressStep();
    }
  }

  // =========================================
  // FUNGSI TOGGLE ON/OFF SISTEM (AKTUATOR)
  // =========================================
  Future<void> toggleSystem(bool newState) async {
    // Optimistic UI update (Berubah di UI seketika)
    systemOn.value = newState;

    try {
      // 1. Update ke Backend API Laravel
      final response = await _api.post('/control', {'system_on': newState});

      if (response != null && response['success'] == true) {
        Get.snackbar('Berhasil',
            'Sistem berhasil di${newState ? 'nyalakan' : 'matikan'}');

        // 2. JALUR GANDA: Publikasikan juga perintah kontrol ke MQTT untuk respon cepat alat ESP32
        _mqttService.publish('olivia/control', {
          'system_on': newState,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      } else {
        // Rollback jika API gagal
        systemOn.value = !newState;
        Get.snackbar('Gagal', 'Gagal mengubah status kontrol sistem');
      }
    } catch (e) {
      // Rollback jika terjadi error koneksi
      systemOn.value = !newState;
      Get.snackbar('Error', 'Terjadi kesalahan jaringan: $e');
    }
  }

  // =========================================
  // LOGIKA STATUS PROGRESS UI
  // =========================================
  void _updateProgressStep() {
    if (!systemOn.value) {
      progressStep.value = 0;
    } else if (bleachP2.value || validasiVol.value > 0) {
      progressStep.value = 3; // Sedang di tahap validasi akhir
    } else if (bleachP1.value || suhuBleaching.value > 30) {
      progressStep.value = 2; // Sedang di tahap bleaching
    } else if (suhuArang.value > 30) {
      progressStep.value = 1; // Sedang di tahap pemanasan arang
    } else {
      progressStep.value = 0;
    }
  }

  // =========================================
  // HELPER FUNCTIONS
  // =========================================
  void _updateSparkline(RxList<double> list, double value) {
    if (value > 0) {
      list.add(value);
      if (list.length > 15) list.removeAt(0); // Batasi maksimal 15 titik grafik
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return 'Menunggu Data...';
    int brightness = (r + g + b) ~/ 3;
    if (brightness > 180 && b > 100) return 'Jernih (Sangat Layak)';
    if (brightness > 120) return 'Agak Jernih (Cukup Layak)';
    if (brightness > 60) return 'Coklat Kekuningan (Kurang Layak)';
    return 'Coklat Kotor (Tidak Layak)';
  }
}
