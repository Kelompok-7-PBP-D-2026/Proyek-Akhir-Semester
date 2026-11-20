/// Halaman daftar makanan surplus untuk modul Donasi Makanan (Rindu).
library;

import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import 'donation.dart';
import 'donation_service.dart';

class DonasiScreen extends StatefulWidget {
  const DonasiScreen({super.key});

  @override
  State<DonasiScreen> createState() => _DonasiScreenState();
}

class _DonasiScreenState extends State<DonasiScreen> {
  final DonationService _service = DonationService();
  late Future<DonationPage> _donations;

  @override
  void initState() {
    super.initState();
    _donations = _service.fetchDonations();
  }

  Future<void> _refresh() async {
    setState(() => _donations = _service.fetchDonations());
    await _donations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Makanan tersedia'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<DonationPage>(
        future: _donations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _RequestError(onRetry: _refresh, error: snapshot.error);
          }

          final page = snapshot.data!;
          if (page.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 180), _EmptyDonations()],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: page.items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    '${page.totalCount} makanan dapat diselamatkan hari ini',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return _DonationCard(donation: page.items[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photo = donation.photoUrl;
    final resolvedPhoto = photo == null || photo.isEmpty
        ? null
        : Uri.parse(ApiConfig.activeUrl).resolve(photo).toString();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detail ${donation.name} akan segera tersedia.'),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DonationImage(photoUrl: resolvedPhoto),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            donation.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(
                          label: donation.statusLabel,
                          isAvailable: donation.status == 'tersedia',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(
                      icon: Icons.restaurant_outlined,
                      text: '${donation.portionCount} porsi tersisa',
                    ),
                    const SizedBox(height: 4),
                    _InfoLine(
                      icon: Icons.place_outlined,
                      text: donation.location,
                    ),
                    const SizedBox(height: 4),
                    _InfoLine(
                      icon: Icons.schedule_outlined,
                      text:
                          'Ambil sebelum ${_formatDateTime(donation.pickupEndsAt)}',
                    ),
                    if (donation.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        donation.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonationImage extends StatelessWidget {
  const _DonationImage({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 76,
      height: 76,
      color: Theme.of(context).colorScheme.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.restaurant,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    );
    if (photoUrl == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        photoUrl!,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.isAvailable});

  final String label;
  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = isAvailable ? colorScheme.primary : colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _EmptyDonations extends StatelessWidget {
  const _EmptyDonations();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 64),
          SizedBox(height: 16),
          Text('Belum ada makanan tersedia.'),
          SizedBox(height: 8),
          Text(
            'Tarik layar ke bawah untuk memeriksa donasi terbaru.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RequestError extends StatelessWidget {
  const _RequestError({required this.onRetry, required this.error});

  final Future<void> Function() onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Donasi belum dapat dimuat.'),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final date =
      '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  return '$date, $time';
}
