/// Konfigurasi koneksi ke web service Django (PWS).
///
/// Ubah [baseUrl] sesuai domain deployment kelompok sebelum build APK.
/// Untuk emulator Android, `http://10.0.2.2:8000/` mengarah ke localhost
/// mesin development (pakai saat menjalankan `manage.py runserver` lokal).
library;

class ApiConfig {
  /// Domain deployment Django PTS di PWS.
  static const String baseUrl = 'https://<domain-pts>-pws.cs.ui.ac.id';

  /// Base URL untuk development lokal (emulator Android).
  static const String localUrl = 'http://10.0.2.2:8000';

  /// Endpoint yang sedang aktif. Ganti ke [localUrl] saat development.
  static const String activeUrl = baseUrl;

  /// URL endpoint modul Profil Pengguna.
  static Uri get profilDonor =>
      Uri.parse('$activeUrl/api/profil-donor/');
  static Uri get profilPenerima =>
      Uri.parse('$activeUrl/api/profil-penerima/');

  /// URL endpoint modul Donasi Makanan.
  static Uri get donasi => Uri.parse('$activeUrl/donasi/api/donasi/');

  /// URL endpoint modul Klaim dan Reservasi.
  static Uri get claim => Uri.parse('$activeUrl/klaim/api/claim/');

  /// URL endpoint modul Venue dan Lokasi.
  static Uri get venue => Uri.parse('$activeUrl/venue/api/venue/');

  /// URL endpoint modul Laporan Dampak.
  static Uri get laporan => Uri.parse('$activeUrl/laporan/api/laporan/');
}
