import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mbg_mobile/screens/donasi/donation_service.dart';

void main() {
  group('DonationService', () {
    test('parses a DRF list response', () async {
      final client = MockClient((request) async {
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'nama': 'Nasi kotak seminar',
              'jumlah_porsi': 12,
              'lokasi': 'Fasilkom UI',
              'waktu_tersedia': '2026-11-20T08:00:00+07:00',
              'waktu_akhir_pengambilan': '2026-11-20T11:00:00+07:00',
              'status': 'tersedia',
              'status_tampilan': 'Tersedia',
              'catatan': 'Halal',
              'foto_url': null,
            },
          ]),
          200,
          headers: const {'content-type': 'application/json'},
        );
      });

      final page = await DonationService(client: client).fetchDonations();

      expect(page.totalCount, 1);
      expect(page.items, hasLength(1));
      expect(page.items.single.name, 'Nasi kotak seminar');
      expect(page.items.single.portionCount, 12);
      expect(page.items.single.statusLabel, 'Tersedia');
    });

    test(
      'throws a meaningful exception for an unsuccessful response',
      () async {
        final client = MockClient((_) async => http.Response('', 503));

        expect(
          DonationService(client: client).fetchDonations(),
          throwsA(
            isA<DonationRequestException>().having(
              (error) => error.statusCode,
              'statusCode',
              503,
            ),
          ),
        );
      },
    );
  });
}
