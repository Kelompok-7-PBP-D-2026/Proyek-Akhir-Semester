/// Halaman daftar generik untuk semua modul.
///
/// Anggota tidak perlu menulis ulang logika fetch/Loading/Error/Empty:
/// berikan [title], [endpoint], dan [buildItem] — halaman menampilkan
/// daftar hasil fetch dari web service Django (PWS).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.buildItem,
    this.emptyMessage = 'Belum ada data.',
  });

  /// Judul yang tampil di AppBar.
  final String title;

  /// URI endpoint web service Django yang di-fetch.
  final Uri endpoint;

  /// Builder satu item dari JSON map hasil fetch.
  final Widget Function(BuildContext context, Map<String, dynamic> item)
      buildItem;

  /// Pesan ketika respons berisi daftar kosong.
  final String emptyMessage;

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchItems();
  }

  Future<void> _refresh() async {
    setState(() => _future = _fetchItems());
  }

  Future<List<dynamic>> _fetchItems() async {
    final response = await http.get(widget.endpoint);
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is List) return body;
      if (body is Map<String, dynamic> && body['results'] is List) {
        return body['results'] as List;
      }
      return [];
    }
    throw Exception('Gagal memuat data (HTTP ${response.statusCode}).');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}'),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _refresh, child: const Text('Coba lagi')),
                  ],
                ),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(widget.emptyMessage),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  widget.buildItem(context, items[index] as Map<String, dynamic>),
            ),
          );
        },
      ),
    );
  }
}
