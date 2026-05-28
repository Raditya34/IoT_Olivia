// lib/models/sensor_data.dart

class EspData {
  final double suhuArang;
  final double volumeArang; // Sudah spesifik
  final double suhuBleaching;
  final double volumeValidasi; // Sudah spesifik
  final double turbidity;
  final double viscosity;
  final int r;
  final int g;
  final int b;

  EspData({
    required this.suhuArang,
    required this.volumeArang,
    required this.suhuBleaching,
    required this.volumeValidasi,
    required this.turbidity,
    required this.viscosity,
    required this.r,
    required this.g,
    required this.b,
  });

  // Memetakan data dari API Laravel / Payload MQTT gabungan secara presisi
  factory EspData.fromJson(Map<String, dynamic> json) {
    // Ambil sub-object jika ada, jika tidak ada (struktur flat) gunakan fallback ke root json
    final arang = json['arang'] ?? json;
    final bleaching = json['bleaching'] ?? json;
    final validasi = json['validasi'] ?? json;

    return EspData(
      suhuArang: (arang['suhu_arang'] ?? 0.0).toDouble(),
      volumeArang: (arang['volume_arang'] ?? 0.0).toDouble(),
      suhuBleaching: (bleaching['suhu_bleaching'] ?? 0.0).toDouble(),
      volumeValidasi: (validasi['volume_validasi'] ?? 0.0).toDouble(),
      turbidity: (validasi['turbidity'] ?? 0.0).toDouble(),
      viscosity: (validasi['viscosity'] ?? 0.0).toDouble(),
      r: validasi['r'] ?? 0,
      g: validasi['g'] ?? 0,
      b: validasi['b'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suhu_arang': suhuArang,
      'volume_arang': volumeArang,
      'suhu_bleaching': suhuBleaching,
      'volume_validasi': volumeValidasi,
      'turbidity': turbidity,
      'viscosity': viscosity,
      'r': r,
      'g': g,
      'b': b,
    };
  }
}
