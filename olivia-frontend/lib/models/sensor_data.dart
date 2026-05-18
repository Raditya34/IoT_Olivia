class EspData {
  final double suhuArang;
  final double suhuBleaching;
  final double volume;
  final double turbidity;
  final double viscosity;
  final int r;
  final int g;
  final int b;

  EspData({
    required this.suhuArang,
    required this.suhuBleaching,
    required this.volume,
    required this.turbidity,
    required this.viscosity,
    required this.r,
    required this.g,
    required this.b,
  });

  // Untuk mengolah data dari API Laravel / MQTT payload secara konsisten
  factory EspData.fromJson(Map<String, dynamic> json) {
    return EspData(
      suhuArang: (json['suhu_arang'] ?? 0.0).toDouble(),
      suhuBleaching: (json['suhu_bleaching'] ?? 0.0).toDouble(),
      volume: (json['volume'] ?? 0.0).toDouble(),
      turbidity: (json['turbidity'] ?? 0.0).toDouble(),
      viscosity: (json['viscosity'] ?? 0.0).toDouble(),
      r: json['r'] ?? 0,
      g: json['g'] ?? 0,
      b: json['b'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'suhu_arang': suhuArang,
      'suhu_bleaching': suhuBleaching,
      'volume': volume,
      'turbidity': turbidity,
      'viscosity': viscosity,
      'r': r,
      'g': g,
      'b': b,
    };
  }
}
