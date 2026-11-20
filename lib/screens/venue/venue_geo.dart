/// Perhitungan jarak dan format koordinat untuk modul Venue.
library;

import 'dart:math' as math;

/// Titik acuan jarak bila lokasi pengguna tidak tersedia (perkiraan pusat
/// kampus UI Depok, sama dengan situs web).
const double kCampusLat = -6.3650;
const double kCampusLng = 106.8280;

const double _earthRadiusKm = 6371.0088;

/// Jarak garis lurus dua koordinat dalam kilometer (rumus haversine).
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

/// 0.84 -> "0,8" (satu angka di belakang koma, pemisah koma).
String formatKm(double km) => km.toStringAsFixed(1).replaceAll('.', ',');

/// -6.3641 -> "-6,3641".
String formatCoordinate(double value) =>
    value.toStringAsFixed(4).replaceAll('.', ',');

/// Menerima koma atau titik sebagai pemisah desimal. Mengembalikan null bila bukan angka.
double? parseCoordinate(String raw) {
  final normalized = raw.trim().replaceAll('\u2212', '-').replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  final value = double.tryParse(normalized);
  if (value == null || value.isNaN || value.isInfinite) return null;
  return value;
}

bool isValidLatitude(double value) => value >= -90 && value <= 90;
bool isValidLongitude(double value) => value >= -180 && value <= 180;
