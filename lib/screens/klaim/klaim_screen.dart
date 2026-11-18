/// Halaman Klaim dan Reservasi (Kireina).
/// Starter: daftar klaim dari API (butuh login). Kembangkan menjadi
/// form klaim + pembatalan + verifikasi kode sesuai spek modul.
library;

import 'package:flutter/material.dart';

import '../module_list_screen.dart';
import '../../config/api_config.dart';

class KlaimScreen extends StatelessWidget {
  const KlaimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleListScreen(
      title: 'Klaim dan Reservasi',
      endpoint: ApiConfig.claim,
      emptyMessage: 'Belum ada klaim.',
      buildItem: (context, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.receipt_long),
          title: Text(item['food_name']?.toString() ?? 'Klaim'),
          subtitle: Text(
            '${item['portions']} porsi — kode ${item['pickup_code']}',
          ),
          trailing: Text(item['display_status_label']?.toString() ?? ''),
        ),
      ),
    );
  }
}
