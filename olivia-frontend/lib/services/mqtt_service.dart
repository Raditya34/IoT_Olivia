import 'dart:convert';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String _host = 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _username = 'Olivia_IoT';
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
    _client.securityContext = SecurityContext.defaultContext;
    _client.onBadCertificate = (dynamic cert) => true;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .startClean();
    _client.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      print('Connecting to HiveMQ Cloud..');
      await _client.connect();
      return _client.connectionStatus!.state == MqttConnectionState.connected;
    } catch (e) {
      print('MQTT Connection Error: $e');
      _client.disconnect();
      return false;
    }
  }

  void subscribe(String topic) {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);
      _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String pt =
            MqttPublishPayload.bytesToString(recMess.payload.message);

        try {
          final Map<String, dynamic> parsedData = jsonDecode(pt);
          if (onMessageReceived != null) {
            onMessageReceived?.call(c[0].topic, parsedData);
          }
        } catch (e) {
          print('Error parsing MQTT payload: $e');
        }
      });
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
