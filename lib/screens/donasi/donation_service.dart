import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'donation.dart';

class DonationPage {
  const DonationPage({required this.items, required this.totalCount});

  final List<Donation> items;
  final int totalCount;
}

/// Mengisolasi komunikasi HTTP modul Donasi dari kode tampilan.
class DonationService {
  DonationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DonationPage> fetchDonations() async {
    final response = await _client.get(
      ApiConfig.donasi,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw DonationRequestException(response.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) {
      throw const FormatException('Format respons Donasi tidak dikenali.');
    }

    final items = decoded
        .whereType<Map<String, dynamic>>()
        .map(Donation.fromJson)
        .toList();
    return DonationPage(items: items, totalCount: items.length);
  }
}

class DonationRequestException implements Exception {
  const DonationRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Gagal memuat donasi (HTTP $statusCode).';
}
