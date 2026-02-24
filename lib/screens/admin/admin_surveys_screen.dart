import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../labo/donnees_laboratoire_home.dart';
import '../terrain/matrice1_home.dart';
import 'widgets/admin_role_guard.dart';
import '../../services/firestore_db.dart';
import '../../services/export_service.dart';
import '../../utils/csv_columns.dart';

class AdminSurveysScreen extends StatefulWidget {
  const AdminSurveysScreen({super.key});

  @override
  State<AdminSurveysScreen> createState() => _AdminSurveysScreenState();
}

class _AdminSurveysScreenState extends State<AdminSurveysScreen> {
  final FirebaseFirestore _db = FirestoreDb.db;
  final ExportService _exportService = ExportService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _loading = true;
  List<_SurveyItem> _allItems = [];
  List<_SurveyItem> _filteredItems = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedType = 'Tous';
  bool _isExporting = false;
  int _exportLoaded = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snapshots = await Future.wait([
        _db
            .collection('terrain_forms')
            .orderBy('updatedAt', descending: true)
            .limit(50)
            .get(),
        _db
            .collection('lab_forms')
            .orderBy('updatedAt', descending: true)
            .limit(50)
            .get(),
      ]);

      final rawItems = <_SurveyItem>[
        ...snapshots[0].docs.map((d) => _fromDoc('Terrain', d)),
        ...snapshots[1].docs.map((d) => _fromDoc('Labo', d)),
      ];

      final ownerIds = rawItems
          .map((e) => e.ownerId)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final ownerNameMap = <String, String>{};
      await Future.wait(
        ownerIds.map((uid) async {
          final userDoc = await _db.collection('users').doc(uid).get();
          final name = (userDoc.data()?['fullName']?.toString() ?? '').trim();
          ownerNameMap[uid] = name.isEmpty ? uid : name;
        }),
      );

      final merged =
          rawItems
              .map(
                (e) =>
                    e.copyWith(ownerName: ownerNameMap[e.ownerId] ?? e.ownerId),
              )
              .toList()
            ..sort((a, b) {
              final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return bd.compareTo(ad);
            });

      if (!mounted) return;
      setState(() {
        _allItems = merged;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement des enquetes')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final locationQuery = _locationController.text.trim().toLowerCase();
    final filtered = _allItems.where((item) {
      if (_selectedType != 'Tous' && item.type != _selectedType) {
        return false;
      }
      if (_startDate != null) {
        final candidate = item.surveyDate ?? item.updatedAt;
        if (candidate == null || candidate.isBefore(_startDate!)) return false;
      }
      if (_endDate != null) {
        final candidate = item.surveyDate ?? item.updatedAt;
        if (candidate == null ||
            candidate.isAfter(_endDate!.add(const Duration(days: 1)))) {
          return false;
        }
      }
      if (locationQuery.isNotEmpty &&
          !item.location.toLowerCase().contains(locationQuery)) {
        return false;
      }
      if (query.isNotEmpty) {
        final inText =
            item.title.toLowerCase().contains(query) ||
            item.ownerName.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query);
        if (!inText) return false;
      }
      return true;
    }).toList();

    _filteredItems = filtered;
  }

