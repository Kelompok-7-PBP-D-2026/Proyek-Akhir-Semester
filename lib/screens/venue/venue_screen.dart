/// Halaman Venue dan Lokasi (Marvin).
///
/// Figma 4A: daftar venue dan peta (toggle Peta/Daftar, pencarian, chip fakultas).
/// Figma 4E: keadaan "Venue tidak ditemukan".
/// Detail (4B, 4D) ada di venue_detail_screen.dart, form (4C) di venue_form_screen.dart.
library;

import 'package:flutter/material.dart';

import '../donasi/donation.dart';
import '../donasi/donation_service.dart';
import 'venue.dart';
import 'venue_detail_screen.dart';
import 'venue_donations.dart';
import 'venue_form_screen.dart';
import 'venue_geo.dart';
import 'venue_location.dart';
import 'venue_map.dart';
import 'venue_service.dart';
import 'venue_widgets.dart';

enum _VenueView { peta, daftar }

class _VenueData {
  const _VenueData(this.venues, this.donations);

  final List<Venue> venues;

  /// Null bila data donasi gagal dimuat (jumlah donasi aktif tidak ditampilkan).
  final List<Donation>? donations;
}

class VenueScreen extends StatefulWidget {
  const VenueScreen({super.key});

  @override
  State<VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  final VenueService _service = VenueService();
  final DonationService _donationService = DonationService();
  final TextEditingController _searchController = TextEditingController();

  late Future<_VenueData> _data;
  _VenueView _view = _VenueView.peta;
  String _unit = '';
  String _query = '';
  int? _selectedId;
  UserLocation? _user;

  @override
  void initState() {
    super.initState();
    _data = _load();
    _locate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_VenueData> _load() async {
    final donationsFuture = _loadDonations();
    final venues = await _service.fetchVenues();
    return _VenueData(venues, await donationsFuture);
  }

  Future<List<Donation>?> _loadDonations() async {
    try {
      return (await _donationService.fetchDonations()).items;
    } catch (_) {
      return null;
    }
  }

  Future<void> _locate() async {
    final location = await currentUserLocation();
    if (!mounted) return;
    setState(() => _user = location);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _data = future);
    try {
      await future;
    } catch (_) {
      // Error ditampilkan oleh FutureBuilder.
    }
  }

  Future<void> _addVenue() async {
    final created = await Navigator.of(
      context,
    ).push<Venue>(MaterialPageRoute(builder: (_) => const VenueFormScreen()));
    if (created != null && mounted) await _refresh();
  }

  Future<void> _openDetail(Venue venue, List<Donation>? donations) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            VenueDetailScreen(venue: venue, donations: donations, user: _user),
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  bool _matches(Venue venue) {
    if (_unit.isNotEmpty && venue.fakultas != _unit) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return venue.nama.toLowerCase().contains(q) ||
        venue.alamat.toLowerCase().contains(q) ||
        venue.unitLabel.toLowerCase().contains(q) ||
        venue.unitShort.toLowerCase().contains(q);
  }

  double _distanceKm(Venue venue) {
    final user = _user;
    return haversineKm(
      user?.latitude ?? kCampusLat,
      user?.longitude ?? kCampusLng,
      venue.latitude,
      venue.longitude,
    );
  }

