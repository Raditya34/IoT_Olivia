import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String _host = 'n68555e3.ala.asia-southeast1.emqxsl.com';
  final int _port = 1883;
  final String _username = 'admin';
  final String _password = '*difa020824';
  final String _clientId =
      'flutter_olivia_${DateTime.now().millisecondsSinceEpoch}';

  late MqttServerClient _client;
  Function(String topic, Map<String, dynamic> data)? onMessageReceived;

  MqttService() {
    _client = MqttServerClient.withPort(_host, _clientId, _port);
    _setupClient();
  }

  void _setupClient() {
    _client.logging(on: false);
    _client.keepAlivePeriod = 60;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .startClean();
    _client.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      await _client.connect();
      return _client.connectionStatus!.state == MqttConnectionState.connected;
    } catch (e) {
      _client.disconnect();
      return false;
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }
}
