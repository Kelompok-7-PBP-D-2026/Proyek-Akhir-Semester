/// Data Donasi yang diterima dari endpoint Django REST Framework.
class Donation {
  const Donation({
    required this.id,
    required this.name,
    required this.portionCount,
    required this.location,
    required this.availableAt,
    required this.pickupEndsAt,
    required this.status,
    required this.statusLabel,
    this.note = '',
    this.photoUrl,
  });

  final int id;
  final String name;
  final int portionCount;
  final String location;
  final DateTime availableAt;
  final DateTime pickupEndsAt;
  final String status;
  final String statusLabel;
  final String note;
  final String? photoUrl;

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as int,
      name: json['nama']?.toString() ?? 'Donasi tanpa nama',
      portionCount: (json['jumlah_porsi'] as num?)?.toInt() ?? 0,
      location: json['lokasi']?.toString() ?? 'Lokasi belum tersedia',
      availableAt:
          DateTime.tryParse(json['waktu_tersedia']?.toString() ?? '') ??
          DateTime.now(),
      pickupEndsAt:
          DateTime.tryParse(
            json['waktu_akhir_pengambilan']?.toString() ?? '',
          ) ??
          DateTime.now(),
      status: json['status']?.toString() ?? '',
      statusLabel: json['status_tampilan']?.toString() ?? 'Tidak diketahui',
      note: json['catatan']?.toString() ?? '',
      photoUrl: json['foto_url']?.toString(),
    );
  }
}
