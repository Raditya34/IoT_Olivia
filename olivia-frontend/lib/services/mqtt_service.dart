import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String _host = 'ff0669f1.ala.asia-southeast1.emqxsl.com';
  final int _port = 8883;
  final String _username = 'Olivia_1';
  final String _password = 'Olivia12345';
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
    _client.secure = true;

    // FIX: Sintaks terbaru untuk bypass sertifikat
    _client.onBadCertificate = (dynamic cert) => true;

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
      print('MQTT Connection Error: $e');
      _client.disconnect();
      return false;
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
    }
  }
}
