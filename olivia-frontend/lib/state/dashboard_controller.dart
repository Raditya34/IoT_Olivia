// lib/state/dashboard_controller.dart
import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();
  final MqttService _mqttService = Get.find<MqttService>();

  // ===========================================================================
  // ✅ SAFE PARSING UTILITIES (NEW)
  // ===========================================================================

  /// Safely convert any type to double
  static double _safeDouble(dynamic value, [double defaultValue = 0.0]) {
    try {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      print('[Parse Error] Failed to parse $value as double: $e');
      return defaultValue;
    }
  }

  /// Safely convert any type to int
  static int _safeInt(dynamic value, [int defaultValue = 0]) {
    try {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      print('[Parse Error] Failed to parse $value as int: $e');
      return defaultValue;
    }
  }

  /// Safely convert any type to bool
  static bool _safeBool(dynamic value, [bool defaultValue = false]) {
    try {
      if (value == null) return defaultValue;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        return lower == 'true' || lower == '1' || lower == 'on';
      }
      return defaultValue;
    } catch (e) {
      print('[Parse Error] Failed to parse $value as bool: $e');
      return defaultValue;
    }
  }

  // ===========================================================================
  // STATE VARIABEL (REAKTIF GetX)
  // ===========================================================================
  var systemOn = false.obs;
  var isLoading = true.obs;
  var progressStep = 0.obs;
  var isConnected = false.obs;
  var connectionMessage = "Terhubung".obs;

  // ✅ NEW: Error tracking
  var lastError = "".obs;
  var hasError = false.obs;

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

  // --- UNIT 3: VALIDASI ---
  var validasiVol = 0.0.obs;
  var ntu = 0.0.obs;
  var viscosity = 0.0.obs;
  var r = 0.obs;
  var g = 0.obs;
  var b = 0.obs;
  var kelayakan = 0.0.obs;
  var statusLayak = "Menunggu Analisa...".obs;
  var warnaLabel = "Menunggu Analisa...".obs;

  StreamSubscription? _mqttSub;
  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    _initSystem();
  }

  Future<void> _initSystem() async {
    await fetchInitialData();
    _setupMqttListener();
    _startPollingFallback();
  }

  /// Fetch data dari Laravel API saat aplikasi dibuka
  Future<void> fetchInitialData() async {
    try {
      final res = await _api.get('/dashboard');
      if (res != null && res['status'] == 'success' && res['data'] != null) {
        _parseAndUpdates(res['data']);
        _clearError();
      } else {
        _setError('API returned invalid response structure');
      }
    } catch (e) {
      _setError('Failed to fetch initial data: $e');
      print('[Dashboard Error] Gagal fetch data API Laravel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Setup listener untuk data MQTT real-time
  void _setupMqttListener() {
    _mqttService.subscribe('olivia/OLIVIA-MASTER/telemetry'); // ✅ Fixed topic
    _mqttSub = _mqttService.payloadStream.listen(
      (payload) {
        try {
          if (payload.containsKey('topic') &&
              payload['topic'] == 'olivia/OLIVIA-MASTER/telemetry') {
            final data = payload['data'];
            if (data != null) {
              _parseAndUpdates(data);
              _clearError();
            }
          }
        } catch (e) {
          _setError('Error processing MQTT data: $e');
          print('[MQTT Error] $e');
        }
      },
      onError: (error) {
        _setError('MQTT stream error: $error');
        print('[MQTT Stream Error] $error');
      },
    );

    isConnected.bindStream(_mqttService.isConnected.stream);
    ever(isConnected, (bool connected) {
      connectionMessage.value =
          connected ? "Terhubung" : "Terputus, Menggunakan Polling...";
    });
  }

  /// Fallback polling ketika MQTT tidak tersedia
  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_mqttService.isConnected.value) {
        fetchInitialData();
      }
    });
  }

  /// ✅ FIXED: Safe JSON parsing dengan error handling
  void _parseAndUpdates(Map<String, dynamic> json) {
    try {
      // Parse system level
      if (json.containsKey('system_on')) {
        systemOn.value = _safeBool(json['system_on']);
      }

      if (json.containsKey('process_step')) {
        progressStep.value = _safeInt(json['process_step']);
      }

      // Parse Nested Data Unit 1 (Arang)
      final arang = json['arang'];
      if (arang != null && arang is Map<String, dynamic>) {
        suhuArang.value = _safeDouble(arang['suhu_arang']);
        arangVol.value = _safeDouble(arang['volume_arang']);
        _updateSparkline(sparkSuhuArang, suhuArang.value);
      }

      // Parse Nested Data Unit 2 (Bleaching)
      final bleach = json['bleaching'];
      if (bleach != null && bleach is Map<String, dynamic>) {
        suhuBleaching.value = _safeDouble(bleach['suhu_bleaching']);
        bleachValve.value = _safeBool(bleach['valve']);
        bleachP1.value = _safeBool(bleach['p1']);
        bleachP2.value = _safeBool(bleach['p2']);
        bleachP3.value = _safeBool(bleach['p3']);
        bleachH1.value = _safeBool(bleach['h1']);
        bleachH2.value = _safeBool(bleach['h2']);
        bleachH3.value = _safeBool(bleach['h3']);
        bleachH4.value = _safeBool(bleach['h4']);
        bleachSpeed.value = _safeInt(bleach['speed']);
        _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
      }

      // Parse Nested Data Unit 3 (Validasi & Fuzzy)
      final validasi = json['validasi'];
      if (validasi != null && validasi is Map<String, dynamic>) {
        validasiVol.value = _safeDouble(validasi['volume_validasi']);
        ntu.value = _safeDouble(validasi['turbidity']);
        viscosity.value = _safeDouble(validasi['viscosity']);
        r.value = _safeInt(validasi['r']);
        g.value = _safeInt(validasi['g']);
        b.value = _safeInt(validasi['b']);
        kelayakan.value = _safeDouble(validasi['kelayakan']);

        statusLayak.value = _fallbackStatusLabel(
          validasi['status_layak'],
          kelayakan.value,
        );
        warnaLabel.value = _fallbackColorLabel(r.value, g.value, b.value);
      }
    } catch (e) {
      _setError('Error parsing data: $e');
      print('[Parse Error] Detailed error: $e');
    }
  }

  /// Update sparkline dengan batasan ukuran
  void _updateSparkline(RxList<double> list, double value) {
    try {
      // Validasi input
      if (value.isNaN || value.isInfinite) {
        value = 0.0;
      }

      list.add(value);
      if (list.length > 20) {
        list.removeAt(0);
      }
    } catch (e) {
      print('[Sparkline Error] $e');
    }
  }

  /// Toggle system ON/OFF dengan kontrol ke Master via MQTT & API
  Future<void> toggleSystem() async {
    final nextState = !systemOn.value;

    if (nextState) {
      _resetAllForFreshStart();
    } else {
      _resetActuatorsOnly();
    }

    systemOn.value = nextState;
    final controlPayload = {"system_on": nextState};

    print("[TOGGLE] New state: $nextState");
    print("[TOGGLE] MQTT Connected: ${_mqttService.isConnected.value}");

    // 1. Kirim via MQTT (Prioritas utama)
    try {
      _mqttService.publish('olivia/control', controlPayload);
    } catch (e) {
      _setError('Failed to publish MQTT: $e');
      print('[MQTT Publish Error] $e');
    }

    // 2. Kirim via API Laravel (Backup persistent)
    try {
      await _api.post('/control', controlPayload);
      _clearError();
    } catch (e) {
      _setError('Failed to update control via API: $e');
      print('[Control Error] $e');
    }
  }

  /// Reset hanya aktuator ketika sistem OFF
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

  /// ✅ FIXED: Better fallback status label
  String _fallbackStatusLabel(dynamic serverLabel, double percent) {
    try {
      if (serverLabel != null && serverLabel.toString().trim().isNotEmpty) {
        return serverLabel.toString();
      }
    } catch (e) {
      print('[Status Label Error] $e');
    }

    if (percent <= 0.0) return "Menunggu Analisa...";
    if (percent >= 80.0) return "SANGAT LAYAK (Premium)";
    if (percent >= 65.0) return "LAYAK (Sesuai Standar)";
    if (percent >= 40.0) return "KURANG LAYAK";
    return "TIDAK LAYAK";
  }

  /// ✅ FIXED: Better color label prediction from RGB
  String _fallbackColorLabel(int r, int g, int b) {
    try {
      // Semua 0 = belum ada data
      if (r == 0 && g == 0 && b == 0) {
        return "Menunggu Analisa...";
      }

      // Kuning Cerah (high R, high G, low B)
      if (r > 200 && g > 180 && b < 130) {
        return "Kuning Cerah (Excellent)";
      }

      // Kuning Kecoklatan (medium R, medium G, low B)
      if (r > 150 && r < 210 && g > 120 && g < 180 && b < 80) {
        return "Kuning Kecoklatan (Good)";
      }

      // Coklat (medium-low values)
      if (r > 100 && r < 160 && g > 60 && g < 140 && b > 20 && b < 100) {
        return "Coklat (Fair)";
      }

      // Coklat Pekat (all low, R > others)
      if (r > g && r > b && r < 100) {
        return "Coklat Pekat (Poor)";
      }

      return "Minyak Sedang Diuji";
    } catch (e) {
      print('[Color Label Error] $e');
      return "Minyak Sedang Diuji";
    }
  }

  /// Reset SEMUA data untuk fresh start
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
    progressStep.value = 0;
  }

  /// ✅ NEW: Error tracking methods
  void _setError(String message) {
    lastError.value = message;
    hasError.value = true;
    print('[Controller Error] $message');
  }

  void _clearError() {
    lastError.value = "";
    hasError.value = false;
  }

  @override
  void onClose() {
    _mqttSub?.cancel();
    _pollingTimer?.cancel();
    super.onClose();
  }
}
