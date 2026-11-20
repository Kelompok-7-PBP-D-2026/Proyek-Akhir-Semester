import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mbg_mobile/screens/venue/venue.dart';
import 'package:mbg_mobile/screens/venue/venue_service.dart';

const _json = {'content-type': 'application/json'};

const _venueJson = {
  'id': 1,
  'nama': 'Lobi Gedung A',
  'fakultas': 'fasilkom',
  'alamat': 'Gedung A, lantai 1',
  'latitude': '-6.364100',
  'longitude': '106.827200',
  'deskripsi_akses': 'Dekat lift.',
};

const _input = VenueInput(
  nama: 'Lobi Gedung A',
  fakultas: 'fasilkom',
  latitude: -6.3641,
  longitude: 106.8272,
);

VenueService _service(
  MockClient client, {
  Map<String, String> Function()? headers,
}) {
  return VenueService(
    client: client,
    endpoint: Uri.parse('https://example.test/venue/api/venue/'),
    headersProvider: headers,
  );
}

void main() {
  group('VenueService', () {
    test('fetchVenues membaca daftar DRF', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers['Accept'], 'application/json');
        return http.Response(jsonEncode([_venueJson]), 200, headers: _json);
      });

      final venues = await _service(client).fetchVenues();

      expect(venues, hasLength(1));
      expect(venues.single.nama, 'Lobi Gedung A');
      expect(venues.single.latitude, -6.3641);
    });

    test('fetchVenues membaca respons berhalaman (results)', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'results': [_venueJson],
          }),
          200,
          headers: _json,
        );
      });

      expect(await _service(client).fetchVenues(), hasLength(1));
    });

    test('fetchVenues melempar VenueRequestException bila HTTP bukan 200', () {
      final client = MockClient((_) async => http.Response('', 503));

      expect(
        _service(client).fetchVenues(),
        throwsA(
          isA<VenueRequestException>().having(
            (e) => e.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    test('createVenue mengirim JSON dan header tambahan', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.headers['X-CSRFToken'], 'token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['latitude'], '-6.364100');
        expect(body['fakultas'], 'fasilkom');
        return http.Response(jsonEncode(_venueJson), 201, headers: _json);
      });

      final venue = await _service(
        client,
        headers: () => {'X-CSRFToken': 'token'},
      ).createVenue(_input);

      expect(venue.id, 1);
    });

    test('updateVenue memakai PUT ke URL detail', () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/venue/api/venue/1/');
        return http.Response(jsonEncode(_venueJson), 200, headers: _json);
      });

      expect((await _service(client).updateVenue(1, _input)).id, 1);
    });

    test('deleteVenue menerima 204', () async {
      final client = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/venue/api/venue/1/');
        return http.Response('', 204);
      });

      await _service(client).deleteVenue(1);
    });

    test('401 dan 403 menjadi VenueAuthException', () {
      final client = MockClient(
        (_) async => http.Response('{"detail":"x"}', 403),
      );

      expect(
        _service(client).createVenue(_input),
        throwsA(isA<VenueAuthException>()),
      );
    });

    test('400 membawa pesan dari server', () {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'non_field_errors': ['Nama sudah dipakai.'],
          }),
          400,
          headers: _json,
        );
      });

      expect(
        _service(client).createVenue(_input),
        throwsA(
          isA<VenueValidationException>().having(
            (e) => e.message,
            'message',
            'Nama sudah dipakai.',
          ),
        ),
      );
    });

    test('searchAddress memakai User-Agent dan melewati hasil rusak', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'nominatim.openstreetmap.org');
        expect(request.headers['User-Agent'], startsWith('MBG-Mobile'));
        return http.Response(
          jsonEncode([
            {
              'name': 'Gedung A',
              'display_name':
                  'Gedung A, Fasilkom UI, Kampus UI Depok, Beji, Depok',
              'lat': '-6.3641',
              'lon': '106.8272',
            },
            {'name': 'Rusak', 'display_name': 'x', 'lat': 'abc', 'lon': '1'},
          ]),
          200,
          headers: _json,
        );
      });

      final results = await _service(client).searchAddress('gedung a');

      expect(results, hasLength(1));
      expect(results.single.title, 'Gedung A');
      expect(results.single.subtitle, 'Fasilkom UI, Kampus UI Depok, Beji');
    });

    test('describeVenueError ramah pengguna', () {
      expect(
        describeVenueError(const VenueAuthException(403)),
        'Masuk sebagai admin atau donor untuk mengelola venue.',
      );
      expect(describeVenueError(Exception('x')), contains('koneksi'));
    });
  });
}
