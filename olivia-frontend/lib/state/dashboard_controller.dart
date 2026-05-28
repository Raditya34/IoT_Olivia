// lib/state/dashboard_controller.dart
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();
  final MqttService _mqttService = Get.find<MqttService>();

  // ===========================================================================
  // STATE VARIABEL (REAKTIF GetX)
  // ===========================================================================
  var systemOn = false.obs;
  var isLoading = true.obs;
  var progressStep = 0.obs;

  // --- UNIT 1: PROSES ARANG ---
  var suhuArang = 0.0.obs;
  var sparkSuhuArang = <double>[0.0].obs;
  var arangVol = 0.0.obs; // Untuk volume_arang

  // --- UNIT 2: PROSES BLEACHING ---
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

  // --- UNIT 3: PROSES VALIDASI (AKHIR) ---
  var validasiVol = 0.0.obs; // Untuk volume_validasi agar tidak mismatch
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;
  var warnaLabel = "Menunggu Analisa...".obs;

  StreamSubscription? _mqttSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    _initMqttListen();
  }

  @override
  void onClose() {
    _mqttSubscription?.cancel();
    super.onClose();
  }

  // ===========================================================================
  // HTTP API FETCH (sinkronisasi awal / refresh manual dari Laravel)
  // ===========================================================================
  Future<void> fetchDashboardData() async {
    try {
      isLoading.value = true;
      final response = await _api.get('/dashboard');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final telemetry = response.data['data'];
        _parseAndUpdates(telemetry);
      }
    } catch (e) {
      debugPrint("Error HTTP Fetch Dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // TOGGLE ON/OFF UTAMA (Dikirim ke Laravel & Memicu Perubahan)
  // ===========================================================================
  Future<void> toggleSystemStatus() async {
    try {
      // Ambil kebalikan dari status saat ini
      bool targetStatus = !systemOn.value;

      // Kirim perintah POST ke backend Laravel
      final response = await _api.post('/control', {
        'system_on': targetStatus,
      });

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        // Update local state terlebih dahulu agar UI terasa responsif
        systemOn.value = targetStatus;
        if (!targetStatus) {
          _resetAllRealtimeMetrics();
        }
      }
    } catch (e) {
      debugPrint("Error Toggle System Control: $e");
      Get.snackbar(
        "Koneksi Gagal",
        "Gagal mengirimkan perintah kontrol ke sistem.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // ===========================================================================
  // MQTT REAL-TIME TELEMETRY RECEIVER
  // ===========================================================================
  void _initMqttListen() {
    _mqttSubscription = _mqttService.payloadStream.listen((payload) {
      _parseAndUpdates(payload);
    });
  }

  void toggleSystem(bool value) {
    toggleSystemStatus();
  }

  // ===========================================================================
  // CORE PARSING LOGIC (SINKRONISASI DATABASES & PAYLOAD MASTER)
  // ===========================================================================
  void _parseAndUpdates(Map<String, dynamic> json) {
    // 1. Sinkronisasi Status Saklar Utama
    systemOn.value = json['system_on'] ?? false;

    // 2. Parsing Struktur Data Sub-Object 'arang'
    if (json['arang'] != null) {
      var arang = json['arang'];
      suhuArang.value = _toDouble(arang['suhu_arang']);
      arangVol.value =
          _toDouble(arang['volume_arang']); // SINKRON: volume_arang
      _updateSparkline(sparkSuhuArang, suhuArang.value);
    }

    // 3. Parsing Struktur Data Sub-Object 'bleaching'
    if (json['bleaching'] != null) {
      var bleaching = json['bleaching'];
      suhuBleaching.value = _toDouble(bleaching['suhu_bleaching']);
      bleachValve.value = bleaching['valve'] ?? false;
      bleachP1.value = bleaching['p1'] ?? false;
      bleachP2.value = bleaching['p2'] ?? false;
      bleachP3.value = bleaching['p3'] ?? false;
      bleachH1.value = bleaching['h1'] ?? false;
      bleachH2.value = bleaching['h2'] ?? false;
      bleachH3.value = bleaching['h3'] ?? false;
      bleachH4.value = bleaching['h4'] ?? false;
      bleachSpeed.value = bleaching['speed'] ?? 0;
      _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
    }

    // 4. Parsing Struktur Data Sub-Object 'validasi'
    if (json['validasi'] != null) {
      var validasi = json['validasi'];
      validasiVol.value =
          _toDouble(validasi['volume_validasi']); // SINKRON: volume_validasi
      ntu.value = _toDouble(validasi['turbidity']);
      viscosity.value = _toDouble(validasi['viscosity']);
      r.value = validasi['r'] ?? 0;
      g.value = validasi['g'] ?? 0;
      b.value = validasi['b'] ?? 0;
      warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
    }

    // 5. Jalankan Evaluasi State Machine untuk Indikator Garis Waktu UI
    _updateProgressStep();
  }

  // ===========================================================================
  // AUTOMATIC PROGRESS LOGIC (State Machine Evaluator)
  // ===========================================================================
  void _updateProgressStep() {
    if (!systemOn.value) {
      progressStep.value = 0;
    } else if (bleachP2.value || validasiVol.value > 0 || ntu.value > 0) {
      progressStep.value = 3; // Tahap Validasi / Hasil Akhir
    } else if (bleachP1.value ||
        suhuBleaching.value > 30 ||
        bleachSpeed.value > 0) {
      progressStep.value = 2; // Sedang dalam tahapan pencampuran Bleaching
    } else if (suhuArang.value > 30 || arangVol.value > 0) {
      progressStep.value = 1; // Sedang dalam tahapan Pemanasan Arang
    } else {
      progressStep.value = 0; // Standby berjalan namun parameter belum naik
    }
  }

  // ===========================================================================
  // HELPER METODE & RESETTER
  // ===========================================================================
  void _updateSparkline(RxList<double> list, double value) {
    // Abaikan nilai error pembacaan sensor (-127 atau 0 saat mati) ke dalam chart grafik
    if (value > 0 && value != -127.0) {
      list.add(value);
      if (list.length > 15) list.removeAt(0); // Batasi titik chart max 15 data
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  void _resetAllRealtimeMetrics() {
    suhuArang.value = 0.0;
    arangVol.value = 0.0;
    suhuBleaching.value = 0.0;
    bleachValve.value = false;
    bleachP1.value = false;
    bleachP2.value = false;
    bleachP3.value = false;
    bleachH1.value = false;
    bleachH2.value = false;
    bleachH3.value = false;
    bleachH4.value = false;
    bleachSpeed.value = 0;
    validasiVol.value = 0.0;
    ntu.value = 0.0;
    viscosity.value = 0.0;
    r.value = 0;
    g.value = 0;
    b.value = 0;
    progressStep.value = 0;
  }

  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "Menunggu Analisa...";
    if (r > 200 && g > 180 && b < 130) return "Cerah (Sesuai Standar)";
    if (r > 150 && g > 100 && b < 50) return "Keruh (Butuh Purifikasi Ulang)";
    return "Minyak Sedang Diuji";
  }
}
