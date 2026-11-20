/// Form tambah dan edit venue (Figma 4C).
///
/// Pencarian alamat memakai Nominatim (OpenStreetMap). Titik pengambilan dipilih
/// dengan menggeser peta: pin tetap di tengah dan koordinat mengikuti. Isian
/// "Gedung" disimpan di field `alamat` pada web service.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' show MapController;
import 'package:latlong2/latlong.dart';

import 'venue.dart';
import 'venue_geo.dart';
import 'venue_map.dart';
import 'venue_service.dart';
import 'venue_widgets.dart';

class VenueFormScreen extends StatefulWidget {
  const VenueFormScreen({super.key, this.venue, this.service});

  /// Null = tambah venue baru; terisi = edit venue ini.
  final Venue? venue;
  final VenueService? service;

  @override
  State<VenueFormScreen> createState() => _VenueFormScreenState();
}

class _VenueFormScreenState extends State<VenueFormScreen> {
  late final VenueService _service = widget.service ?? VenueService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _gedungController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  final TextEditingController _aksesController = TextEditingController();
  final MapController _mapController = MapController();

  String? _fakultas;
  Timer? _debounce;
  int _searchToken = 0;
  bool _searching = false;
  String? _searchMessage;
  List<AddressResult> _results = const [];
  bool _saving = false;

  bool get _isEdit => widget.venue != null;

  @override
  void initState() {
    super.initState();
    final venue = widget.venue;
    if (venue != null) {
      _namaController.text = venue.nama;
      _gedungController.text = venue.alamat;
      _latController.text = venue.latitude.toStringAsFixed(6);
      _lngController.text = venue.longitude.toStringAsFixed(6);
      _aksesController.text = venue.deskripsiAkses;
      _fakultas = kVenueUnitLabels.containsKey(venue.fakultas)
          ? venue.fakultas
          : null;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _namaController.dispose();
    _gedungController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _aksesController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.length < 3) {
      _searchToken++;
      setState(() {
        _results = const [];
        _searchMessage = null;
        _searching = false;
      });
      return;
    }
    // Nominatim membatasi 1 permintaan per detik, jadi pencarian ditunda.
    _debounce = Timer(
      const Duration(milliseconds: 600),
      () => _runSearch(query),
    );
  }

