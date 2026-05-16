import 'package:get/get.dart';
import 'dart:async';
import '../../services/api_service.dart';

class DashboardController extends GetxController {
  var systemOn = false.obs;
  var progressStep = 0.obs;
  var isLoading = true.obs;

  var arangTemp = 0.0.obs;
  var arangVol = 0.0.obs;
  var sparkArangTemp = <double>[0.0].obs;
  var sparkArangVol = <double>[0.0].obs;

  var bleachTemp = 0.0.obs;
  var sparkBleachTemp = <double>[0.0].obs;
  var bleachValve = false.obs;
  var bleachP1 = false.obs;
  var bleachP2 = false.obs;
  var bleachP3 = false.obs;
  var bleachH1 = false.obs;
  var bleachH2 = false.obs;
  var bleachH3 = false.obs; // Tambahan Heater 3
  var bleachH4 = false.obs; // Tambahan Heater 4
  var bleachSpeed = 0.obs;

  var validasiVol = 0.0.obs;
  var turb = 0.0.obs;
  var visc = 0.0.obs;
  var warna = '-'.obs;

  final ApiService _api = ApiService();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
    _timer =
        Timer.periodic(const Duration(seconds: 3), (_) => fetchDashboardData());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // Helper fungsi konversi data yang tangguh
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  bool _toBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val == 1;
    return val.toString().toLowerCase() == 'true' || val.toString() == '1';
  }

  Future<void> fetchDashboardData() async {
    try {
      final data = await _api.get('/dashboard');

      if (data != null && data['success'] == true) {
        systemOn.value = _toBool(data['system_status']);

        // --- MAPPING DATA UNIT 1 (ARANG) ---
        if (data['arang'] != null) {
          var d1 = data['arang'];
          arangTemp.value = _toDouble(d1['suhu']);
          arangVol.value = _toDouble(d1['volume']);
          _updateSparkline(sparkArangTemp, arangTemp.value);
          _updateSparkline(sparkArangVol, arangVol.value);
        }

        // --- MAPPING DATA UNIT 2 (BLEACHING) ---
        if (data['bleaching'] != null) {
          var d2 = data['bleaching'];
          bleachTemp.value = _toDouble(d2['suhu']);

          bleachValve.value = _toBool(d2['valve']);
          bleachP1.value = _toBool(d2['pompa_1']);
          bleachP2.value = _toBool(d2['pompa_2']);
          bleachP3.value = _toBool(d2['pompa_3']);

          bleachH1.value = _toBool(d2['heater_1']);
          bleachH2.value = _toBool(d2['heater_2']);
          bleachH3.value = _toBool(d2['heater_3']); // Parse Heater 3
          bleachH4.value = _toBool(d2['heater_4']); // Parse Heater 4

          bleachSpeed.value =
              int.tryParse(d2['motor_ac_speed'].toString()) ?? 0;
          _updateSparkline(sparkBleachTemp, bleachTemp.value);
        }

        // --- MAPPING DATA UNIT 3 (VALIDASI) ---
        if (data['validasi'] != null) {
          var d3 = data['validasi'];
          validasiVol.value = _toDouble(d3['volume']);
          turb.value = _toDouble(d3['turbidity']);
          visc.value = _toDouble(d3['viskositas']);
          warna.value = d3['warna']?.toString() ?? '-';
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
            'Sistem berhasil di${newState ? 'aktifkan' : 'matikan'}',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        systemOn.value = !newState;
      }
    } catch (e) {
      systemOn.value = !newState;
      print("Toggle System Error: $e");
    }
  }
}
