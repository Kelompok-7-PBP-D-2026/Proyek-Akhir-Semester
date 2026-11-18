// Smoke test: aplikasi jalan dan navigasi bawah menampilkan 5 modul.
//
// Tes ini tidak melakukan koneksi jaringan — halaman yang diuji menampilkan
// state loading/error dari FutureBuilder secara lokal.
import 'package:flutter_test/flutter_test.dart';

import 'package:mbg_mobile/main.dart';

void main() {
  testWidgets('Bottom navigation menampilkan 5 tab modul',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MbgMobileApp());
    await tester.pump();

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Donasi'), findsOneWidget);
    expect(find.text('Klaim'), findsOneWidget);
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Laporan'), findsOneWidget);

    // Pindah tab Donasi dan pastikan AppBar halamannya muncul.
    await tester.tap(find.text('Donasi'));
    await tester.pumpAndSettle();
    expect(find.text('Donasi Makanan'), findsOneWidget);
  });
}
