import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

class MqttService {
  late MqttBrowserClient client;

  Function(String topic, String message)? onMessage;

  Future<void> connect() async {
    client = MqttBrowserClient(
      'wss://test.mosquitto.org:8081/mqtt',
      'flutter_olivia_${DateTime.now().millisecondsSinceEpoch}',
    );

    client.keepAlivePeriod = 30;
    client.logging(on: true);

    client.onConnected = () => print('MQTT Connected');
    client.onDisconnected = () => print('MQTT Disconnected');

    final connMessage =
        MqttConnectMessage().startClean().withWillQos(MqttQos.atLeastOnce);

    client.connectionMessage = connMessage;

    await client.connect();

    client.updates!.listen((events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      onMessage?.call(events[0].topic, payload);
    });
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(
      topic,
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    client.disconnect();
  }
}