  Future<void> _runSearch(String query) async {
    final token = ++_searchToken;
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final results = await _service.searchAddress(query);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = results;
        _searching = false;
        _searchMessage = results.isEmpty
            ? 'Alamat tidak ditemukan. Coba kata kunci lain atau isi koordinat manual.'
            : 'Hasil dari OpenStreetMap.';
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = const [];
        _searching = false;
        _searchMessage =
            'Pencarian OpenStreetMap gagal. Isi koordinat secara manual.';
      });
    }
  }

  void _selectResult(AddressResult result) {
    setState(() {
      _latController.text = result.latitude.toStringAsFixed(6);
      _lngController.text = result.longitude.toStringAsFixed(6);
      if (_namaController.text.trim().isEmpty) {
        _namaController.text = result.title;
      }
      if (_gedungController.text.trim().isEmpty) {
        _gedungController.text = result.title;
      }
      _searchController.text = result.title;
      _results = const [];
      _searchMessage = null;
    });
    _mapController.move(LatLng(result.latitude, result.longitude), 17);
    FocusScope.of(context).unfocus();
  }

  /// Koordinat diketik manual: pindahkan peta bila keduanya valid.
  void _onCoordinateTyped() {
    final lat = parseCoordinate(_latController.text);
    final lng = parseCoordinate(_lngController.text);
    if (lat != null &&
        lng != null &&
        isValidLatitude(lat) &&
        isValidLongitude(lng)) {
      _mapController.move(LatLng(lat, lng), 17);
    }
  }

  /// Peta digeser pengguna: isi koordinat dari titik tengah peta.
  void _onMapMoved(double latitude, double longitude) {
    _latController.text = latitude.toStringAsFixed(6);
    _lngController.text = longitude.toStringAsFixed(6);
  }

  String? _requiredText(String? value, String message, {int max = 0}) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return message;
    if (max > 0 && text.length > max) return 'Maksimal $max karakter.';
    return null;
  }

  String? _validateCoordinate(String? value, {required bool latitude}) {
    final label = latitude ? 'Latitude' : 'Longitude';
    final parsed = parseCoordinate(value ?? '');
    if (parsed == null) return '$label wajib diisi (angka).';
    final valid = latitude ? isValidLatitude(parsed) : isValidLongitude(parsed);
    if (!valid) {
      return latitude
          ? 'Latitude harus antara -90 dan 90.'
          : 'Longitude harus antara -180 dan 180.';
    }
    return null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final lat = parseCoordinate(_latController.text);
    final lng = parseCoordinate(_lngController.text);
    final fakultas = _fakultas;
    if (lat == null || lng == null || fakultas == null) return;

    final input = VenueInput(
      nama: _namaController.text.trim(),
      fakultas: fakultas,
      latitude: lat,
      longitude: lng,
      alamat: _gedungController.text.trim(),
      deskripsiAkses: _aksesController.text.trim(),
    );

    setState(() => _saving = true);
    try {
      final existing = widget.venue;
      final saved = existing == null
          ? await _service.createVenue(input)
          : await _service.updateVenue(existing.id, input);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      showVenueSnackBar(context, describeVenueError(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final venue = widget.venue;
    return Scaffold(
      backgroundColor: VenueColors.page,
      appBar: AppBar(
        backgroundColor: VenueColors.page,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEdit ? 'Edit venue' : 'Tambah venue'),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: VenueColors.forest,
                  side: const BorderSide(color: VenueColors.forest, width: 1.5),
                  minimumSize: const Size(96, 50),
                ),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: VenueColors.carrot,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan venue'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            VenueHeading(
              eyebrow: 'Venue',
              title: _isEdit ? 'Edit venue' : 'Tambah venue',
            ),
            const SizedBox(height: 6),
            const Text(
              'Cari alamat lewat OpenStreetMap, koordinat terisi otomatis.',
              style: TextStyle(color: VenueColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            VenueSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAddressSearch(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _namaController,
                    decoration: venueInputDecoration(label: 'Nama venue'),
                    validator: (value) => _requiredText(
                      value,
                      'Nama venue wajib diisi.',
                      max: 120,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _fakultas,
                          isExpanded: true,
                          decoration: venueInputDecoration(label: 'Fakultas'),
                          items: [
                            for (final entry in kVenueUnitLabels.entries)
                              DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(
                                  entry.value,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _fakultas = value),
                          validator: (value) =>
                              value == null ? 'Pilih fakultas.' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _gedungController,
                          decoration: venueInputDecoration(
                            label: 'Gedung',
                            hint: 'Gedung A, lt. 1',
                          ),
                          validator: (value) {
                            if ((value ?? '').trim().length > 255) {
                              return 'Maksimal 255 karakter.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: (_) => _onCoordinateTyped(),
                          decoration: venueInputDecoration(label: 'Latitude'),
                          validator: (value) =>
                              _validateCoordinate(value, latitude: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          onChanged: (_) => _onCoordinateTyped(),
                          decoration: venueInputDecoration(label: 'Longitude'),
                          validator: (value) =>
                              _validateCoordinate(value, latitude: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  VenuePickerMap(
                    controller: _mapController,
                    initialLatitude: venue?.latitude ?? kCampusLat,
                    initialLongitude: venue?.longitude ?? kCampusLng,
                    onMoved: _onMapMoved,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Geser peta untuk menyesuaikan titik pengambilan.',
                    style: TextStyle(color: VenueColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _aksesController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: venueInputDecoration(label: 'Petunjuk akses'),
                    validator: (value) {
                      if ((value ?? '').trim().length > 300) {
                        return 'Maksimal 300 karakter.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: venueInputDecoration(
            label: 'Cari alamat',
            hint: 'Contoh: Gedung A Fasilkom',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
        ),
        if (_searchMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _searchMessage!,
              style: const TextStyle(color: VenueColors.muted, fontSize: 12),
            ),
          ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: VenueColors.cream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VenueColors.border),
            ),
            child: Column(
              children: [
                for (final result in _results)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: VenueColors.forest,
                    ),
                    title: Text(
                      result.title,
                      style: const TextStyle(
                        color: VenueColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(result.subtitle),
                    onTap: () => _selectResult(result),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
