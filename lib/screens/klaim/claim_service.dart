/// Komunikasi HTTP modul Klaim dan Reservasi
/// Autentikasi disambungkan lewat [AuthHeadersProvider]: cukup beri fungsi yang
/// mengembalikan header (Cookie, X-CSRFToken, atau Authorization) dari sesi login.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'klaim.dart';

/// Mengembalikan header autentikasi untuk setiap request.
typedef AuthHeadersProvider = Future<Map<String, String>> Function();

/// Hasil daftar berpaginasi dari DRF ({count, next, results}).
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.count,
    required this.hasNext,
  });

  final List<T> items;
  final int count;
  final bool hasNext;
}

/// Kegagalan dari server: status HTTP dan pesan Indonesia dari API bila ada.
class ClaimApiException implements Exception {
  const ClaimApiException(this.statusCode, [this.detail = '']);

  final int statusCode;
  final String detail;

  /// 401/403: belum login, atau peran tidak sesuai.
  bool get isAuthProblem => statusCode == 401 || statusCode == 403;

  String get message {
    if (detail.isNotEmpty) return detail;
    if (isAuthProblem) return 'Masuk dulu untuk melihat klaim.';
    if (statusCode == 404) return 'Data tidak ditemukan.';
    return 'Permintaan gagal (HTTP $statusCode).';
  }

  @override
  String toString() => message;
}

class ClaimService {
  ClaimService({http.Client? client, AuthHeadersProvider? authHeaders})
    : _client = client ?? http.Client(),
      _authHeaders = authHeaders ?? _noAuth;

  static Future<Map<String, String>> _noAuth() async => const {};

  final http.Client _client;
  final AuthHeadersProvider _authHeaders;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse(ApiConfig.activeUrl).resolve(path);
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<dynamic> _send(String method, Uri uri, {Object? body}) async {
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    request.headers.addAll(await _authHeaders());

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    final text = utf8.decode(response.bodyBytes);
    dynamic decoded;
    try {
      decoded = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw ClaimApiException(response.statusCode, _messageFrom(decoded));
  }

  /// Ambil pesan dari {"detail": "..."} atau dari kesalahan per field DRF.
  String _messageFrom(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return '';
    final detail = decoded['detail'];
    if (detail != null) return detail.toString();
    final parts = <String>[];
    for (final value in decoded.values) {
      if (value is List) {
        parts.addAll(value.map((e) => e.toString()));
      } else if (value != null) {
        parts.add(value.toString());
      }
    }
    return parts.join(' ');
  }

  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Format respons Klaim tidak dikenali.');
  }

  PagedResult<T> _paged<T>(
    Object? data,
    T Function(Map<String, dynamic>) parse,
  ) {
    final map = _asMap(data);
    final results = map['results'];
    final items = results is List
        ? results.whereType<Map<String, dynamic>>().map(parse).toList()
        : <T>[];
    return PagedResult<T>(
      items: items,
      count: (map['count'] as num?)?.toInt() ?? items.length,
      hasNext: map['next'] != null,
    );
  }

  // ---- penerima ----

  /// GET /klaim/api/claim/ : klaim milik penerima yang login.
  Future<PagedResult<Claim>> fetchClaims({String? status, int page = 1}) async {
    final data = await _send(
      'GET',
      _uri('/klaim/api/claim/', {
        'page': '$page',
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
    return _paged(data, Claim.fromJson);
  }

  /// `GET /klaim/api/claim/<id>/` : detail, timeline, dan koordinat venue.
  Future<Claim> fetchClaim(int id) async {
    final data = await _send('GET', _uri('/klaim/api/claim/$id/'));
    return Claim.fromJson(_asMap(data));
  }

  /// `GET /klaim/api/claim/form/<donationId>/` : stok, batas, slot, atau alasan ditolak.
  Future<ClaimFormInfo> fetchFormInfo(int donationId) async {
    final data = await _send('GET', _uri('/klaim/api/claim/form/$donationId/'));
    return ClaimFormInfo.fromJson(_asMap(data));
  }

  /// POST /klaim/api/claim/ : [pickupTime] nilai ISO dari salah satu slot.
  Future<Claim> createClaim({
    required int donationId,
    required int portions,
    required String pickupTime,
    String note = '',
  }) async {
    final data = await _send(
      'POST',
      _uri('/klaim/api/claim/'),
      body: {
        'donation_id': donationId,
        'portions': portions,
        'pickup_time': pickupTime,
        if (note.isNotEmpty) 'note': note,
      },
    );
    return Claim.fromJson(_asMap(data));
  }

  /// `POST /klaim/api/claim/<id>/cancel/`
  Future<Claim> cancelClaim(int id) async {
    final data = await _send('POST', _uri('/klaim/api/claim/$id/cancel/'));
    return Claim.fromJson(_asMap(data));
  }

  // ---- donor ----

  /// GET /klaim/api/incoming/ : klaim atas donasi milik donor.
  Future<PagedResult<IncomingClaim>> fetchIncoming({
    String? status,
    int page = 1,
  }) async {
    final data = await _send(
      'GET',
      _uri('/klaim/api/incoming/', {
        'page': '$page',
        if (status != null && status.isNotEmpty) 'status': status,
      }),
    );
    return _paged(data, IncomingClaim.fromJson);
  }

  /// GET /klaim/api/incoming/stats/
  Future<ClaimStats> fetchStats() async {
    final data = await _send('GET', _uri('/klaim/api/incoming/stats/'));
    return ClaimStats.fromJson(_asMap(data));
  }

  /// `POST /klaim/api/incoming/<id>/verify/` : mengembalikan pesan sukses dari server.
  Future<String> verifyCode(int id, String code) async {
    final data = await _send(
      'POST',
      _uri('/klaim/api/incoming/$id/verify/'),
      body: {'pickup_code': code},
    );
    return _asMap(data)['detail']?.toString() ?? 'Kode cocok.';
  }

  void close() => _client.close();
}
