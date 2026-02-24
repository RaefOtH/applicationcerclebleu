import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/csv_export_service.dart';
import 'researcher_details_screen.dart';
import 'widgets/admin_role_guard.dart';
import '../../services/firestore_db.dart';

class AdminResearchersScreen extends StatefulWidget {
  const AdminResearchersScreen({super.key});

  @override
  State<AdminResearchersScreen> createState() => _AdminResearchersScreenState();
}

class _AdminResearchersScreenState extends State<AdminResearchersScreen> {
  final FirebaseFirestore _db = FirestoreDb.db;
  final CsvExportService _csvService = CsvExportService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();

  bool _loading = true;
  List<_ResearcherSummary> _all = [];
  List<_ResearcherSummary> _filtered = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final usersSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'chercheur')
          .get();

      final summaries = await Future.wait(
        usersSnap.docs.map((doc) async {
          final data = doc.data();
          final user = AppUser.fromMap(doc.id, data);

          final terrainCountFuture = _db
              .collection('terrain_forms')
              .where('ownerId', isEqualTo: doc.id)
              .count()
              .get();
          final labCountFuture = _db
              .collection('lab_forms')
              .where('ownerId', isEqualTo: doc.id)
              .count()
              .get();

          final placesFuture = _loadPlacesForResearcher(doc.id);

          final counts = await Future.wait([
            terrainCountFuture,
            labCountFuture,
          ]);
          final places = await placesFuture;

          return _ResearcherSummary(
            user: user,
            phone: (data['phone']?.toString() ?? '').trim(),
            createdAt: _asDate(data['createdAt']),
            lastLoginAt: _asDate(data['lastLoginAt']),
            terrainCount: counts[0].count ?? 0,
            labCount: counts[1].count ?? 0,
            places: places,
          );
        }),
      );

      if (!mounted) return;
      setState(() {
        _all = summaries;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement des chercheurs')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Set<String>> _loadPlacesForResearcher(String uid) async {
    final snaps = await Future.wait([
      _db
          .collection('terrain_forms')
          .where('ownerId', isEqualTo: uid)
          .limit(20)
          .get(),
      _db
          .collection('lab_forms')
          .where('ownerId', isEqualTo: uid)
          .limit(20)
          .get(),
    ]);
    final places = <String>{};
    for (final snap in snaps) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final nested = _toMap(data['data']);
        for (final key in const ['location', 'place', 'emplacement', 'zone']) {
          final candidate = (data[key] ?? nested[key] ?? '').toString().trim();
          if (candidate.isNotEmpty) places.add(candidate);
        }
      }
    }
    return places;
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  DateTime? _asDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final placeQuery = _placeController.text.trim().toLowerCase();
    final filtered = _all.where((summary) {
      if (query.isNotEmpty) {
        final inText =
            summary.user.fullName.toLowerCase().contains(query) ||
            summary.user.email.toLowerCase().contains(query);
        if (!inText) return false;
      }
      if (placeQuery.isNotEmpty) {
        final hasPlace = summary.places.any(
          (p) => p.toLowerCase().contains(placeQuery),
        );
        if (!hasPlace) return false;
      }
      if (_startDate != null) {
        final created = summary.createdAt;
        if (created == null || created.isBefore(_startDate!)) return false;
      }
      if (_endDate != null) {
        final created = summary.createdAt;
        if (created == null ||
            created.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      return true;
    }).toList();

    _filtered = filtered;
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      _applyFilters();
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _applyFilters();
    });
  }

  String _fmtDate(DateTime? value) {
    if (value == null) return 'N/A';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  Widget _chip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $count'),
    );
  }

  Future<void> _exportFilteredResearchers() async {
    if (_filtered.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final headers = <String>[
        'uid',
        'fullName',
        'email',
        'phone',
        'createdAt',
        'lastLoginAt',
        'terrainCount',
        'labCount',
        'places',
      ];
      final rows = _filtered.map((r) {
        return <String>[
          r.user.uid,
          r.user.fullName,
          r.user.email,
          r.phone,
          _csvService.formatDateTimeForCsv(r.createdAt),
          _csvService.formatDateTimeForCsv(r.lastLoginAt),
          r.terrainCount.toString(),
          r.labCount.toString(),
          r.places.join(' | '),
        ];
      }).toList();
      final csv = _csvService.buildCsvContent(headers: headers, rows: rows);
      final fileName = 'chercheurs_${_csvService.fileStampNow()}.csv';
      final saved = await _csvService.saveCsvToDevice(fileName, csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? '✅ Fichier enregistre dans Fichiers'
                : '✅ Fichier enregistre dans Telechargements',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Export impossible: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminRoleGuard(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2D4BA8),
                    Color(0xFF1E3A8A),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Cercle Bleu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 56),
                        child: Text(
                          'Gestion des chercheurs',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: RefreshIndicator(
                          onRefresh: _load,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF1E3A8A,
                                      ).withOpacity(0.08),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${_filtered.length} resultats',
                                              style: const TextStyle(
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed:
                                                _filtered.isEmpty ||
                                                    _isExporting
                                                ? null
                                                : _exportFilteredResearchers,
                                            icon: _isExporting
                                                ? const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .file_download_outlined,
                                                  ),
                                            label: const Text('Exporter CSV'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF1E3A8A,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _searchController,
                                        onChanged: (_) =>
                                            setState(_applyFilters),
                                        decoration: const InputDecoration(
                                          labelText:
                                              'Recherche par nom ou email',
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _placeController,
                                        onChanged: (_) =>
                                            setState(_applyFilters),
                                        decoration: const InputDecoration(
                                          labelText: 'Filtre emplacement',
                                          prefixIcon: Icon(
                                            Icons.place_outlined,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _pickStart,
                                              icon: const Icon(
                                                Icons.date_range_rounded,
                                              ),
                                              label: Text(
                                                _startDate == null
                                                    ? 'Cree apres'
                                                    : _fmtDate(_startDate),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _pickEnd,
                                              icon: const Icon(
                                                Icons.event_rounded,
                                              ),
                                              label: Text(
                                                _endDate == null
                                                    ? 'Cree avant'
                                                    : _fmtDate(_endDate),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _placeController.clear();
                                              _startDate = null;
                                              _endDate = null;
                                              _applyFilters();
                                            });
                                          },
                                          child: const Text('Reinitialiser'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: _loading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : _filtered.isEmpty
                                      ? const Center(
                                          child: Text('Aucun chercheur trouve'),
                                        )
                                      : ListView.builder(
                                          itemCount: _filtered.length,
                                          itemBuilder: (context, index) {
                                            final summary = _filtered[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ResearcherDetailsScreen(
                                                            researcherId:
                                                                summary
                                                                    .user
                                                                    .uid,
                                                          ),
                                                    ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF1E3A8A,
                                                      ).withOpacity(0.08),
                                                      width: 1.2,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        summary
                                                                .user
                                                                .fullName
                                                                .isEmpty
                                                            ? 'Utilisateur'
                                                            : summary
                                                                  .user
                                                                  .fullName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF1E3A8A,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        summary.user.email,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Telephone: ${summary.phone.isEmpty ? 'N/A' : summary.phone}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Cree le: ${_fmtDate(summary.createdAt)}',
                                                      ),
                                                      Text(
                                                        'Derniere connexion: ${_fmtDate(summary.lastLoginAt)}',
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 8,
                                                        children: [
                                                          _chip(
                                                            'Terrain',
                                                            summary
                                                                .terrainCount,
                                                          ),
                                                          _chip(
                                                            'Labo',
                                                            summary.labCount,
                                                          ),
                                                        ],
                                                      ),
                                                      if (summary
                                                          .places
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 8,
                                                        ),
                                                        Wrap(
                                                          spacing: 6,
                                                          runSpacing: 6,
                                                          children: summary
                                                              .places
                                                              .take(4)
                                                              .map(
                                                                (p) => Chip(
                                                                  label: Text(
                                                                    p,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  visualDensity:
                                                                      VisualDensity
                                                                          .compact,
                                                                ),
                                                              )
                                                              .toList(),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResearcherSummary {
  final AppUser user;
  final String phone;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final int terrainCount;
  final int labCount;
  final Set<String> places;

  _ResearcherSummary({
    required this.user,
    required this.phone,
    required this.createdAt,
    required this.lastLoginAt,
    required this.terrainCount,
    required this.labCount,
    required this.places,
  });
}
