/// Halaman Laporan Dampak (Joshua).
/// Starter: daftar laporan dari API (butuh login). Kembangkan menjadi
/// detail laporan + ekspor sesuai spek modul.
library;

import 'package:flutter/material.dart';

import '../module_list_screen.dart';
import '../../config/api_config.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleListScreen(
      title: 'Laporan Dampak',
      endpoint: ApiConfig.laporan,
      emptyMessage: 'Belum ada laporan.',
      buildItem: (context, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.assessment),
          title: Text(item['periode']?.toString() ?? 'Laporan'),
          subtitle: Text(
            '${item['total_makanan_tersalurkan']} makanan tersalurkan',
          ),
        ),
      ),
    );
  }
}
