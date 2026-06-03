// lib/state/dashboard_controller.dart
import 'package:get/get.dart';
import 'dart:async';
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
  var progressStep =
      0.obs; // Diisi langsung secara riil dari hardware "process_step"
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

  // Fetch pertama saat aplikasi dibuka lewat Laravel API Restful
  Future<void> fetchInitialData() async {
    try {
      final res = await _api.get('/dashboard');
      if (res != null && res['status'] == 'success' && res['data'] != null) {
        _parseAndUpdates(res['data']);
      }
    } catch (e) {
      print('[Dashboard Error] Gagal fetch data API Laravel: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _setupMqttListener() {
    _mqttService.subscribe('olivia/telemetry');
    _mqttSub = _mqttService.payloadStream.listen((payload) {
      if (payload.containsKey('topic') &&
          payload['topic'] == 'olivia/telemetry') {
        final data = payload['data'];
        if (data != null) {
          _parseAndUpdates(data);
        }
      }
    });

    isConnected.bindStream(_mqttService.isConnected.stream);
    ever(isConnected, (bool connected) {
      connectionMessage.value =
          connected ? "Terhubung" : "Terputus, Menggunakan Polling...";
    });
  }

  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_mqttService.isConnected.value) {
        fetchInitialData();
      }
    });
  }

  // Membaca riil parameter `process_step` dari payload JSON hardware
  void _parseAndUpdates(Map<String, dynamic> json) {
    if (json.containsKey('system_on')) {
      systemOn.value = json['system_on'] is bool
          ? json['system_on']
          : (json['system_on'] == 1 || json['system_on'] == 'true');
    }

    if (json.containsKey('process_step')) {
      progressStep.value = json['process_step'] ?? 0;
    }

    // Parse Nested Data Unit 1 (Arang)
    final arang = json['arang'];
    if (arang != null) {
      suhuArang.value = (arang['suhu_arang'] ?? 0.0).toDouble();
      arangVol.value = (arang['volume_arang'] ?? 0.0).toDouble();
      _updateSparkline(sparkSuhuArang, suhuArang.value);
    }

    // Parse Nested Data Unit 2 (Bleaching)
    final bleach = json['bleaching'];
    if (bleach != null) {
      suhuBleaching.value = (bleach['suhu_bleaching'] ?? 0.0).toDouble();
      bleachValve.value = bleach['valve'] == true || bleach['valve'] == 1;
      bleachP1.value = bleach['p1'] == true || bleach['p1'] == 1;
      bleachP2.value = bleach['p2'] == true || bleach['p2'] == 1;
      bleachP3.value = bleach['p3'] == true || bleach['p3'] == 1;
      bleachH1.value = bleach['h1'] == true || bleach['h1'] == 1;
      bleachH2.value = bleach['h2'] == true || bleach['h2'] == 1;
      bleachH3.value = bleach['h3'] == true || bleach['h3'] == 1;
      bleachH4.value = bleach['h4'] == true || bleach['h4'] == 1;
      bleachSpeed.value = bleach['speed'] ?? 0;
      _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
    }

    // Parse Nested Data Unit 3 (Validasi & Fuzzy)
    final validasi = json['validasi'];
    if (validasi != null) {
      validasiVol.value = (validasi['volume_validasi'] ?? 0.0).toDouble();
      ntu.value = (validasi['turbidity'] ?? 0.0).toDouble();
      viscosity.value = (validasi['viscosity'] ?? 0.0).toDouble();
      r.value = validasi['r'] ?? 0;
      g.value = validasi['g'] ?? 0;
      b.value = validasi['b'] ?? 0;
      kelayakan.value = (validasi['kelayakan'] ?? 0.0).toDouble();

      statusLayak.value =
          _fallbackStatusLabel(validasi['status_layak'], kelayakan.value);
      warnaLabel.value = _fallbackColorLabel(r.value, g.value, b.value);
    }
  }

  void _updateSparkline(RxList<double> list, double value) {
    list.add(value);
    if (list.length > 20) {
      list.removeAt(0);
    }
  }

  // Fungsi Kirim Kontrol START/STOP dari Aplikasi Flutter via MQTT & API Laravel
  Future<void> toggleSystem() async {
    final nextState = !systemOn.value;

    if (nextState) {
      _resetAllForFreshStart();
    } else {
      _resetActuatorsOnly();
    }

    systemOn.value = nextState;

    final controlPayload = {"system_on": nextState};

    print("BUTTON DITEKAN");
    print("MQTT CONNECTED: ${_mqttService.isConnected.value}");

    // 1. Kirim via MQTT (Prioritas utama eksekusi instan)
    _mqttService.publish('olivia/control', controlPayload);

    // 2. Kirim via API Laravel Backend (Guna backup status persistent di table database)
    try {
      await _api.post('/control', controlPayload);
    } catch (e) {
      print('[Control Error] Gagal update master control Laravel API: $e');
    }
  }

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

  String _fallbackStatusLabel(dynamic serverLabel, double percent) {
    if (serverLabel != null && serverLabel.toString().isNotEmpty) {
      return serverLabel.toString();
    }
    if (percent == 0.0) return "Menunggu Analisa...";
    return percent >= 65.0 ? 'LAYAK (Sesuai Standar)' : 'TIDAK LAYAK';
  }

  String _fallbackColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return "Menunggu Analisa...";
    if (r > 200 && g > 180 && b < 130) return "Cerah (Sesuai Standar)";
    if (r > 150 && g > 100 && b < 50) return "Keruh (Butuh Purifikasi Ulang)";
    return "Minyak Sedang Diuji";
  }

  // Reset SEMUA data (dipanggil saat sistem di-ON ulang agar progress fresh)
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
    progressStep.value = 0; // Kembalikan ke posisi awal
  }

  @override
  void onClose() {
    _mqttSub?.cancel();
    _pollingTimer?.cancel();
    super.onClose();
  }
}
