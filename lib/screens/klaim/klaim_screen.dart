/// Halaman Klaim dan Reservasi
library;

import 'package:flutter/material.dart';

import 'claim_service.dart';
import 'klaim.dart';

class KlaimScreen extends StatefulWidget {
  const KlaimScreen({super.key});

  @override
  State<KlaimScreen> createState() => _KlaimScreenState();
}

class _KlaimScreenState extends State<KlaimScreen> {
  static const _filters = <(String, String)>[
    ('', 'Semua'),
    ('pending', 'Menunggu'),
    ('picked_up', 'Sudah diambil'),
    ('cancelled', 'Dibatalkan'),
    ('expired', 'Kedaluwarsa'),
  ];

  final ClaimService _service = ClaimService();
  late Future<PagedResult<Claim>> _claims;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _claims = _load();
  }

  Future<PagedResult<Claim>> _load() => _service.fetchClaims(status: _status);

  Future<void> _refresh() async {
    setState(() => _claims = _load());
    try {
      await _claims;
    } catch (_) {
      // Kesalahan ditampilkan oleh FutureBuilder.
    }
  }

  void _selectStatus(String value) {
    setState(() {
      _status = value;
      _claims = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klaim dan Reservasi'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final (value, label) in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _status == value,
                      onSelected: (_) => _selectStatus(value),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<PagedResult<Claim>>(
              future: _claims,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _ClaimError(error: snapshot.error, onRetry: _refresh);
                }

                final page = snapshot.data!;
                if (page.items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 140), _EmptyClaims()],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: page.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _ClaimCard(claim: page.items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({required this.claim});

  final Claim claim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickup = claim.pickupTime;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Detail klaim akan segera tersedia.')),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      claim.foodName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(status: claim.status, label: claim.statusLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text('${claim.portions} porsi · ${claim.donorName}'),
              if (pickup != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Waktu ambil ${_formatDateTime(pickup)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (claim.status == 'pending' && claim.pickupCode.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Kode ambil: ${claim.pickupCode}',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.label});

  final String status;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (status) {
      'picked_up' => scheme.primary,
      'pending' => scheme.tertiary,
      _ => scheme.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _EmptyClaims extends StatelessWidget {
  const _EmptyClaims();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64),
          SizedBox(height: 16),
          Text('Belum ada klaim.'),
          SizedBox(height: 8),
          Text(
            'Klaim makanan dari halaman Donasi, lalu pantau di sini.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ClaimError extends StatelessWidget {
  const _ClaimError({required this.error, required this.onRetry});

  final Object? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final needsLogin =
        error is ClaimApiException &&
        (error as ClaimApiException).isAuthProblem;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              needsLogin ? Icons.lock_outline : Icons.cloud_off_outlined,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              needsLogin
                  ? 'Masuk dulu untuk melihat klaim.'
                  : 'Klaim belum dapat dimuat.',
            ),
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
