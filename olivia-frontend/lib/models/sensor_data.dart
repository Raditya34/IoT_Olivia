class EspData {
  final double? suhu;
  final double? volume;
  final int? turbidity;
  final int? viscosity;
  final int? warna;

  EspData({this.suhu, this.volume, this.turbidity, this.viscosity, this.warna});

  // Untuk mengolah data dari API Laravel
  factory EspData.fromJson(Map<String, dynamic> json) {
    return EspData(
      suhu: (json['suhu'] != null) ? json['suhu'].toDouble() : 0.0,
      volume: (json['volume'] != null) ? json['volume'].toDouble() : 0.0,
      turbidity: json['turbidity'] ?? 0,
      viscosity: json['viscosity'] ?? 0,
      warna: json['warna'] ?? 0,
    );
  }
}
