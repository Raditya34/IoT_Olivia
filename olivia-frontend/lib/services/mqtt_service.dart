// lib/services/mqtt_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService extends GetxService {
  final String _host = 'a24e7a00b6d943c2be69eafa2c60943f.s1.eu.hivemq.cloud';
  final int _port = 8883;
  final String _username = 'Olivia_IoT';
  final String _password = 'Olivia12345';
  late final String _clientId;

  late MqttServerClient _client;
  Function(String topic, Map<String, dynamic> data)? onMessageReceived;

  final StreamController<Map<String, dynamic>> _payloadController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get payloadStream => _payloadController.stream;

  final isConnected = false.obs;
  final reconnectAttempts = 0.obs;

  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _clientId = 'flutter_olivia_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_host, _clientId, _port);
    _setupClient();
    connect();
  }

  void _setupClient() {
    _client.logging(on: false);
    _client.keepAlivePeriod = 60;
    _client.secure = true;
    _client.securityContext = SecurityContext.defaultContext;
    _client.onBadCertificate = (dynamic cert) => true;
    _client.onDisconnected = _onDisconnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .startClean();
    _client.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      print('[MQTT] Connecting to HiveMQ Cloud...');
      await _client.connect();

      final connected =
          _client.connectionStatus!.state == MqttConnectionState.connected;

      if (connected) {
        isConnected.value = true;
        reconnectAttempts.value = 0;

        // Daftarkan listener SEKALI saja di sini
        _subscription = _client.updates!
            .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          for (final msg in messages) {
            final recMess = msg.payload as MqttPublishMessage;
            final pt =
                MqttPublishPayload.bytesToString(recMess.payload.message);
            try {
              final Map<String, dynamic> parsed = jsonDecode(pt);
              onMessageReceived?.call(msg.topic, parsed);
              _payloadController.add({
                'topic': msg.topic,
                'data': parsed,
              });
              print('[MQTT RX] Topic: ${msg.topic}');
            } catch (e) {
              print('[MQTT] Error parsing payload dari ${msg.topic}: $e');
            }
          }
        });

        // ✅ Subscribe ke topic yang dikirim oleh MqttSubscribe.php Laravel
        // Laravel re-publish ke 'olivia/telemetry' (format flat tanpa device code)
        subscribe('olivia/telemetry');

        // ✅ Subscribe ke response kontrol (acknowledgement dari Laravel setelah toggle)
        subscribe('olivia/control/response');

        // ✅ Subscribe ke topic Master langsung sebagai fallback
        // (jika Laravel MqttSubscribe tidak berjalan / down)
        subscribe('olivia/OLIVIA-MASTER/telemetry');

        print('[MQTT] Connected! Subscribed to all topics.');
      } else {
        throw Exception('Failed to establish MQTT connection');
      }
      return connected;
    } catch (e) {
      print('[MQTT] Connection Error: $e');
      isConnected.value = false;
      _client.disconnect();
      _attemptReconnect();
      return false;
    }
  }

  void _attemptReconnect() {
    if (reconnectAttempts.value < 5) {
      reconnectAttempts.value++;
      final delay = Duration(seconds: 5 * reconnectAttempts.value);
      print(
          '[MQTT] Reconnect dalam ${delay.inSeconds}s... (Attempt ${reconnectAttempts.value})');
      Future.delayed(delay, () {
        if (!isConnected.value) connect();
      });
    } else {
      print(
          '[MQTT] Max reconnect attempts reached. Falling back to HTTP polling.');
    }
  }

  void subscribe(String topic) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);
      print('[MQTT] Subscribed: $topic');
    } else {
      print('[MQTT] Cannot subscribe — not connected: $topic');
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    print("MQTT STATE = ${_client.connectionStatus?.state}");

    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      print("PUBLISH MQTT -> $topic");

      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));

      _client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );

      print('[MQTT TX] $topic');
    } else {
      print('[MQTT] Cannot publish — not connected');
    }
  }

  void _onDisconnected() {
    print('[MQTT] Disconnected from broker');
    isConnected.value = false;
    _attemptReconnect();
  }

  void disconnect() {
    _subscription?.cancel();
    _client.disconnect();
    print('[MQTT] Disconnected');
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _payloadController.close();
    disconnect();
    super.onClose();
  }
}