  String get _originLabel =>
      _user != null ? 'dari lokasimu' : 'dari pusat kampus';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VenueColors.page,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addVenue,
        backgroundColor: VenueColors.carrot,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah venue'),
      ),
      body: SafeArea(
        child: FutureBuilder<_VenueData>(
          future: _data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: describeVenueError(snapshot.error!),
                onRetry: _refresh,
              );
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(_VenueData data) {
    final filtered = data.venues.where(_matches).toList();
    final now = DateTime.now();
    final hasFilter = _query.isNotEmpty || _unit.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const VenueHeading(
            eyebrow: 'Venue dan lokasi',
            title: 'Titik pengambilan',
          ),
          const SizedBox(height: 16),
          if (filtered.isNotEmpty) ...[
            SegmentedButton<_VenueView>(
              segments: const [
                ButtonSegment(
                  value: _VenueView.peta,
                  label: Text('Peta'),
                  icon: Icon(Icons.map_outlined),
                ),
                ButtonSegment(
                  value: _VenueView.daftar,
                  label: Text('Daftar'),
                  icon: Icon(Icons.list),
                ),
              ],
              selected: {_view},
              onSelectionChanged: (selection) =>
                  setState(() => _view = selection.first),
            ),
            const SizedBox(height: 12),
            if (_view == _VenueView.peta) ...[
              VenuesMap(
                venues: filtered,
                userLatitude: _user?.latitude,
                userLongitude: _user?.longitude,
                selectedId: _selectedId,
                onSelect: (id) => setState(() => _selectedId = id),
              ),
              const SizedBox(height: 8),
              Text(
                _user != null
                    ? 'Jarak dihitung dari lokasimu lewat OpenStreetMap.'
                    : 'Jarak dihitung dari pusat kampus. Izinkan akses lokasi '
                          'untuk jarak dari posisimu.',
                style: const TextStyle(color: VenueColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ],
          _buildSearchField(),
          const SizedBox(height: 10),
          _buildChips(data.venues),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            _EmptyVenues(hasFilter: hasFilter, onAdd: _addVenue)
          else
            for (final venue in filtered)
              _VenueCard(
                venue: venue,
                selected: venue.id == _selectedId,
                info: _cardInfo(venue, data.donations, now),
                onDetail: () => _openDetail(venue, data.donations),
              ),
        ],
      ),
    );
  }

  String _cardInfo(Venue venue, List<Donation>? donations, DateTime now) {
    final distance = '${formatKm(_distanceKm(venue))} km $_originLabel';
    if (donations == null) return distance;
    return '$distance · ${activeDonationCount(venue, donations, now)} donasi aktif';
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim()),
      textInputAction: TextInputAction.search,
      decoration: venueInputDecoration(
        hint: 'Cari venue atau gedung...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                icon: const Icon(Icons.close),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
      ),
    );
  }

  Widget _buildChips(List<Venue> all) {
    final counts = <String, int>{};
    for (final venue in all) {
      counts[venue.fakultas] = (counts[venue.fakultas] ?? 0) + 1;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip('Semua (${all.length})', _unit.isEmpty, () {
            setState(() => _unit = '');
          }),
          for (final code in kVenueUnitLabels.keys)
            if (counts.containsKey(code)) ...[
              const SizedBox(width: 8),
              _chip(
                '${kVenueUnitShort[code]} (${counts[code]})',
                _unit == code,
                () => setState(() => _unit = code),
              ),
            ],
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: VenueColors.forest,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: VenueColors.forest),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : VenueColors.forest,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  const _VenueCard({
    required this.venue,
    required this.info,
    required this.selected,
    required this.onDetail,
  });

  final Venue venue;
  final String info;
  final bool selected;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? VenueColors.forest : VenueColors.border,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VenueColors.cream,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.place_outlined, color: VenueColors.forest),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        venue.nama,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: VenueColors.forest,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    VenueBadge(label: venue.unitShort),
                  ],
                ),
                Text(
                  venue.unitLabel,
                  style: const TextStyle(
                    color: VenueColors.muted,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        info,
                        style: const TextStyle(
                          color: VenueColors.text,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: onDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: VenueColors.sunshine,
                        foregroundColor: VenueColors.text,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text(
                        'Detail',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 4E: pencarian venue kosong.
class _EmptyVenues extends StatelessWidget {
  const _EmptyVenues({required this.hasFilter, required this.onAdd});

  final bool hasFilter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: const BoxDecoration(
              color: VenueColors.sunshine,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              size: 52,
              color: VenueColors.forest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Venue tidak ditemukan' : 'Belum ada venue',
            style: const TextStyle(
              color: VenueColors.forest,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coba kata kunci lain, atau tambahkan venue baru lewat pencarian alamat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VenueColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(backgroundColor: VenueColors.forest),
            icon: const Icon(Icons.add),
            label: const Text('Tambah venue'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: VenueColors.muted),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
