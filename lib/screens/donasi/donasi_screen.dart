/// Halaman Donasi Makanan (Rindu).
/// Starter: daftar donasi dari API. Kembangkan menjadi detail donasi +
/// form buat/edit sesuai spek modul.
library;

import 'package:flutter/material.dart';

import '../module_list_screen.dart';
import '../../config/api_config.dart';

class DonasiScreen extends StatelessWidget {
  const DonasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleListScreen(
      title: 'Donasi Makanan',
      endpoint: ApiConfig.donasi,
      emptyMessage: 'Belum ada donasi tersedia.',
      buildItem: (context, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.restaurant),
          title: Text(item['nama']?.toString() ?? 'Donasi'),
          subtitle: Text(
            '${item['jumlah_porsi']} porsi — ${item['lokasi']}',
          ),
          trailing: Text(item['status_tampilan']?.toString() ?? ''),
        ),
      ),
    );
  }
}
