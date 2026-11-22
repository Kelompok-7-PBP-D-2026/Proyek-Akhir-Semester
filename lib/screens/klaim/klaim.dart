library;

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

int _asInt(Object? value) => (value as num?)?.toInt() ?? 0;

/// Koordinat venue; jarak dihitung di perangkat.
class VenuePoint {
  const VenuePoint({required this.lat, required this.lng});

  final double lat;
  final double lng;

  static VenuePoint? fromJsonOrNull(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return VenuePoint(lat: lat, lng: lng);
  }
}

class TimelineStep {
  const TimelineStep({
    required this.label,
    required this.caption,
    required this.state,
  });

  final String label;
  final String caption;

  /// done, pending, or failed.
  final String state;

  factory TimelineStep.fromJson(Map<String, dynamic> json) {
    return TimelineStep(
      label: json['label']?.toString() ?? '',
      caption: json['caption']?.toString() ?? '',
      state: json['state']?.toString() ?? 'pending',
    );
  }
}

class Claim {
  const Claim({
    required this.id,
    required this.donationId,
    required this.foodName,
    required this.donorName,
    required this.pickupLocation,
    required this.portions,
    required this.status,
    required this.statusLabel,
    required this.canCancel,
    this.pickupTime,
    this.expiresAt,
    this.note = '',
    this.pickupCode = '',
    this.createdAt,
    this.pickedUpAt,
    this.timeline = const [],
    this.location,
  });

  final int id;
  final int donationId;
  final String foodName;
  final String donorName;
  final String pickupLocation;
  final int portions;
  final DateTime? pickupTime;
  final DateTime? expiresAt;
  final String note;
  final String pickupCode;

  /// pending, picked_up, cancelled, atau expired.
  final String status;
  final String statusLabel;
  final bool canCancel;
  final DateTime? createdAt;
  final DateTime? pickedUpAt;

  /// Hanya terisi pada endpoint detail.
  final List<TimelineStep> timeline;
  final VenuePoint? location;

  factory Claim.fromJson(Map<String, dynamic> json) {
    final rawTimeline = json['timeline'];
    return Claim(
      id: _asInt(json['id']),
      donationId: _asInt(json['donation_id']),
      foodName: json['food_name']?.toString() ?? 'Klaim',
      donorName: json['donor_name']?.toString() ?? '',
      pickupLocation: json['pickup_location']?.toString() ?? '',
      portions: _asInt(json['portions']),
      pickupTime: _parseDate(json['pickup_time']),
      expiresAt: _parseDate(json['expires_at']),
      note: json['note']?.toString() ?? '',
      pickupCode: json['pickup_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['display_status_label']?.toString() ?? '',
      canCancel: json['can_cancel'] == true,
      createdAt: _parseDate(json['created_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      timeline: rawTimeline is List
          ? rawTimeline
                .whereType<Map<String, dynamic>>()
                .map(TimelineStep.fromJson)
                .toList()
          : const [],
      location: VenuePoint.fromJsonOrNull(json['location']),
    );
  }
}

class IncomingClaim {
  const IncomingClaim({
    required this.id,
    required this.foodName,
    required this.portions,
    required this.recipientName,
    required this.recipientLabel,
    required this.status,
    required this.statusLabel,
    required this.canVerify,
    this.pickupTime,
    this.expiresAt,
    this.note = '',
  });

  final int id;
  final String foodName;
  final int portions;
  final DateTime? pickupTime;
  final DateTime? expiresAt;
  final String note;
  final String recipientName;

  final String recipientLabel;
  final String status;
  final String statusLabel;
  final bool canVerify;

  factory IncomingClaim.fromJson(Map<String, dynamic> json) {
    return IncomingClaim(
      id: _asInt(json['id']),
      foodName: json['food_name']?.toString() ?? '',
      portions: _asInt(json['portions']),
      pickupTime: _parseDate(json['pickup_time']),
      expiresAt: _parseDate(json['expires_at']),
      note: json['note']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString() ?? '',
      recipientLabel: json['recipient_label']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusLabel: json['display_status_label']?.toString() ?? '',
      canVerify: json['can_verify'] == true,
    );
  }
}

/// Satu pilihan slot waktu ambil pada form klaim.
class ClaimSlot {
  const ClaimSlot({required this.value, required this.label});

  /// Nilai ISO yang dikirim kembali ke server.
  final String value;

  /// Teks untuk pengguna, misalnya "30 Okt 2026, 15.00".
  final String label;

  factory ClaimSlot.fromJson(Map<String, dynamic> json) {
    return ClaimSlot(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

/// Data untuk form klaim: stok, batas, slot, atau alasan klaim ditolak.
class ClaimFormInfo {
  const ClaimFormInfo({
    required this.canClaim,
    required this.donationId,
    required this.foodName,
    required this.donorName,
    required this.pickupLocation,
    required this.availablePortions,
    required this.maxPortions,
    required this.noteMaxLength,
    required this.graceMinutes,
    this.blocker,
    this.pickupDeadline,
    this.slots = const [],
    this.location,
  });

  final bool canClaim;

  final String? blocker;
  final int donationId;
  final String foodName;
  final String donorName;
  final String pickupLocation;
  final int availablePortions;
  final DateTime? pickupDeadline;
  final int maxPortions;
  final int noteMaxLength;
  final int graceMinutes;
  final List<ClaimSlot> slots;
  final VenuePoint? location;

  factory ClaimFormInfo.fromJson(Map<String, dynamic> json) {
    final donation = json['donation'] is Map<String, dynamic>
        ? json['donation'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rawSlots = json['slots'];
    return ClaimFormInfo(
      canClaim: json['can_claim'] == true,
      blocker: json['blocker']?.toString(),
      donationId: _asInt(donation['id']),
      foodName: donation['food_name']?.toString() ?? '',
      donorName: donation['donor_name']?.toString() ?? '',
      pickupLocation: donation['pickup_location']?.toString() ?? '',
      availablePortions: _asInt(donation['available_portions']),
      pickupDeadline: _parseDate(donation['pickup_deadline']),
      maxPortions: _asInt(json['max_portions']),
      noteMaxLength: _asInt(json['note_max_length']),
      graceMinutes: _asInt(json['grace_minutes']),
      slots: rawSlots is List
          ? rawSlots
                .whereType<Map<String, dynamic>>()
                .map(ClaimSlot.fromJson)
                .toList()
          : const [],
      location: VenuePoint.fromJsonOrNull(json['location']),
    );
  }
}

/// Tiga angka ringkasan di halaman Klaim Masuk (donor).
class ClaimStats {
  const ClaimStats({
    required this.waiting,
    required this.pickedUp,
    required this.notPicked,
  });

  final int waiting;
  final int pickedUp;
  final int notPicked;

  factory ClaimStats.fromJson(Map<String, dynamic> json) {
    return ClaimStats(
      waiting: _asInt(json['waiting']),
      pickedUp: _asInt(json['picked_up']),
      notPicked: _asInt(json['not_picked']),
    );
  }
}
