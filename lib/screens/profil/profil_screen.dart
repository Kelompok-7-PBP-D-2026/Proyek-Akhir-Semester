/// Halaman Profil Pengguna (Fikri).
/// Starter: daftar donor dari API. Kembangkan menjadi profil sendiri +
/// detail donor sesuai spek modul.
library;

import 'package:flutter/material.dart';

import '../module_list_screen.dart';
import '../../config/api_config.dart';

class ProfilScreen extends StatelessWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModuleListScreen(
      title: 'Profil Pengguna',
      endpoint: ApiConfig.profilDonor,
      emptyMessage: 'Belum ada donor terdaftar.',
      buildItem: (context, item) => Card(
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(item['user']?.toString() ?? 'Donor'),
          subtitle: Text(item['jenis_donor']?.toString() ?? ''),
        ),
      ),
    );
  }
}
