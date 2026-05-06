import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  // DATA DARI GAMBAR EMQX CLOUD KAMU
  final String _host = 'n68555e3.ala.asia-southeast1.emqxsl.com';
  final int _port = 1883;

  // Ambil dari menu "Authentication" di Dashboard EMQX
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
    _client.onDisconnected = _onDisconnected;
    _client.onConnected = _onConnected;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(_clientId)
        .authenticateAs(_username, _password)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    _client.connectionMessage = connMess;
  }

  Future<bool> connect() async {
    try {
      await _client.connect();
      if (_client.connectionStatus!.state == MqttConnectionState.connected) {
        print('MQTT: Terhubung ke EMQX Cloud!');
        _listenToMessages();
        // Langsung subscribe ke topik utama
        subscribe('olivia/OLIVIA-01/telemetry');
        return true;
      }
    } catch (e) {
      print('MQTT Error: $e');
      _client.disconnect();
    }
    return false;
  }

  void _listenToMessages() {
    _client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (onMessageReceived != null) {
        onMessageReceived!(c[0].topic, jsonDecode(payload));
      }
    });
  }

  void subscribe(String topic) {
    if (_client.connectionStatus!.state == MqttConnectionState.connected) {
      _client.subscribe(topic, MqttQos.atMostOnce);
    }
  }

  void publish(String topic, Map<String, dynamic> payload) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(payload));
    _client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() => _client.disconnect();
  void _onConnected() => print('Connected');
  void _onDisconnected() => print('Disconnected');
}
