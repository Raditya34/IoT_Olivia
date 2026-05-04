import 'package:get/get.dart';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import '../../services/mqtt_service.dart';

class DashboardController extends GetxController {
  var systemOn = false.obs;
  var progressStep = 0.obs;

  // Data Sensor
  var arangTemp = 0.0.obs;
  var arangVol = 0.0.obs;
  var bleachTemp = 0.0.obs;
  var turb = 0.0.obs;
  var visc = 0.0.obs;
  var warna = 'Jernih'.obs;

  // History untuk Sparkline (Maksimal 10 data terakhir)
  var sparkArangTemp = <double>[].obs;
  var sparkArangVol = <double>[].obs;
  var sparkBleachTemp = <double>[].obs;

  late MqttService _mqttService;

  @override
  void onInit() {
    super.onInit();
    _initMqtt();
  }

  void _initMqtt() async {
    _mqttService = MqttService();
    await _mqttService.connect();

    _mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String topic = c[0].topic;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      _parseData(topic, payload);
    });
  }

  void _parseData(String topic, String payload) {
    try {
      final data = jsonDecode(payload);
      if (topic == 'olivia/esp1') {
        arangTemp.value = (data['suhu'] ?? 0).toDouble();
        arangVol.value = (data['volume'] ?? 0).toDouble();
        _pushHistory(sparkArangTemp, arangTemp.value);
        _pushHistory(sparkArangVol, arangVol.value);
      } else if (topic == 'olivia/esp2') {
        bleachTemp.value = (data['suhu'] ?? 0).toDouble();
        _pushHistory(sparkBleachTemp, bleachTemp.value);
      } else if (topic == 'olivia/esp3') {
        turb.value = (data['turbidity'] ?? 0).toDouble();
        visc.value = (data['viscosity'] ?? 0).toDouble();
        warna.value = data['warna'] ?? 'Jernih';
      }
    } catch (e) {
      print("Error parse data: $e");
    }
  }

  void _pushHistory(RxList<double> list, double value) {
    list.add(value);
    if (list.length > 15) list.removeAt(0);
  }

  void toggleSystem() => systemOn.value = !systemOn.value;
}
