/// Peta OpenStreetMap untuk modul Venue (paket `flutter_map`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'venue.dart';
import 'venue_geo.dart';
import 'venue_widgets.dart';

const String _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const String _appPackage = 'com.kelompok7.mbg_mobile';

Widget _tileLayer() =>
    TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _appPackage);

/// Atribusi OpenStreetMap wajib ditampilkan di setiap peta.
Widget _attribution() => RichAttributionWidget(
  attributions: [TextSourceAttribution('OpenStreetMap contributors')],
);

/// Penanda bulat bergaya Figma: hijau untuk venue, oranye untuk posisi/titik terpilih.
class MapPin extends StatelessWidget {
  const MapPin({
    super.key,
    this.color = VenueColors.forest,
    this.size = 26,
    this.highlighted = false,
  });

  final Color color;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: highlighted ? VenueColors.sunshine : Colors.black26,
            blurRadius: highlighted ? 0 : 4,
            spreadRadius: highlighted ? 5 : 0,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.3,
          height: size * 0.3,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Peta daftar: semua venue (pin hijau) dan posisi pengguna (pin oranye).
class VenuesMap extends StatelessWidget {
  const VenuesMap({
    super.key,
    required this.venues,
    this.userLatitude,
    this.userLongitude,
    this.selectedId,
    this.onSelect,
    this.height = 230,
  });

  final List<Venue> venues;
  final double? userLatitude;
  final double? userLongitude;
  final int? selectedId;
  final ValueChanged<int>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (venues.isEmpty) return const SizedBox.shrink();
    final points = <LatLng>[
      for (final venue in venues) LatLng(venue.latitude, venue.longitude),
    ];
    final userLat = userLatitude;
    final userLng = userLongitude;
    final user = (userLat != null && userLng != null)
        ? LatLng(userLat, userLng)
        : null;

    // Posisi pengguna ikut membingkai peta hanya bila dekat dengan venue,
    // supaya peta tidak melebar ke seluruh kota saat pengguna jauh dari kampus.
    final fitPoints = <LatLng>[
      ...points,
      if (user != null &&
          haversineKm(
                user.latitude,
                user.longitude,
                venues.first.latitude,
                venues.first.longitude,
              ) <
              20)
        user,
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          key: ValueKey('${venues.map((v) => v.id).join(',')}|${user != null}'),
          options: MapOptions(
            initialCenter: fitPoints.first,
            initialZoom: 16,
            initialCameraFit: fitPoints.length > 1
                ? CameraFit.coordinates(
                    coordinates: fitPoints,
                    padding: const EdgeInsets.all(36),
                    maxZoom: 17,
                  )
                : null,
          ),
          children: [
            _tileLayer(),
            MarkerLayer(
              markers: [
                for (final venue in venues)
                  Marker(
                    point: LatLng(venue.latitude, venue.longitude),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => onSelect?.call(venue.id),
                      child: Center(
                        child: MapPin(highlighted: venue.id == selectedId),
                      ),
                    ),
                  ),
                if (user != null)
                  Marker(
                    point: user,
                    width: 36,
                    height: 36,
                    child: const Center(
                      child: MapPin(color: VenueColors.carrot, size: 30),
                    ),
                  ),
              ],
            ),
            _attribution(),
          ],
        ),
      ),
    );
  }
}

/// Peta detail: satu pin oranye, tidak bisa digeser agar tidak bentrok dengan scroll.
class VenuePinMap extends StatelessWidget {
  const VenuePinMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 170,
  });

  final double latitude;
  final double longitude;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          key: ValueKey('$latitude,$longitude'),
          options: MapOptions(
            initialCenter: point,
            initialZoom: 17,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            _tileLayer(),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 36,
                  height: 36,
                  child: const Center(
                    child: MapPin(color: VenueColors.carrot, size: 30),
                  ),
                ),
              ],
            ),
            _attribution(),
          ],
        ),
      ),
    );
  }
}

/// Peta form: pin tetap di tengah, pengguna menggeser peta untuk memilih titik.
/// Koordinat tengah dikirim lewat [onMoved] hanya saat digeser oleh pengguna.
class VenuePickerMap extends StatelessWidget {
  const VenuePickerMap({
    super.key,
    required this.controller,
    required this.initialLatitude,
    required this.initialLongitude,
    required this.onMoved,
    this.height = 200,
  });

  final MapController controller;
  final double initialLatitude;
  final double initialLongitude;
  final void Function(double latitude, double longitude) onMoved;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: LatLng(initialLatitude, initialLongitude),
                initialZoom: 17,
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    onMoved(camera.center.latitude, camera.center.longitude);
                  }
                },
              ),
              children: [_tileLayer(), _attribution()],
            ),
            const IgnorePointer(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_on,
                    size: 40,
                    color: VenueColors.carrot,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
