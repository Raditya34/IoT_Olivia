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

  // Observable untuk tracking status koneksi
  final isConnected = false.obs;
  final reconnectAttempts = 0.obs;

  // Listener didaftapkan SEKALI saja saat connect, bukan saat subscribe
  StreamSubscription? _subscription;

  @override
  void onInit() {
    super.onInit();
    _clientId = 'flutter_olivia_${DateTime.now().millisecondsSinceEpoch}';
    _client = MqttServerClient.withPort(_host, _clientId, _port);
    _setupClient();
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

        // Daftarkan listener SEKALI di sini, bukan di dalam subscribe()
        _subscription = _client.updates!
            .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
          for (final msg in messages) {
            final recMess = msg.payload as MqttPublishMessage;
            final pt =
                MqttPublishPayload.bytesToString(recMess.payload.message);
            try {
              final Map<String, dynamic> parsed = jsonDecode(pt);
              onMessageReceived?.call(msg.topic, parsed);
              _payloadController.add(parsed);
            } catch (e) {
              print('[MQTT] Error parsing payload: $e');
            }
          }
        });

        // AUTO-SUBSCRIBE ke topic utama setelah connect berhasil
        subscribe('olivia/telemetry');
        subscribe('olivia/system');
        subscribe('olivia/control/response');

        print('[MQTT] Connected and subscribed to topics!');
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

  /// Auto-reconnect dengan exponential backoff
  void _attemptReconnect() {
    if (reconnectAttempts.value < 5) {
      reconnectAttempts.value++;
      final delay = Duration(seconds: 5 * reconnectAttempts.value);
      print(
          '[MQTT] Attempting reconnect in ${delay.inSeconds}s... (Attempt ${reconnectAttempts.value})');

      Future.delayed(delay, () {
        if (!isConnected.value) {
          connect();
        }
      });
    } else {
      print('[MQTT] Max reconnection attempts reached');
    }
  }

  // subscribe() hanya mendaftarkan topik, tidak mendaftarkan listener lagi
  void subscribe(String topic) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);
      print('[MQTT] Subscribed to: $topic');
    } else {
      print('[MQTT] Cannot subscribe — not connected');
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    if (_client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(jsonEncode(payload));
      _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
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
