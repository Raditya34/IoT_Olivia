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

  // --- UNIT 3: PROSES VALIDASI ---
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;

  // --- FUZZY LOGIC ---
  var kelayakan = 0.0.obs;
  var statusLayak = "Menunggu Analisa...".obs;
  var warnaLabel = "Menunggu Analisa...".obs;

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
    _connectionSubscription = _mqttService.isConnected.listen((connected) {
      isConnected.value = connected;
      connectionMessage.value = connected ? "Terhubung" : "Tidak Terhubung";
    });
  }

  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!isConnected.value) fetchDashboardData();
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
  // HTTP API FETCH
  // ===========================================================================
  Future<void> fetchDashboardData() async {
    try {
      if (isLoading.value) isLoading.value = true;
      final response = await _api.get('/dashboard');

      dynamic data;
      if (response is Map) {
        data = response;
      } else if (response?.data != null) {
        data = response.data;
      }

      if (data != null && data['status'] == 'success') {
        final telemetry = data['data'];
        if (telemetry != null) {
          _parseAndUpdates(Map<String, dynamic>.from(telemetry));
        }
      }
    } catch (e) {
      debugPrint("[API] Error: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // TOGGLE ON/OFF
  // ===========================================================================
  Future<void> toggleSystemStatus() async {
    try {
      bool targetStatus = !systemOn.value;

      if (isConnected.value) {
        _mqttService.publish('olivia/control/request', {
          'command': 'system_toggle',
          'system_on': targetStatus,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      final response = await _api.post('/control', {
        'system_on': targetStatus,
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('API request timeout'),
      );

      bool isSuccess = false;
      if (response is Map && response['status'] == 'success') isSuccess = true;
      if (response?.data?['status'] == 'success') isSuccess = true;

      if (isSuccess) {
        systemOn.value = targetStatus;

        if (targetStatus) {
          // ✅ FIX: Saat sistem di-ON, reset SEMUA data sensor & aktuator
          // agar progress dimulai dari awal (step 0), bukan melanjutkan data lama
          _resetAllForFreshStart();
          debugPrint('[TOGGLE] System ON → Reset semua data, mulai dari awal');
        } else {
          // Saat sistem di-OFF: reset hanya aktuator, sensor tetap tampil
          _resetActuatorsOnly();
          debugPrint('[TOGGLE] System OFF → Hanya aktuator direset');
        }

        Get.snackbar(
          "Sukses",
          targetStatus
              ? "Sistem dihidupkan — memulai dari awal"
              : "Sistem dimatikan",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        fetchDashboardData();
      } else {
        throw Exception('Server returned unsuccessful status');
      }
    } on TimeoutException {
      Get.snackbar(
        "Request Timeout",
        "Perintah tidak merespons. Coba lagi.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("Error Toggle: $e");
      Get.snackbar(
        "Koneksi Gagal",
        "Gagal mengirim perintah ke sistem.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void toggleSystem(bool value) => toggleSystemStatus();

  // ===========================================================================
  // MQTT REAL-TIME RECEIVER
  // ===========================================================================
  void _initMqttListen() {
    _mqttSubscription = _mqttService.payloadStream.listen((payload) {
      if (payload.isNotEmpty) _parseAndUpdates(payload);
    });
  }

  // ===========================================================================
  // CORE PARSING LOGIC
  // ===========================================================================
  void _parseAndUpdates(Map<String, dynamic> json) {
    if (json.containsKey('system_on')) {
      bool incomingState = json['system_on'] == true || json['system_on'] == 1;
      // Deteksi transisi OFF → ON dari hardware (misal tombol fisik ditekan)
      if (incomingState == true && systemOn.value == false) {
        // Hardware baru saja di-ON (misal via tombol fisik)
        // Reset progress agar dimulai dari awal
        _resetAllForFreshStart();
        debugPrint('[MQTT] Transisi OFF→ON dari hardware → Reset progress');
      }
      systemOn.value = incomingState;
    }

    if (json['arang'] != null) {
      var arang = json['arang'];
      suhuArang.value = _toDouble(arang['suhu_arang']);
      arangVol.value = _toDouble(arang['volume_arang']);
      _updateSparkline(sparkSuhuArang, suhuArang.value);
    }

    if (json['bleaching'] != null) {
      var bl = json['bleaching'];
      suhuBleaching.value = _toDouble(bl['suhu_bleaching']);
      bleachValve.value = bl['valve'] ?? false;
      bleachP1.value = bl['p1'] ?? false;
      bleachP2.value = bl['p2'] ?? false;
      bleachP3.value = bl['p3'] ?? false;
      bleachH1.value = bl['h1'] ?? false;
      bleachH2.value = bl['h2'] ?? false;
      bleachH3.value = bl['h3'] ?? false;
      bleachH4.value = bl['h4'] ?? false;
      bleachSpeed.value = bl['speed'] ?? 0;
      _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
    }

    if (json['validasi'] != null) {
      var v = json['validasi'];
      validasiVol.value = _toDouble(v['volume_validasi']);
      ntu.value = _toDouble(v['turbidity']);
      viscosity.value = _toDouble(v['viscosity']);
      r.value = (v['r'] as num?)?.toInt() ?? 0;
      g.value = (v['g'] as num?)?.toInt() ?? 0;
      b.value = (v['b'] as num?)?.toInt() ?? 0;

      if (v.containsKey('kelayakan')) {
        kelayakan.value = _toDouble(v['kelayakan']);
      }

      if (v.containsKey('status_layak') &&
          v['status_layak'] != null &&
          v['status_layak'].toString().isNotEmpty) {
        statusLayak.value = v['status_layak'].toString();
        warnaLabel.value = _translateStatusToLabel(statusLayak.value);
      } else {
        statusLayak.value = _fallbackColorLabel(r.value, g.value, b.value);
        warnaLabel.value = statusLayak.value;
      }
    }

    _updateProgressStep();
  }

  // ===========================================================================
  // PROGRESS STEP LOGIC
  // ===========================================================================
  void _updateProgressStep() {
    // ✅ FIX: Progress hanya naik ketika system_on = true
    // Ketika OFF, progress tetap di posisi terakhir (atau 0 jika baru reset)
    if (!systemOn.value) {
      // Tidak update progress saat OFF — biarkan di posisi terakhir
      // (kecuali jika sudah di-reset oleh _resetAllForFreshStart)
      return;
    }

    if (bleachP2.value ||
        validasiVol.value > 0 ||
        ntu.value > 0 ||
        kelayakan.value > 0) {
      progressStep.value = 3; // Validasi
    } else if (bleachP1.value ||
        suhuBleaching.value > 30 ||
        bleachSpeed.value > 0) {
      progressStep.value = 2; // Bleaching
    } else if (suhuArang.value > 30 || arangVol.value > 0) {
      progressStep.value = 1; // Arang
    } else {
      progressStep.value = 0; // Standby / baru mulai
    }
  }

  // ===========================================================================
  // HELPERS
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

  String _translateStatusToLabel(String status) {
    switch (status.toUpperCase().trim()) {
      case 'SANGAT LAYAK':
        return 'Sangat Baik (Cerah & Jernih)';
      case 'LAYAK':
        return 'Baik (Memenuhi Standar)';
      case 'KURANG LAYAK':
        return 'Perlu Purifikasi Ulang';
      case 'TIDAK LAYAK':
        return 'Tidak Memenuhi Standar';
      default:
        return 'Menunggu Analisa...';
    }
  }

  String _fallbackColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "Menunggu Analisa...";
    if (r > 200 && g > 180 && b < 130) return "Cerah (Sesuai Standar)";
    if (r > 150 && g > 100 && b < 50) return "Keruh (Butuh Purifikasi Ulang)";
    return "Minyak Sedang Diuji";
  }

  // ✅ Reset SEMUA data (dipanggil saat sistem di-ON ulang agar progress fresh)
  void _resetAllForFreshStart() {
    suhuArang.value = 0.0;
    arangVol.value = 0.0;
    sparkSuhuArang.value = [0.0];
    suhuBleaching.value = 0.0;
    sparkSuhuBleaching.value = [0.0];
    _resetActuatorsOnly();
    validasiVol.value = 0.0;
    ntu.value = 0.0;
    viscosity.value = 0.0;
    r.value = 0;
    g.value = 0;
    b.value = 0;
    kelayakan.value = 0.0;
    statusLayak.value = "Menunggu Analisa...";
    warnaLabel.value = "Menunggu Analisa...";
    progressStep.value = 0; // ✅ Progress kembali ke step 0 "Minyak"
  }

  // Reset hanya aktuator (dipanggil saat sistem di-OFF)
  void _resetActuatorsOnly() {
    bleachValve.value = false;
    bleachP1.value = false;
    bleachP2.value = false;
    bleachP3.value = false;
    bleachH1.value = false;
    bleachH2.value = false;
    bleachH3.value = false;
    bleachH4.value = false;
    bleachSpeed.value = 0;
  }

  // Manual reset (bisa dipanggil dari UI jika diperlukan)
  void resetAll() => _resetAllForFreshStart();
}
