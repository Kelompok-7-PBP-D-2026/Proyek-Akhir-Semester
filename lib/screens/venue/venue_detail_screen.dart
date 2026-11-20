/// Detail venue (Figma 4B) dan konfirmasi hapus (Figma 4D).
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../donasi/donasi_screen.dart';
import '../donasi/donation.dart';
import 'venue.dart';
import 'venue_donations.dart';
import 'venue_form_screen.dart';
import 'venue_geo.dart';
import 'venue_location.dart';
import 'venue_map.dart';
import 'venue_service.dart';
import 'venue_widgets.dart';

class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({
    super.key,
    required this.venue,
    this.donations,
    this.user,
    this.service,
    this.canManage = true,
  });

  final Venue venue;

  /// Semua donasi dari API (difilter ke venue ini). Null bila gagal dimuat.
  final List<Donation>? donations;
  final UserLocation? user;
  final VenueService? service;

  /// Menampilkan tombol Hapus dan Edit. Ubah sesuai peran (admin/donor) bila
  /// login sudah tersedia di aplikasi; server tetap menolak peran lain.
  final bool canManage;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  late final VenueService _service = widget.service ?? VenueService();
  late Venue _venue = widget.venue;
  bool _changed = false;

  List<Donation>? get _openDonations {
    final all = widget.donations;
    if (all == null) return null;
    return openDonationsAt(_venue, all, DateTime.now());
  }

  int get _activeCount {
    final all = widget.donations;
    if (all == null) return 0;
    return activeDonationCount(_venue, all, DateTime.now());
  }

  Future<void> _openRoute() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${_venue.latitude},${_venue.longitude}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      showVenueSnackBar(context, 'Tidak dapat membuka aplikasi peta.');
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<Venue>(
      MaterialPageRoute(
        builder: (_) => VenueFormScreen(venue: _venue, service: _service),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _venue = updated;
        _changed = true;
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: VenueColors.page,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) =>
          _DeleteSheet(venueName: _venue.nama, activeDonations: _activeCount),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteVenue(_venue.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      showVenueSnackBar(context, describeVenueError(error));
    }
  }

  void _openAllDonations() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const DonasiScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final distanceKm = haversineKm(
      user?.latitude ?? kCampusLat,
      user?.longitude ?? kCampusLng,
      _venue.latitude,
      _venue.longitude,
    );
    final originLabel = user != null ? 'dari lokasimu' : 'dari pusat kampus';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: VenueColors.page,
        appBar: AppBar(
          backgroundColor: VenueColors.page,
          surfaceTintColor: Colors.transparent,
          title: const Text('Detail venue'),
        ),
        bottomNavigationBar: widget.canManage ? _buildActionBar() : null,
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            VenuePinMap(latitude: _venue.latitude, longitude: _venue.longitude),
            const SizedBox(height: 16),
            Text(
              'VENUE · ${_venue.unitLabel.toUpperCase()}',
              style: const TextStyle(
                color: VenueColors.carrot,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _venue.nama.toUpperCase(),
              style: const TextStyle(
                color: VenueColors.forest,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_activeCount > 0)
                  const VenuePill(
                    label: 'Aktif',
                    showDot: true,
                    background: VenueColors.kiwi,
                    foreground: VenueColors.text,
                  ),
                VenuePill(label: '${formatKm(distanceKm)} km'),
              ],
            ),
            const SizedBox(height: 16),
            VenueSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi venue',
                    style: TextStyle(
                      color: VenueColors.forest,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow('Fakultas', _venue.unitLabel),
                  _InfoRow('Gedung', _venue.gedung),
                  _InfoRow(
                    'Koordinat',
                    '${formatCoordinate(_venue.latitude)} · '
                        '${formatCoordinate(_venue.longitude)}',
                  ),
                  _InfoRow('Jarak', '${formatKm(distanceKm)} km $originLabel'),
                  _InfoRow(
                    'Akses',
                    _venue.deskripsiAkses.isEmpty
                        ? 'Belum ada deskripsi akses.'
                        : _venue.deskripsiAkses,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openRoute,
              style: FilledButton.styleFrom(
                backgroundColor: VenueColors.cream,
                foregroundColor: VenueColors.forest,
                minimumSize: const Size.fromHeight(48),
              ),
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('Buka rute di peta'),
            ),
            const SizedBox(height: 12),
            _buildDonationsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationsCard() {
    final open = _openDonations;
    return VenueSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Donasi di venue ini',
            style: TextStyle(
              color: VenueColors.forest,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (open == null)
            const Text(
              'Data donasi tidak dapat dimuat.',
              style: TextStyle(color: VenueColors.muted),
            )
          else if (open.isEmpty)
            const Text(
              'Belum ada donasi aktif di venue ini.',
              style: TextStyle(color: VenueColors.muted),
            )
          else
            for (final donation in open.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.name,
                            style: const TextStyle(
                              color: VenueColors.forest,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${donation.portionCount} porsi',
                            style: const TextStyle(
                              color: VenueColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    VenuePill(
                      label: donation.statusLabel,
                      showDot: true,
                      background: donation.portionCount > 0
                          ? VenueColors.kiwi
                          : VenueColors.tomato,
                      foreground: donation.portionCount > 0
                          ? VenueColors.text
                          : Colors.white,
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: _openAllDonations,
            style: OutlinedButton.styleFrom(
              foregroundColor: VenueColors.forest,
              side: const BorderSide(color: VenueColors.forest, width: 1.5),
              minimumSize: const Size.fromHeight(46),
            ),
            child: const Text('Lihat semua donasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _confirmDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: VenueColors.tomato,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _edit,
                style: FilledButton.styleFrom(
                  backgroundColor: VenueColors.forest,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit venue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                color: VenueColors.forest,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: VenueColors.text, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 4D: konfirmasi hapus. Tombol "Ya, hapus" nonaktif bila masih ada donasi aktif.
class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.venueName, required this.activeDonations});

  final String venueName;
  final int activeDonations;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: VenueColors.sunshine,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              size: 34,
              color: VenueColors.forest,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hapus venue ini?',
            style: TextStyle(
              color: VenueColors.forest,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '“$venueName” akan hilang dari peta dan daftar venue.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: VenueColors.text),
          ),
          if (activeDonations > 0) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: VenueColors.sunshine,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Ada $activeDonations donasi aktif di venue ini. '
                'Pindahkan lokasinya dulu.',
                style: const TextStyle(
                  color: VenueColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: VenueColors.forest,
                    side: const BorderSide(
                      color: VenueColors.forest,
                      width: 1.5,
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: activeDonations > 0
                      ? null
                      : () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: VenueColors.tomato,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Ya, hapus'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
