/// Komunikasi HTTP modul Venue dan Lokasi (dipisah dari kode tampilan).
///
/// Baca daftar venue bersifat publik. Tulis (POST/PUT/DELETE) menuntut login
/// admin atau donor di web service; sambungkan [headersProvider] ke
/// mekanisme login aplikasi (cookie sesi + token CSRF) bila sudah tersedia.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'venue.dart';

/// Hasil pencarian alamat OpenStreetMap (Nominatim).
class AddressResult {
  const AddressResult({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
  });

  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
}

class VenueRequestException implements Exception {
  const VenueRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Permintaan venue gagal (HTTP $statusCode).';
}

/// Respons 401/403: belum login, atau bukan admin/donor.
class VenueAuthException extends VenueRequestException {
  const VenueAuthException(super.statusCode);

  @override
  String toString() => 'Masuk sebagai admin atau donor untuk mengelola venue.';
}

/// Respons 400: data ditolak server (pesan dari server ada di [message]).
class VenueValidationException extends VenueRequestException {
  const VenueValidationException(this.message) : super(400);

  final String message;

  @override
  String toString() => message;
}

/// Pesan yang aman ditampilkan ke pengguna untuk error apa pun.
String describeVenueError(Object error) {
  if (error is VenueRequestException) return error.toString();
  if (error is FormatException) {
    return 'Format data dari server tidak dikenali.';
  }
  return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
}

class VenueService {
  VenueService({http.Client? client, Uri? endpoint, this.headersProvider})
    : _client = client ?? http.Client(),
      _endpoint = endpoint ?? ApiConfig.venue;

  final http.Client _client;
  final Uri _endpoint;

  /// Header tambahan untuk request tulis (misalnya Cookie dan X-CSRFToken).
  final Map<String, String> Function()? headersProvider;

  static const String _userAgent =
      'MBG-Mobile/1.0 (Proyek Akhir Semester Kelompok 7 PBP D 2026)';

  Uri _detailUri(int id) {
    final base = _endpoint.toString();
    return Uri.parse(base.endsWith('/') ? '$base$id/' : '$base/$id/');
  }

  Map<String, String> _writeHeaders() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    ...?headersProvider?.call(),
  };

  Future<List<Venue>> fetchVenues() async {
    final response = await _client.get(
      _endpoint,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw VenueRequestException(response.statusCode);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['results'] is List
              ? decoded['results'] as List
              : throw const FormatException(
                  'Format respons Venue tidak dikenali.',
                ));
    return list.whereType<Map<String, dynamic>>().map(Venue.fromJson).toList();
  }

  Future<Venue> createVenue(VenueInput input) async {
    final response = await _client.post(
      _endpoint,
      headers: _writeHeaders(),
      body: jsonEncode(input.toJson()),
    );
    return _readVenue(response, expected: 201);
  }

  Future<Venue> updateVenue(int id, VenueInput input) async {
    final response = await _client.put(
      _detailUri(id),
      headers: _writeHeaders(),
      body: jsonEncode(input.toJson()),
    );
    return _readVenue(response, expected: 200);
  }

  Future<void> deleteVenue(int id) async {
    final response = await _client.delete(
      _detailUri(id),
      headers: _writeHeaders(),
    );
    if (response.statusCode == 204 || response.statusCode == 200) return;
    throw _errorFor(response);
  }

  Venue _readVenue(http.Response response, {required int expected}) {
    if (response.statusCode != expected) throw _errorFor(response);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format respons Venue tidak dikenali.');
    }
    return Venue.fromJson(decoded);
  }

  VenueRequestException _errorFor(http.Response response) {
    final code = response.statusCode;
    if (code == 401 || code == 403) return VenueAuthException(code);
    if (code == 400) return VenueValidationException(_firstMessage(response));
    return VenueRequestException(code);
  }

  /// DRF membalas 400 sebagai {"field": ["pesan"]} atau {"detail": "pesan"}.
  String _firstMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        for (final value in body.values) {
          if (value is List && value.isNotEmpty) return value.first.toString();
          if (value is String && value.isNotEmpty) return value;
        }
      }
    } on FormatException {
      // Body bukan JSON: pakai pesan umum di bawah.
    }
    return 'Data venue ditolak server. Periksa isian formulir.';
  }

  /// Pencarian alamat lewat Nominatim (OpenStreetMap), dibatasi di sekitar kampus UI.
  Future<List<AddressResult>> searchAddress(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '5',
      'countrycodes': 'id',
      'viewbox': '106.78,-6.32,106.87,-6.42',
    });
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Accept-Language': 'id',
        'User-Agent': _userAgent,
      },
    );
    if (response.statusCode != 200) {
      throw VenueRequestException(response.statusCode);
    }
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException(
        'Format respons pencarian alamat tidak dikenali.',
      );
    }
    final results = <AddressResult>[];
    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final lat = double.tryParse(item['lat']?.toString() ?? '');
      final lon = double.tryParse(item['lon']?.toString() ?? '');
      if (lat == null || lon == null) continue;
      final segments = (item['display_name']?.toString() ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final name = item['name']?.toString() ?? '';
      final title = name.isNotEmpty
          ? name
          : (segments.isNotEmpty ? segments.first : 'Tanpa nama');
      final rest = segments.isNotEmpty && segments.first == title
          ? segments.skip(1)
          : segments;
      results.add(
        AddressResult(
          title: title,
          subtitle: rest.take(3).join(', '),
          latitude: lat,
          longitude: lon,
        ),
      );
    }
    return results;
  }
}
