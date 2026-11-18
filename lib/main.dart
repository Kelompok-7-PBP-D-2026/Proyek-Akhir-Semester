/// MBG Mobile — aplikasi Flutter Proyek Akhir Semester Kelompok 7.
///
/// Navigasi utama memakai bottom navigation bar dengan 5 halaman modul.
/// Setiap halaman mengambil data dari web service Django REST Framework
/// di PWS (lihat lib/config/api_config.dart).
library;

import 'package:flutter/material.dart';

import 'screens/donasi/donasi_screen.dart';
import 'screens/klaim/klaim_screen.dart';
import 'screens/laporan/laporan_screen.dart';
import 'screens/profil/profil_screen.dart';
import 'screens/venue/venue_screen.dart';

void main() {
  runApp(const MbgMobileApp());
}

class MbgMobileApp extends StatelessWidget {
  const MbgMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MBG Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

/// Container navigasi utama: 5 tab sesuai daftar modul di README.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  static const List<Widget> _screens = [
    ProfilScreen(),
    DonasiScreen(),
    KlaimScreen(),
    VenueScreen(),
    LaporanScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Donasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Klaim',
          ),
          NavigationDestination(
            icon: Icon(Icons.place_outlined),
            selectedIcon: Icon(Icons.place),
            label: 'Venue',
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: 'Laporan',
          ),
        ],
      ),
    );
  }
}
