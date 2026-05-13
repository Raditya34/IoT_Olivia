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

  Future<void> fetchDashboardData() async {
    try {
      final response = await _api.get('/dashboard');

      if (response != null && response['success'] == true) {
        systemOn.value = response['system_status'] ?? false;

        var d1 = response['arang'];
        if (d1 != null) {
          arangTemp.value = double.tryParse(d1['suhu'].toString()) ?? 0.0;
          arangVol.value = double.tryParse(d1['volume'].toString()) ?? 0.0;
          _updateSparkline(sparkArangTemp, arangTemp.value);
          _updateSparkline(sparkArangVol, arangVol.value);
        }

        var d2 = response['bleaching'];
        if (d2 != null) {
          bleachTemp.value = double.tryParse(d2['suhu'].toString()) ?? 0.0;
          _updateSparkline(sparkBleachTemp, bleachTemp.value);
          bleachValve.value = (d2['valve'] == 1 || d2['valve'] == true);
          bleachP1.value = (d2['pompa_1'] == 1 || d2['pompa_1'] == true);
          bleachP2.value = (d2['pompa_2'] == 1 || d2['pompa_2'] == true);
          bleachP3.value = (d2['pompa_3'] == 1 || d2['pompa_3'] == true);
          bleachH1.value = (d2['heater_1'] == 1 || d2['heater_1'] == true);
          bleachH2.value = (d2['heater_2'] == 1 || d2['heater_2'] == true);
          bleachSpeed.value =
              int.tryParse(d2['motor_ac_speed'].toString()) ?? 0;
        }

        var d3 = response['validasi'];
        if (d3 != null) {
          validasiVol.value = double.tryParse(d3['volume'].toString()) ?? 0.0;
          turb.value = double.tryParse(d3['turbidity'].toString()) ?? 0.0;
          visc.value = double.tryParse(d3['viskositas'].toString()) ?? 0.0;
          warna.value = d3['warna']?.toString() ?? '-';
        }

        if (validasiVol.value > 0) {
          progressStep.value = 2;
        } else if (bleachTemp.value > 0 || bleachP1.value) {
          progressStep.value = 1;
        } else {
          progressStep.value = 0;
        }
      }
    } catch (e) {
      print("Dashboard Data Error: $e");
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
    final oldState = systemOn.value;
    systemOn.value = newState;

    try {
      // Endpoint sesuai api.php: /control
      // Body sesuai OliviaController: system_on (boolean)
      final response = await _api.post('/control', {'system_on': newState});

      if (response != null && response['success'] == true) {
        Get.snackbar(
            'Berhasil', 'Sistem ${newState ? 'Dinyalakan' : 'Dimatikan'}');
      } else {
        systemOn.value = oldState;
        Get.snackbar('Gagal', 'Gagal merubah status di server');
      }
    } catch (e) {
      systemOn.value = oldState;
      Get.snackbar('Error', 'Koneksi bermasalah');
    }
  }
}
