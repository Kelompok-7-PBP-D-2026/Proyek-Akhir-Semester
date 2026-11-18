/// Halaman Venue dan Lokasi (Marvin).
/// Starter: daftar venue dari API. Kembangkan menjadi detail venue +
/// peta dan jarak sesuai spek modul.
library;

import 'package:flutter/material.dart';

import '../module_list_screen.dart';
import '../../config/api_config.dart';

class VenueScreen extends StatelessWidget {
  const VenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleListScreen(
      title: 'Venue dan Lokasi',
      endpoint: ApiConfig.venue,
      emptyMessage: 'Belum ada venue.',
      buildItem: (context, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.place),
          title: Text(item['nama']?.toString() ?? 'Venue'),
          subtitle: Text(item['fakultas']?.toString() ?? ''),
        ),
      ),
    );
  }
}
