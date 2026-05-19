// lib/state/dashboard_controller.dart
import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/mqtt_service.dart';

class DashboardController extends GetxController {
  final ApiService _api = ApiService();

  // Menggunakan instance singleton yang telah didaftarkan ke GetX
  final MqttService _mqttService = Get.find<MqttService>();

  var systemOn = false.obs;
  var progressStep = 0.obs;
  var isLoading = true.obs;

  // --- Proses 1 (Arang) ---
  var suhuArang = 0.0.obs;
  var sparkSuhuArang = <double>[0.0].obs;
  var arangVol = 0.0.obs;

  // --- Proses 2 (Bleaching) ---
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
    _initDashboardAndMqtt(); // Ambil data awal lewat API lalu nyalakan MQTT
  }

  @override
  void onClose() {
    // Memutus koneksi jika halaman/controller dihancurkan
    _mqttService.disconnect();
    super.onClose();
  }

  Future<void> _initDashboardAndMqtt() async {
    // 1. Ambil snapshot data terbaru dari database backend (HTTP)
    await fetchDashboardData();

    // 2. Setup callback penangkap data MQTT dari HiveMQ Cloud
    _mqttService.onMessageReceived = (topic, data) {
      _handleIncomingMqttData(topic, data);
    };

    // 3. Hubungkan ke HiveMQ Broker
    bool isConnected = await _mqttService.connect();
    if (isConnected) {
      print('MQTT Connected Successfully to HiveMQ Cloud!');
      // Subscribe ke topik monitoring data alat IoT Anda
      _mqttService.subscribe('olivia/purifikasi/telemetry');
    } else {
      print('MQTT Connection Failed!');
    }
  }

  // Fungsi untuk memproses data real-time dari HiveMQ
  void _handleIncomingMqttData(String topic, Map<String, dynamic> data) {
    if (topic == 'olivia/purifikasi/telemetry') {
      // Pastikan status sistem aktif mengikuti data terbaru dari IoT
      if (data.containsKey('system_on')) {
        systemOn.value = data['system_on'] ?? false;
      }

      // --- Parsing Proses 1: Arang ---
      if (data['arang'] != null) {
        var d1 = data['arang'];
        if (d1.containsKey('suhu_arang')) {
          suhuArang.value = _toDouble(d1['suhu_arang']);
          _updateSparkline(sparkSuhuArang, suhuArang.value);
        }
        if (d1.containsKey('volume_arang')) {
          arangVol.value = _toDouble(d1['volume_arang']);
        }
      }

      // --- Parsing Proses 2: Bleaching ---
      if (data['bleaching'] != null) {
        var d2 = data['bleaching'];
        if (d2.containsKey('suhu_bleaching')) {
          suhuBleaching.value = _toDouble(d2['suhu_bleaching']);
          _updateSparkline(sparkSuhuBleaching, suhuBleaching.value);
        }
        if (d2.containsKey('valve')) bleachValve.value = d2['valve'] ?? false;
        if (d2.containsKey('p1')) bleachP1.value = d2['p1'] ?? false;
        if (d2.containsKey('p2')) bleachP2.value = d2['p2'] ?? false;
        if (d2.containsKey('p3')) bleachP3.value = d2['p3'] ?? false;
        if (d2.containsKey('h1')) bleachH1.value = d2['h1'] ?? false;
        if (d2.containsKey('h2')) bleachH2.value = d2['h2'] ?? false;
        if (d2.containsKey('h3')) bleachH3.value = d2['h3'] ?? false;
        if (d2.containsKey('h4')) bleachH4.value = d2['h4'] ?? false;
        if (d2.containsKey('speed')) bleachSpeed.value = _toInt(d2['speed']);
      }

      // --- Parsing Proses 3: Validasi ---
      if (data['validasi'] != null) {
        var d3 = data['validasi'];
        if (d3.containsKey('volume_validasi')) {
          validasiVol.value = _toDouble(d3['volume_validasi']);
        }
        if (d3.containsKey('turbidity')) ntu.value = _toDouble(d3['turbidity']);
        if (d3.containsKey('viscosity')) {
          viscosity.value = _toDouble(d3['viscosity']);
        }

        // Parsing RGB untuk update label warna secara langsung
        bool colorChanged = false;
        if (d3.containsKey('r')) {
          r.value = _toInt(d3['r']);
          colorChanged = true;
        }
        if (d3.containsKey('g')) {
          g.value = _toInt(d3['g']);
          colorChanged = true;
        }
        if (d3.containsKey('b')) {
          b.value = _toInt(d3['b']);
          colorChanged = true;
        }

        if (colorChanged) {
          warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
        }
      }

      // --- Hitung Ulang Progress Step ---
      _calculateProgressStep();
    }
  }

  // Helper eksternal untuk menghitung kemajuan alur proses kerja
  void _calculateProgressStep() {
    if (validasiVol.value > 0 || ntu.value > 0) {
      progressStep.value = 2;
    } else if (suhuBleaching.value > 0 || bleachP1.value) {
      progressStep.value = 1;
    } else {
      progressStep.value = 0;
    }
  }

  // Mengambil snapshot dari database via API HTTP (Bagus untuk pull-to-refresh)
  Future<void> fetchDashboardData() async {
    try {
      if (isLoading.value && sparkSuhuArang.length <= 1) {
        isLoading.value = true;
      }

      final response = await _api.get('/dashboard');

      if (response != null && response['status'] == 'success') {
        final data = response['data'];
        systemOn.value = data['system_on'] ?? false;

        // --- Parsing Proses 1: Arang ---
        if (data['arang'] != null) {
          var d1 = data['arang'];
          suhuArang.value = _toDouble(d1['suhu_arang']);
          _updateSparkline(sparkSuhuArang, suhuArang.value);
          arangVol.value = _toDouble(d1['volume_arang']);
        }

        // --- Parsing Proses 2: Bleaching ---
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

        // --- Parsing Proses 3: Validasi ---
        if (data['validasi'] != null) {
          var d3 = data['validasi'];
          validasiVol.value = _toDouble(d3['volume_validasi']);
          ntu.value = _toDouble(d3['turbidity']);
          viscosity.value = _toDouble(d3['viscosity']);
          r.value = _toInt(d3['r']);
          g.value = _toInt(d3['g']);
          b.value = _toInt(d3['b']);
          warnaLabel.value = getOilColorLabel(r.value, g.value, b.value);
        }

        _calculateProgressStep();
      }
    } catch (e) {
      print("Dashboard fetch error: $e");
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

        // JALUR GANDA: Publikasikan juga perintah kontrol ke MQTT untuk respon cepat alat IoT
        _mqttService.publish('olivia/control', {
          'system_on': newState,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });

        fetchDashboardData();
      } else {
        systemOn.value = !newState;
        Get.snackbar('Gagal', 'Gagal mengubah status kontrol sistem');
      }
    } catch (e) {
      systemOn.value = !newState;
      Get.snackbar('Error', 'Terjadi kesalahan jaringan: $e');
    }
  }

  String getOilColorLabel(int r, int g, int b) {
    if (r == 0 && g == 0 && b == 0) return 'Menunggu Data...';
    int brightness = (r + g + b) ~/ 3;
    if (brightness > 180 && b > 100) return 'Jernih (Sangat Layak)';
    if (brightness > 120) return 'Agak Jernih (Cukup Layak)';
    if (brightness > 60) return 'Coklat Kekuningan (Kurang Layak)';
    return 'Coklat Kotor (Tidak Layak)';
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
