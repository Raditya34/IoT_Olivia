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

  // --- FUZZY LOGIC (dari ESP32 Master) ---
  var kelayakan = 0.0.obs;
  var statusLayak = "Menunggu Analisa...".obs;

  // ✅ FIX: warnaLabel sekarang diturunkan dari statusLayak (bukan dihitung ulang di sini)
  // sehingga konsisten dengan hasil fuzzy logic dari ESP32 Master
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
      debugPrint('[MQTT] Connection status: $connected');
    });
  }

  /// 🔄 AUTO-POLLING FALLBACK: polling API tiap 3 detik jika MQTT tidak terhubung
  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      // ✅ Polling tetap berjalan untuk data sensor walaupun system off
      // (bukan hanya saat MQTT tidak terhubung)
      if (!isConnected.value) {
        debugPrint('[POLLING] MQTT offline → Fetching data from API...');
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
  // HTTP API FETCH (Sinkronisasi awal & fallback)
  // ===========================================================================
  Future<void> fetchDashboardData() async {
    try {
      final isFirstLoad = isLoading.value;
      if (isFirstLoad) isLoading.value = true;

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
          debugPrint('[API] Dashboard data fetched successfully');
        }
      } else {
        debugPrint('[API] Response tidak berisi status success');
      }
    } catch (e) {
      debugPrint("[API] Error fetching dashboard: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // ===========================================================================
  // TOGGLE ON/OFF SISTEM (dari Flutter → Laravel → MQTT → ESP32 via RS485)
  // ===========================================================================
  Future<void> toggleSystemStatus() async {
    try {
      bool targetStatus = !systemOn.value;

      // 1️⃣ Kirim via MQTT untuk response real-time (jika tersedia)
      if (isConnected.value) {
        _mqttService.publish('olivia/control/request', {
          'command': 'system_toggle',
          'system_on': targetStatus,
          'timestamp': DateTime.now().toIso8601String(),
        });
        debugPrint('[TOGGLE] MQTT command sent: system_on=$targetStatus');
      }

      // 2️⃣ Selalu kirim ke API Laravel (sebagai sumber kebenaran utama)
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

        Get.snackbar(
          "Sukses",
          targetStatus ? "Sistem dihidupkan" : "Sistem dimatikan",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // ✅ FIX: Saat sistem dimatikan, HANYA reset status aktuator
        // Data sensor (suhu, volume, ntu, dll) TIDAK direset
        // sehingga tetap tampil di UI
        if (!targetStatus) {
          _resetActuatorsOnly();
        }

        // Refresh data dari server
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
      if (payload.isNotEmpty) {
        _parseAndUpdates(payload);
      }
    });
  }

  // ===========================================================================
  // CORE PARSING LOGIC
  // ===========================================================================
  void _parseAndUpdates(Map<String, dynamic> json) {
    // 1. Status saklar utama
    if (json.containsKey('system_on')) {
      systemOn.value = json['system_on'] == true || json['system_on'] == 1;
    }

    // 2. Data Arang
    if (json['arang'] != null) {
      var arang = json['arang'];
      suhuArang.value = _toDouble(arang['suhu_arang']);
      arangVol.value = _toDouble(arang['volume_arang']);
      _updateSparkline(sparkSuhuArang, suhuArang.value);
    }

    // 3. Data Bleaching
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

    // 4. Data Validasi
    if (json['validasi'] != null) {
      var validasi = json['validasi'];

      // ✅ Data sensor selalu diupdate, tidak tergantung system_on
      validasiVol.value = _toDouble(validasi['volume_validasi']);
      ntu.value = _toDouble(validasi['turbidity']);
      viscosity.value = _toDouble(validasi['viscosity']);
      r.value = (validasi['r'] as num?)?.toInt() ?? 0;
      g.value = (validasi['g'] as num?)?.toInt() ?? 0;
      b.value = (validasi['b'] as num?)?.toInt() ?? 0;

      // ✅ FIX: Ambil hasil Fuzzy dari ESP32 Master
      if (validasi.containsKey('kelayakan')) {
        kelayakan.value = _toDouble(validasi['kelayakan']);
      }

      // ✅ FIX: statusLayak & warnaLabel diambil langsung dari server (bukan dihitung ulang)
      if (validasi.containsKey('status_layak') &&
          validasi['status_layak'] != null &&
          validasi['status_layak'].toString().isNotEmpty) {
        statusLayak.value = validasi['status_layak'].toString();
        // Terjemahkan status_layak ke label warna yang user-friendly
        warnaLabel.value = _translateStatusToWarnaLabel(statusLayak.value);
      } else {
        // Fallback: hitung dari nilai RGB jika server belum kirim status
        statusLayak.value = getOilColorLabel(r.value, g.value, b.value);
        warnaLabel.value = statusLayak.value;
      }
    }

    // 5. Update progress step berdasarkan state terkini
    _updateProgressStep();
  }

  // ===========================================================================
  // PROGRESS STEP LOGIC
  // ===========================================================================
  void _updateProgressStep() {
    // ✅ FIX: Progress step menggambarkan KONDISI PROSES, bukan hanya saat system_on
    // Sehingga walaupun sistem dimatikan, kalau ada data sensor, step bisa tetap tampil
    if (bleachP2.value ||
        validasiVol.value > 0 ||
        ntu.value > 0 ||
        kelayakan.value > 0) {
      progressStep.value = 3; // Tahap Validasi
    } else if (bleachP1.value ||
        suhuBleaching.value > 30 ||
        bleachSpeed.value > 0) {
      progressStep.value = 2; // Tahap Bleaching
    } else if (suhuArang.value > 30 || arangVol.value > 0) {
      progressStep.value = 1; // Tahap Arang
    } else {
      progressStep.value = 0; // Standby
    }
  }

  // ===========================================================================
  // HELPER METODE
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

  /// ✅ FIX: Terjemahkan status_layak dari ESP32 ke label UI yang ramah
  String _translateStatusToWarnaLabel(String status) {
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

  /// ✅ FIX: Hanya reset STATUS AKTUATOR saat sistem dimatikan
  /// Data sensor (suhu, volume, ntu, dll) TETAP ditampilkan
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
    // ⚠️ TIDAK mereset: suhuArang, arangVol, suhuBleaching,
    //    validasiVol, ntu, viscosity, r, g, b, kelayakan, statusLayak
  }

  /// Reset SEMUA data (dipanggil secara manual/eksplisit jika diperlukan)
  void resetAllData() {
    suhuArang.value = 0.0;
    arangVol.value = 0.0;
    suhuBleaching.value = 0.0;
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
    progressStep.value = 0;
  }

  /// Fallback warna label dari RGB (jika status_layak belum tersedia dari server)
  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "Menunggu Analisa...";
    if (r > 200 && g > 180 && b < 130) return "Cerah (Sesuai Standar)";
    if (r > 150 && g > 100 && b < 50) return "Keruh (Butuh Purifikasi Ulang)";
    return "Minyak Sedang Diuji";
  }
}
