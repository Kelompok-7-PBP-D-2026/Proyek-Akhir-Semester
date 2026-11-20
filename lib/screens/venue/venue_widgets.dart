/// Palet warna dan komponen kecil modul Venue (mengikuti Figma Modul 4).
library;

import 'package:flutter/material.dart';

class VenueColors {
  static const Color forest = Color(0xFF19532B);
  static const Color sunshine = Color(0xFFFFCA26);
  static const Color cream = Color(0xFFF3E8CC);
  static const Color carrot = Color(0xFFF86015);
  static const Color kiwi = Color(0xFF9ABC04);
  static const Color tomato = Color(0xFFD42518);
  static const Color page = Color(0xFFFBF6E8);
  static const Color border = Color(0xFFE4D8B6);
  static const Color text = Color(0xFF0F2E19);
  static const Color muted = Color(0xFF4A5D4F);
}

/// Judul halaman: label kecil oranye + judul besar hijau.
class VenueHeading extends StatelessWidget {
  const VenueHeading({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            color: VenueColors.carrot,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: VenueColors.forest,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

/// Badge fakultas pada kartu venue (contoh: "Fasilkom").
class VenueBadge extends StatelessWidget {
  const VenueBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: VenueColors.cream,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VenueColors.forest, width: 1.2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: VenueColors.forest,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Pil kecil (contoh: "Aktif", "0,8 km", "Tersedia").
class VenuePill extends StatelessWidget {
  const VenuePill({
    super.key,
    required this.label,
    this.background = VenueColors.cream,
    this.foreground = VenueColors.forest,
    this.showDot = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: VenueColors.forest.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu putih dengan garis tepi krem.
class VenueSectionCard extends StatelessWidget {
  const VenueSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VenueColors.border),
      ),
      child: child,
    );
  }
}

InputDecoration venueInputDecoration({
  String? label,
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1.5]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(VenueColors.border),
    enabledBorder: border(VenueColors.border),
    focusedBorder: border(VenueColors.forest, 2),
    errorBorder: border(VenueColors.tomato),
    focusedErrorBorder: border(VenueColors.tomato, 2),
  );
}

void showVenueSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