  _SurveyItem _fromDoc(
    String type,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final root = doc.data();
    final mapData = _toMap(root['data']);
    final title = _readString(root, mapData, const ['title', 'name']);
    final location = _readString(root, mapData, const [
      'location',
      'place',
      'emplacement',
      'zone',
    ]);
    final surveyDate = _readDate(root, mapData, const [
      'gen_date',
      'dateEnquete',
      'dateReception',
      'date',
    ]);
    final createdAt = _asDate(root['createdAt']);
    final updatedAt = _asDate(root['updatedAt']) ?? createdAt;
    final status = (root['status']?.toString() ?? 'brouillon').trim();
    final ownerId = (root['ownerId']?.toString() ?? '').trim();
    final idObservation =
        (mapData['gen_idObservation'] ?? mapData['idObservation'] ?? '')
            .toString();

    return _SurveyItem(
      id: doc.id,
      type: type,
      title: title.isEmpty ? '$type - ${doc.id.substring(0, 6)}' : title,
      location: location,
      surveyDate: surveyDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      ownerId: ownerId,
      ownerName: ownerId,
      idObservation: idObservation,
      data: mapData,
    );
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  String _readString(
    Map<String, dynamic> root,
    Map<String, dynamic> nested,
    List<String> keys,
  ) {
    for (final key in keys) {
      final top = root[key]?.toString().trim() ?? '';
      if (top.isNotEmpty) return top;
      final child = nested[key]?.toString().trim() ?? '';
      if (child.isNotEmpty) return child;
    }
    return '';
  }

  DateTime? _readDate(
    Map<String, dynamic> root,
    Map<String, dynamic> nested,
    List<String> keys,
  ) {
    for (final key in keys) {
      final top = _asDate(root[key]);
      if (top != null) return top;
      final child = _asDate(nested[key]);
      if (child != null) return child;
    }
    return null;
  }

  DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final direct = DateTime.tryParse(value);
      if (direct != null) return direct;
      final parts = value.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) return DateTime(y, m, d);
      }
    }
    return null;
  }

  String _fmt(DateTime? value) {
    if (value == null) return 'N/A';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
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

  Future<void> _deleteItem(_SurveyItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette enquete ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final col = item.type == 'Terrain' ? 'terrain_forms' : 'lab_forms';
    await _db.collection(col).doc(item.id).delete();
    if (!mounted) return;
    await _load();
  }

  void _openHub(_SurveyItem item) {
    if (item.type == 'Terrain') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => Matrice1Home(formId: item.id)),
      );
      return;
    }
    if (item.type == 'Labo') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DonneesLaboratoireHome(formId: item.id),
        ),
      );
    }
  }

  Color _badgeColor(String type) {
    switch (type) {
      case 'Terrain':
        return const Color(0xFF00B8B8);
      case 'Labo':
        return const Color(0xFF1E3A8A);
      default:
        return const Color(0xFF0E7490);
    }
  }

  Future<void> _exportItems({
    required List<_SurveyItem> items,
    required bool asPdf,
    required bool isAll,
  }) async {
    if (items.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final terrain = items.where((e) => e.type == 'Terrain').toList();
      final labo = items.where((e) => e.type == 'Labo').toList();
      final tStamp = _exportService.fileStampNow();
      var firstSaved;
      if (terrain.isNotEmpty) {
        final docs = terrain
            .map(
              (e) => {
                'title': e.title,
                'ownerName': e.ownerName,
                'status': e.status,
                'createdAt': e.createdAt,
                'updatedAt': e.updatedAt,
                'lastEditedAt': e.updatedAt,
                'submittedAt': e.status == 'soumis' ? e.updatedAt : null,
                'data': e.data,
              },
            )
            .toList();
        final saved = asPdf
            ? await _exportService.saveBytesToDevice(
                fileName:
                    'terrain_forms_${isAll ? 'ALL' : 'filtered'}_$tStamp.pdf',
                bytes: await _exportService.buildPdfFromDocs(
                  title: 'Export Terrain (Admin)',
                  docs: docs,
                  dataKeys: terrainDataKeys,
                ),
              )
            : await _exportService.saveCsvToDevice(
                fileName:
                    'terrain_forms_${isAll ? 'ALL' : 'filtered'}_$tStamp.csv',
                csvContent: _exportService.buildCsvFromDocs(
                  docs: docs,
                  dataKeys: terrainDataKeys,
                ),
              );
        firstSaved ??= saved;
      }
      if (labo.isNotEmpty) {
        final docs = labo
            .map(
              (e) => {
                'title': e.title,
                'ownerName': e.ownerName,
                'status': e.status,
                'createdAt': e.createdAt,
                'updatedAt': e.updatedAt,
                'lastEditedAt': e.updatedAt,
                'submittedAt': e.status == 'soumis' ? e.updatedAt : null,
                'data': e.data,
              },
            )
            .toList();
        final saved = asPdf
            ? await _exportService.saveBytesToDevice(
                fileName: 'lab_forms_${isAll ? 'ALL' : 'filtered'}_$tStamp.pdf',
                bytes: await _exportService.buildPdfFromDocs(
                  title: 'Export Laboratoire (Admin)',
                  docs: docs,
                  dataKeys: labDataKeys,
                ),
              )
            : await _exportService.saveCsvToDevice(
                fileName: 'lab_forms_${isAll ? 'ALL' : 'filtered'}_$tStamp.csv',
                csvContent: _exportService.buildCsvFromDocs(
                  docs: docs,
                  dataKeys: labDataKeys,
                ),
              );
        firstSaved ??= saved;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firstSaved?.savedLocation == 'Fichiers > Cercle Bleu'
                ? '✅ Enregistre dans Fichiers'
                : '✅ Enregistre dans Telechargements',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Export impossible: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportLoaded = 0;
        });
      }
    }
  }

  Future<void> _showExportOptions() async {
    if (_isExporting || _filteredItems.isEmpty) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Exporter en CSV'),
              onTap: () => Navigator.pop(context, 'filtered_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Exporter en PDF'),
              onTap: () => Navigator.pop(context, 'filtered_pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: const Text('Exporter tout (CSV)'),
              onTap: () => Navigator.pop(context, 'all_csv'),
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline),
              title: const Text('Exporter tout (PDF)'),
              onTap: () => Navigator.pop(context, 'all_pdf'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'filtered_csv' || choice == 'filtered_pdf') {
      await _exportItems(
        items: _filteredItems
            .where((e) => e.type == 'Terrain' || e.type == 'Labo')
            .toList(),
        asPdf: choice == 'filtered_pdf',
        isAll: false,
      );
      return;
    }
    setState(() {
      _isExporting = true;
      _exportLoaded = 0;
    });
    try {
      final allTerrain = await _exportService.fetchAllDocuments(
        collection: 'terrain_forms',
        onProgress: (count) {
          if (!mounted) return;
          setState(() => _exportLoaded = count);
        },
      );
      final allLabo = await _exportService.fetchAllDocuments(
        collection: 'lab_forms',
        onProgress: (count) {
          if (!mounted) return;
          setState(() => _exportLoaded = allTerrain.length + count);
        },
      );
      var allItems = <_SurveyItem>[
        ...allTerrain.map((d) => _fromDoc('Terrain', d)),
        ...allLabo.map((d) => _fromDoc('Labo', d)),
      ];
      final ownerIds = allItems
          .map((e) => e.ownerId)
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      final ownerNameMap = <String, String>{};
      await Future.wait(
        ownerIds.map((uid) async {
          final userDoc = await _db.collection('users').doc(uid).get();
          final name = (userDoc.data()?['fullName']?.toString() ?? '').trim();
          ownerNameMap[uid] = name.isEmpty ? uid : name;
        }),
      );
      allItems = allItems
          .map(
            (e) => e.copyWith(ownerName: ownerNameMap[e.ownerId] ?? e.ownerId),
          )
          .toList();
      if (!mounted) return;
      setState(() => _isExporting = false);
      await _exportItems(
        items: allItems,
        asPdf: choice == 'all_pdf',
        isAll: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportLoaded = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Export impossible: $e')));
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
                          'Gestion des enquetes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
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
                                              '${_filteredItems.length} resultats',
                                              style: const TextStyle(
                                                color: Color(0xFF1E3A8A),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          FilledButton.icon(
                                            onPressed:
                                                _filteredItems.isEmpty ||
                                                    _isExporting
                                                ? null
                                                : _showExportOptions,
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
                                            label: Text(
                                              _exportLoaded > 0
                                                  ? 'Export... $_exportLoaded'
                                                  : 'Exporter',
                                            ),
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
                                              'Recherche (titre/chercheur/lieu)',
                                          prefixIcon: Icon(
                                            Icons.search_rounded,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _locationController,
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
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedType,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'Tous',
                                            child: Text('Tous'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Terrain',
                                            child: Text('Terrain'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'Labo',
                                            child: Text('Labo'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedType = value ?? 'Tous';
                                            _applyFilters();
                                          });
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Type',
                                          prefixIcon: Icon(
                                            Icons.filter_alt_outlined,
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
                                                    ? 'Date debut'
                                                    : _fmt(
                                                        _startDate,
                                                      ).split(' ').first,
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
                                                    ? 'Date fin'
                                                    : _fmt(
                                                        _endDate,
                                                      ).split(' ').first,
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
                                              _locationController.clear();
                                              _selectedType = 'Tous';
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
                                      : _filteredItems.isEmpty
                                      ? const Center(
                                          child: Text('Aucune enquete trouvee'),
                                        )
                                      : ListView.builder(
                                          itemCount: _filteredItems.length,
                                          itemBuilder: (context, index) {
                                            final item = _filteredItems[index];
                                            final badgeColor = _badgeColor(
                                              item.type,
                                            );
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 10,
                                              ),
                                              child: InkWell(
                                                onTap: () => _openHub(item),
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
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: badgeColor
                                                                  .withOpacity(
                                                                    0.12,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    999,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              item.type,
                                                              style: TextStyle(
                                                                color:
                                                                    badgeColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                            ),
                                                          ),
                                                          const Spacer(),
                                                          IconButton(
                                                            onPressed: () =>
                                                                _deleteItem(
                                                                  item,
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .delete_outline_rounded,
                                                              color: Colors
                                                                  .redAccent,
                                                            ),
                                                            tooltip:
                                                                'Supprimer',
                                                          ),
                                                        ],
                                                      ),
                                                      Text(
                                                        item.title,
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
                                                        'Chercheur: ${item.ownerName}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Lieu: ${item.location.isEmpty ? 'N/A' : item.location}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Date: ${_fmt(item.surveyDate)}',
                                                      ),
                                                      Text(
                                                        'Statut: ${item.status}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      Text(
                                                        'Mis a jour: ${_fmt(item.updatedAt)}',
                                                      ),
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

class _SurveyItem {
  final String id;
  final String type;
  final String title;
  final String location;
  final DateTime? surveyDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String status;
  final String ownerId;
  final String ownerName;
  final String idObservation;
  final Map<String, dynamic> data;

  _SurveyItem({
    required this.id,
    required this.type,
    required this.title,
    required this.location,
    required this.surveyDate,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.ownerId,
    required this.ownerName,
    required this.idObservation,
    required this.data,
  });

  _SurveyItem copyWith({String? ownerName}) {
    return _SurveyItem(
      id: id,
      type: type,
      title: title,
      location: location,
      surveyDate: surveyDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      status: status,
      ownerId: ownerId,
      ownerName: ownerName ?? this.ownerName,
      idObservation: idObservation,
      data: data,
    );
  }
}
