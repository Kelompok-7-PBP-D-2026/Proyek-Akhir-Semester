/// Lokasi pengguna untuk menghitung jarak ke venue.
///
/// Semua pemakaian paket `geolocator` ada di file ini. Bila izin ditolak atau
/// lokasi tidak tersedia, fungsi mengembalikan null dan tampilan memakai titik
/// pusat kampus sebagai acuan jarak.
library;

import 'package:geolocator/geolocator.dart';

class UserLocation {
  const UserLocation(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

Future<UserLocation?> currentUserLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
      ),
    );
    return UserLocation(position.latitude, position.longitude);
  } catch (_) {
    return null;
  }
}
