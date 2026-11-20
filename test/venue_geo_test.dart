import 'package:flutter_test/flutter_test.dart';
import 'package:mbg_mobile/screens/donasi/donation.dart';
import 'package:mbg_mobile/screens/venue/venue.dart';
import 'package:mbg_mobile/screens/venue/venue_donations.dart';
import 'package:mbg_mobile/screens/venue/venue_geo.dart';

Donation _donation(String location, int portions, DateTime endsAt) {
  return Donation(
    id: 1,
    name: 'Nasi',
    portionCount: portions,
    location: location,
    availableAt: endsAt.subtract(const Duration(hours: 4)),
    pickupEndsAt: endsAt,
    status: portions > 0 ? 'tersedia' : 'habis',
    statusLabel: portions > 0 ? 'Tersedia' : 'Habis',
  );
}

void main() {
  group('venue_geo', () {
    test('haversineKm menghitung jarak garis lurus', () {
      expect(haversineKm(-6.36, 106.82, -6.36, 106.82), closeTo(0, 1e-9));
      // 0,01 derajat lintang kira-kira 1,11 km.
      expect(haversineKm(-6.36, 106.82, -6.35, 106.82), closeTo(1.11, 0.01));
    });

    test('format memakai koma sebagai pemisah desimal', () {
      expect(formatKm(0.84), '0,8');
      expect(formatKm(2.06), '2,1');
      expect(formatCoordinate(-6.3641), '-6,3641');
    });

    test('parseCoordinate menerima koma dan titik', () {
      expect(parseCoordinate('-6,3641'), -6.3641);
      expect(parseCoordinate(' 106.8272 '), 106.8272);
      expect(parseCoordinate('abc'), isNull);
      expect(parseCoordinate(''), isNull);
    });

    test('rentang koordinat', () {
      expect(isValidLatitude(90), isTrue);
      expect(isValidLatitude(91), isFalse);
      expect(isValidLongitude(-180), isTrue);
      expect(isValidLongitude(181), isFalse);
    });
  });

  group('Venue', () {
    const json = {
      'id': 1,
      'nama': 'Lobi Gedung A',
      'fakultas': 'fasilkom',
      'alamat': 'Gedung A, lantai 1',
      'latitude': '-6.364100',
      'longitude': '106.827200',
      'deskripsi_akses': 'Dekat lift.',
    };

    test('fromJson membaca koordinat string dari DRF', () {
      final venue = Venue.fromJson(json);
      expect(venue.latitude, -6.3641);
      expect(venue.longitude, 106.8272);
      expect(venue.unitLabel, 'Fasilkom UI');
      expect(venue.unitShort, 'Fasilkom');
      expect(venue.gedung, 'Gedung A, lantai 1');
    });

    test('gedung kembali ke nama bila alamat kosong', () {
      expect(Venue.fromJson({...json, 'alamat': ''}).gedung, 'Lobi Gedung A');
    });

    test('koordinat tidak valid melempar FormatException', () {
      expect(
        () => Venue.fromJson({...json, 'latitude': 'abc'}),
        throwsFormatException,
      );
    });

    test('toJson mengirim koordinat 6 desimal sebagai string', () {
      final body = const VenueInput(
        nama: 'A',
        fakultas: 'ft',
        latitude: -6.3641,
        longitude: 106.8272,
      ).toJson();
      expect(body['latitude'], '-6.364100');
      expect(body['longitude'], '106.827200');
    });
  });

  group('pencocokan donasi', () {
    final venue = Venue.fromJson(const {
      'id': 1,
      'nama': 'Lobi Gedung A',
      'fakultas': 'fasilkom',
      'latitude': '-6.364100',
      'longitude': '106.827200',
    });
    final now = DateTime(2026, 11, 20, 12);
    final donations = [
      _donation('lobi gedung a ', 40, now.add(const Duration(hours: 3))),
      _donation('Lobi Gedung A', 0, now.add(const Duration(hours: 2))),
      _donation('Lobi Gedung A', 10, now.subtract(const Duration(minutes: 5))),
      _donation('Aula FEB', 5, now.add(const Duration(hours: 1))),
    ];

    test('hanya donasi venue ini yang belum lewat batas pengambilan', () {
      final open = openDonationsAt(venue, donations, now);
      expect(open, hasLength(2));
      expect(
        open.first.portionCount,
        0,
        reason: 'diurutkan dari batas terdekat',
      );
    });

    test('donasi aktif tidak menghitung stok habis', () {
      expect(activeDonationCount(venue, donations, now), 1);
    });
  });
}
