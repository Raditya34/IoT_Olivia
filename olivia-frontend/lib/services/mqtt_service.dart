import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../config/constants.dart';

class MqttService {
  late MqttServerClient client;

  Future<void> connect() async {
    client = MqttServerClient(AppConfig.mqttHost,
        'flutter_client_${DateTime.now().millisecondsSinceEpoch}');
    client.port = AppConfig.mqttPort;
    client.logging(on: false);
    client.keepAlivePeriod = 20;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(
            'flutter_client_${DateTime.now().millisecondsSinceEpoch}')
        .authenticateAs(AppConfig.mqttUser, AppConfig.mqttPass)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);
    client.connectionMessage = connMess;

    try {
      await client.connect();
      print('MQTT Berhasil Terhubung!');

      // Subscribe ke semua topik olivia
      client.subscribe('olivia/+', MqttQos.atMostOnce);
    } catch (e) {
      print('MQTT Gagal: $e');
      client.disconnect();
    }
  }
}
