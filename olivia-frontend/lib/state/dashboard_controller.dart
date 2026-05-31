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
  var isConnected = false.obs;
  var connectionMessage = "Terhubung".obs;

  // --- UNIT 1: PROSES ARANG ---
  var suhuArang = 0.0.obs;
  var sparkSuhuArang = <double>[0.0].obs;
  var arangVol = 0.0.obs;

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
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;
  var warnaLabel = "Menunggu Analisa...".obs;

  // --- VARIABEL FUZZY LOGIC (BARU DITAMBAHKAN SESUAI ESP32) ---
  var kelayakan = 0.0.obs;
  var statusLayak = "Menunggu Analisa...".obs;

  StreamSubscription? _mqttSubscription;
  StreamSubscription? _connectionSubscription;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    _setupConnectionListener();
    fetchDashboardData();
    _initMqttListen();
    _startPollingFallback();
  }

  void _setupConnectionListener() {
    _connectionSubscription = _mqttService.isConnected.listen((isConnected) {
      this.isConnected.value = isConnected;
      connectionMessage.value = isConnected ? "Terhubung" : "Tidak Terhubung";
    });
  }

  /// 🔄 AUTO-POLLING FALLBACK: Ketika MQTT tidak terhubung, polling API setiap 2 detik
  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      if (!isConnected.value) {
        // Hanya polling jika MQTT tidak terhubung
        debugPrint('[POLLING] Fetching data from API...');
        fetchDashboardData();
      }
    });
  }

  @override
  void onClose() {
    _mqttSubscription?.cancel();
    _connectionSubscription?.cancel();
    _pollingTimer?.cancel();
    super.onClose();
  }

  // ===========================================================================
  // HTTP API FETCH (Sinkronisasi awal dari Laravel)
  // ===========================================================================
  Future<void> fetchDashboardData() async {
    try {
      // Only show loading on first load, not on polling
      final isFirstLoad = isLoading.value;
      if (isFirstLoad) isLoading.value = true;

      // 1. Ambil data dari endpoint /dashboard
      final response = await _api.get('/dashboard');

      // 2. Proses response yang bisa berbentuk Map atau Response object
      dynamic data;

      // Handle jika response adalah Map (dari ApiService)
      if (response is Map) {
        data = response;
      }
      // Handle jika response memiliki properti .data (Response object)
      else if (response != null && response.data != null) {
        data = response.data;
      }

      // 3. Cek struktur response: harus ada 'status' == 'success' dan 'data'
      if (data != null && data['status'] == 'success') {
        final telemetry = data['data'];

        if (telemetry != null) {
          // 4. Parse dan update UI dengan data dari API
          _parseAndUpdates(Map<String, dynamic>.from(telemetry));
          debugPrint('[API] Dashboard data fetched successfully');
        } else {
          debugPrint('[API] Warning: No telemetry data in response');
        }
      } else {
        debugPrint('[API] Response does not have success status');
      }
    } catch (e) {
      debugPrint("[API] Error fetching dashboard: $e");
      // Jangan throw error, tetap tampilkan data terakhir yang ada
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // TOGGLE ON/OFF UTAMA (Dikirim ke Laravel + MQTT sebagai backup)
  // ===========================================================================
  Future<void> toggleSystemStatus() async {
    try {
      bool targetStatus = !systemOn.value;

      // 1️⃣ PRIORITAS UTAMA: Publish ke MQTT jika tersedia (untuk response real-time)
      if (isConnected.value) {
        _mqttService.publish('olivia/control/request', {
          'command': 'system_toggle',
          'system_on': targetStatus,
          'timestamp': DateTime.now().toIso8601String(),
        });
        debugPrint('[TOGGLE] MQTT command sent');
      } else {
        debugPrint('[TOGGLE] MQTT not connected, using API fallback');
      }

      // 2️⃣ SELALU kirim ke API (baik MQTT connected atau tidak)
      final response = await _api.post('/control', {
        'system_on': targetStatus,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      // Deteksi kesuksesan post API
      bool isSuccess = false;
      if (response is Map && response['status'] == 'success') isSuccess = true;
      if (response != null &&
          response.data != null &&
          response.data['status'] == 'success') isSuccess = true;

      if (isSuccess) {
        systemOn.value = targetStatus;
        Get.snackbar(
          "Sukses",
          targetStatus
              ? "Sistem dihidupkan ${isConnected.value ? '' : '(via API)'}"
              : "Sistem dimatikan ${isConnected.value ? '' : '(via API)'}",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        if (!targetStatus) {
          _resetAllRealtimeMetrics();
        }
        // Refresh data dari server untuk sinkronisasi
        fetchDashboardData();
      } else {
        throw Exception('Server returned unsuccessful status');
      }
    } on TimeoutException {
      debugPrint("Error: API request timeout");
      Get.snackbar(
        "Request Timeout",
        "Perintah kontrol tidak merespons dalam waktu yang ditentukan.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("Error Toggle System Control: $e");
      Get.snackbar(
        "Koneksi Gagal",
        "Gagal mengirimkan perintah kontrol ke sistem.\nDetail: ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void toggleSystem(bool value) {
    toggleSystemStatus();
  }

  // ===========================================================================
  // MQTT REAL-TIME TELEMETRY RECEIVER
  // ===========================================================================
  void _initMqttListen() {
    _mqttSubscription = _mqttService.payloadStream.listen((payload) {
      if (payload.isNotEmpty) {
        _parseAndUpdates(payload);
      }
    });
  }

  // ===========================================================================
  // CORE PARSING LOGIC (SINKRONISASI DATABASE & PAYLOAD MQTT)
  // ===========================================================================
  void _parseAndUpdates(Map<String, dynamic> json) {
    // 1. Sinkronisasi Status Saklar Utama
    if (json.containsKey('system_on')) {
      systemOn.value = json['system_on'] == true || json['system_on'] == 1;
    }

    // 2. Parsing Struktur Data Sub-Object 'arang'
    if (json['arang'] != null) {
      var arang = json['arang'];
      suhuArang.value = _toDouble(arang['suhu_arang']);
      arangVol.value = _toDouble(arang['volume_arang']);
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

    // 4. Parsing Struktur Data Sub-Object 'validasi' (DENGAN FUZZY LOGIC)
    if (json['validasi'] != null) {
      var validasi = json['validasi'];
      validasiVol.value = _toDouble(validasi['volume_validasi']);
      ntu.value = _toDouble(validasi['turbidity']);
      viscosity.value = _toDouble(validasi['viscosity']);
      r.value = validasi['r'] ?? 0;
      g.value = validasi['g'] ?? 0;
      b.value = validasi['b'] ?? 0;

      // Ambil hasil Fuzzy Logic dari ESP32 Master
      if (validasi.containsKey('kelayakan')) {
        kelayakan.value = _toDouble(validasi['kelayakan']);
      }
      if (validasi.containsKey('status_layak')) {
        statusLayak.value = validasi['status_layak'].toString();
      } else {
        // Fallback jika belum ada data fuzzy
        statusLayak.value = getOilColorLabel(r.value, g.value, b.value);
      }
    }

    // 5. Jalankan Evaluasi State Machine untuk Indikator UI
    _updateProgressStep();
  }

  // ===========================================================================
  // AUTOMATIC PROGRESS LOGIC
  // ===========================================================================
  void _updateProgressStep() {
    if (!systemOn.value) {
      progressStep.value = 0;
    } else if (bleachP2.value ||
        validasiVol.value > 0 ||
        ntu.value > 0 ||
        kelayakan.value > 0) {
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
    if (value > 0 && value != -127.0) {
      list.add(value);
      if (list.length > 15) list.removeAt(0);
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
    kelayakan.value = 0.0;
    statusLayak.value = "Menunggu Analisa...";
    progressStep.value = 0;
  }

  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "Menunggu Analisa...";
    if (r > 200 && g > 180 && b < 130) return "Cerah (Sesuai Standar)";
    if (r > 150 && g > 100 && b < 50) return "Keruh (Butuh Purifikasi Ulang)";
    return "Minyak Sedang Diuji";
  }
}
