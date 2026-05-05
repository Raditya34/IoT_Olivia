class ApiConfig {
  /// URL Backend Laravel di Railway.
  /// Pastikan tidak ada tanda '/' di akhir kalimat agar tidak double saat dipanggil di ApiService.
  static const String baseUrl = 'https://olivia-production.up.railway.app/api';

  /// Batas waktu tunggu koneksi (dalam milidetik).
  /// Sangat penting untuk mencegah aplikasi loading selamanya saat sinyal lemah.
  static const int connectTimeout = 15000; // 15 detik
  static const int receiveTimeout = 15000; // 15 detik

  /// Header standar untuk permintaan API
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
