/// Pencocokan donasi ke venue.
///
/// `Donasi.lokasi` di backend masih berupa teks bebas, jadi donasi dicocokkan ke
/// venue lewat nama venue (tanpa membedakan huruf besar/kecil), sama seperti
/// situs web (venue/integrations.py). Ganti fungsi ini bila Donasi nanti
/// memakai relasi ke Venue.
library;

import '../donasi/donation.dart';
import 'venue.dart';

bool donationBelongsToVenue(Donation donation, Venue venue) {
  return donation.location.trim().toLowerCase() ==
      venue.nama.trim().toLowerCase();
}

/// Donasi di venue ini yang masa pengambilannya belum lewat.
List<Donation> openDonationsAt(
  Venue venue,
  Iterable<Donation> donations,
  DateTime now,
) {
  final result = donations
      .where(
        (d) => donationBelongsToVenue(d, venue) && d.pickupEndsAt.isAfter(now),
      )
      .toList();
  result.sort((a, b) => a.pickupEndsAt.compareTo(b.pickupEndsAt));
  return result;
}

/// Donasi aktif = masih ada stok dan belum lewat batas pengambilan.
int activeDonationCount(
  Venue venue,
  Iterable<Donation> donations,
  DateTime now,
) {
  return openDonationsAt(
    venue,
    donations,
    now,
  ).where((d) => d.portionCount > 0).length;
}
