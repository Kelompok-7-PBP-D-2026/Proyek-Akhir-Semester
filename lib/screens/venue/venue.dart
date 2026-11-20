/// Data Venue dari endpoint Django REST Framework (`/venue/api/venue/`).
///
/// Kode fakultas/unit sama dengan `UnitVenue` di aplikasi Django (venue/models.py).
library;

/// Nama lengkap fakultas/unit per kode.
const Map<String, String> kVenueUnitLabels = {
  'fasilkom': 'Fasilkom UI',
  'ft': 'Fakultas Teknik',
  'feb': 'Fakultas Ekonomi',
  'fmipa': 'FMIPA UI',
  'fh': 'Fakultas Hukum',
  'fk': 'Fakultas Kedokteran',
  'fik': 'Fakultas Ilmu Keperawatan',
  'fisip': 'FISIP UI',
  'fpsi': 'Fakultas Psikologi',
  'fib': 'Fakultas Ilmu Pengetahuan Budaya',
  'ff': 'Fakultas Farmasi',
  'vokasi': 'Vokasi UI',
  'kampus': 'Gedung Pusat',
};

/// Nama pendek untuk chip filter dan badge kartu (sesuai Figma).
const Map<String, String> kVenueUnitShort = {
  'fasilkom': 'Fasilkom',
  'ft': 'Teknik',
  'feb': 'FEB',
  'fmipa': 'FMIPA',
  'fh': 'FH',
  'fk': 'FK',
  'fik': 'FIK',
  'fisip': 'FISIP',
  'fpsi': 'F.Psi',
  'fib': 'FIB',
  'ff': 'FF',
  'vokasi': 'Vokasi',
  'kampus': 'Kampus',
};

class Venue {
  const Venue({
    required this.id,
    required this.nama,
    required this.fakultas,
    required this.latitude,
    required this.longitude,
    this.alamat = '',
    this.deskripsiAkses = '',
  });

  final int id;
  final String nama;

  /// Kode fakultas/unit, misalnya `fasilkom`.
  final String fakultas;
  final double latitude;
  final double longitude;

  /// Ditampilkan sebagai "Gedung" di detail (contoh: "Gedung A, lantai 1").
  final String alamat;
  final String deskripsiAkses;

  String get unitLabel => kVenueUnitLabels[fakultas] ?? fakultas;
  String get unitShort => kVenueUnitShort[fakultas] ?? unitLabel;

  /// Teks baris "Gedung": alamat bila ada, selain itu nama venue.
  String get gedung => alamat.isNotEmpty ? alamat : nama;

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: (json['id'] as num).toInt(),
      nama: json['nama']?.toString() ?? 'Venue tanpa nama',
      fakultas: json['fakultas']?.toString() ?? '',
      // DRF mengirim DecimalField sebagai string ("-6.364100").
      latitude: _toDouble(json['latitude'], 'latitude'),
      longitude: _toDouble(json['longitude'], 'longitude'),
      alamat: json['alamat']?.toString() ?? '',
      deskripsiAkses: json['deskripsi_akses']?.toString() ?? '',
    );
  }

  static double _toDouble(Object? value, String field) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw FormatException('Koordinat $field venue tidak valid: $value');
    }
    return parsed;
  }
}

/// Data yang dikirim saat membuat atau mengubah venue.
class VenueInput {
  const VenueInput({
    required this.nama,
    required this.fakultas,
    required this.latitude,
    required this.longitude,
    this.alamat = '',
    this.deskripsiAkses = '',
  });

  final String nama;
  final String fakultas;
  final double latitude;
  final double longitude;
  final String alamat;
  final String deskripsiAkses;

  /// Koordinat dikirim sebagai string 6 desimal agar sesuai DecimalField di Django.
  Map<String, dynamic> toJson() => {
    'nama': nama,
    'fakultas': fakultas,
    'latitude': latitude.toStringAsFixed(6),
    'longitude': longitude.toStringAsFixed(6),
    'alamat': alamat,
    'deskripsi_akses': deskripsiAkses,
  };
}
