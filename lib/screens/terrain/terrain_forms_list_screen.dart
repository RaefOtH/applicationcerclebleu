import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/export_service.dart';
import '../../services/terrain_form_service.dart';
import '../../utils/csv_columns.dart';
import '../../widgets/forms_filter_bar.dart';
import 'matrice1_home.dart';

class TerrainFormsListScreen extends StatefulWidget {
  const TerrainFormsListScreen({super.key});

  @override
  State<TerrainFormsListScreen> createState() => _TerrainFormsListScreenState();
}

class _TerrainFormsListScreenState extends State<TerrainFormsListScreen>
    with SingleTickerProviderStateMixin {
  final TerrainFormService _service = TerrainFormService();
  final ExportService _exportService = ExportService();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _waveController;

  Timer? _searchDebounce;
  String _searchTerm = '';
  String _status = 'Tous';
  String _selectedPlace = 'Tous';
  DateTimeRange? _range;
  bool _isExporting = false;
  int _exportLoaded = 0;
  bool _showFilters = false;
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _searchTerm = value.trim().toLowerCase());
    });
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  DateTime? _docDate(Map<String, dynamic> root) {
    final updated = root['updatedAt'];
    final created = root['createdAt'];
    if (updated is Timestamp) return updated.toDate();
    if (created is Timestamp) return created.toDate();
    return null;
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.where((doc) {
      final root = doc.data();
      final data = _toMap(root['data']);
      final title = (root['title'] ?? '').toString().toLowerCase();
      final idObs = (data['gen_idObservation'] ?? '').toString().toLowerCase();
      final status = (root['status'] ?? '').toString().toLowerCase();
      final port = (data['gen_portPeche'] ?? '').toString();
      final zone = (data['gen_zone'] ?? '').toString();
      final place = '$port $zone'.trim().toLowerCase();

      if (_searchTerm.isNotEmpty &&
          !title.contains(_searchTerm) &&
          !idObs.contains(_searchTerm)) {
        return false;
      }
      if (_status != 'Tous' && status != _status) return false;
      if (_selectedPlace != 'Tous') {
        final selected = _selectedPlace.toLowerCase();
        if (!port.toLowerCase().contains(selected) &&
            !zone.toLowerCase().contains(selected) &&
            !place.contains(selected)) {
          return false;
        }
      }
      if (_range != null) {
        final date = _docDate(root);
        if (date == null) return false;
        final start = DateTime(
          _range!.start.year,
          _range!.start.month,
          _range!.start.day,
        );
        final end = DateTime(
          _range!.end.year,
          _range!.end.month,
          _range!.end.day,
          23,
          59,
          59,
        );
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }
      return true;
    }).toList();
  }

  List<String> _buildPlaceOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final places = <String>{'Tous'};
    for (final doc in docs) {
      final data = _toMap(doc.data()['data']);
      final port = (data['gen_portPeche'] ?? '').toString().trim();
      final zone = (data['gen_zone'] ?? '').toString().trim();
      if (port.isNotEmpty) places.add(port);
      if (zone.isNotEmpty) places.add(zone);
    }
    return places.toList()..sort();
  }

  String _fmtDate(dynamic ts) {
    if (ts is! Timestamp) return 'N/A';
    final d = ts.toDate();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'soumis':
      case 'soumise':
        return const Color(0xFF00D9D9);
      case 'brouillon':
        return const Color(0xFF1E3A8A);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _confirmDelete(String formId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce formulaire ?'),
        content: const Text('Cette action est definitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.deleteForm(formId);
    }
  }

  Future<void> _exportDocs({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required bool asPdf,
    required bool isAll,
  }) async {
    if (docs.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final stamp = _exportService.fileStampNow();
      final base = isAll ? 'terrain_forms_ALL_$stamp' : 'terrain_forms_filtered_$stamp';
      final roots = docs.map((d) => d.data()).toList(growable: false);
      final saved = asPdf
          ? await _exportService.saveBytesToDevice(
              fileName: '$base.pdf',
              bytes: await _exportService.buildPdfFromDocs(
                title: 'Formulaires Terrain',
                docs: roots,
                dataKeys: terrainDataKeys,
              ),
            )
          : await _exportService.saveCsvToDevice(
              fileName: '$base.csv',
              csvContent: _exportService.buildCsvFromDocs(
                docs: roots,
                dataKeys: terrainDataKeys,
              ),
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? '✅ Enregistre dans Fichiers'
                : '✅ Enregistre dans Telechargements',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur Firestore: ${e.code} ${e.message ?? ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Export impossible: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _exportLoaded = 0;
        });
      }
    }
  }

  Future<void> _showExportOptions({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> filtered,
  }) async {
    if (_isExporting) return;
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
    if (choice == 'filtered_csv') {
      await _exportDocs(docs: filtered, asPdf: false, isAll: false);
      return;
    }
    if (choice == 'filtered_pdf') {
      await _exportDocs(docs: filtered, asPdf: true, isAll: false);
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Utilisateur non connecte')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportLoaded = 0;
    });
    try {
      final allDocs = await _exportService.fetchAllDocuments(
        collection: 'terrain_forms',
        ownerId: uid,
        onProgress: (count) {
          if (!mounted) return;
          setState(() => _exportLoaded = count);
        },
      );
      if (!mounted) return;
      setState(() => _isExporting = false);
      await _exportDocs(docs: allDocs, asPdf: choice == 'all_pdf', isAll: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExporting = false;
        _exportLoaded = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Export impossible: $e')),
      );
    }
  }

  String get _dateLabel {
    if (_range == null) return 'Periode: Du - Au';
    final s =
        '${_range!.start.day.toString().padLeft(2, '0')}/${_range!.start.month.toString().padLeft(2, '0')}';
    final e =
        '${_range!.end.day.toString().padLeft(2, '0')}/${_range!.end.month.toString().padLeft(2, '0')}';
    return 'Periode: $s - $e';
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchTerm = '';
      _status = 'Tous';
      _selectedPlace = 'Tous';
      _range = null;
      _visibleCount = 20;
    });
  }

  Future<void> _exportSingleDoc({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool asPdf,
  }) async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final root = doc.data();
      final stamp = _exportService.fileStampNow();
      final fileName = asPdf
          ? 'terrain_form_$stamp.pdf'
          : 'terrain_form_$stamp.csv';
      final saved = asPdf
          ? await _exportService.saveBytesToDevice(
              fileName: fileName,
              bytes: await _exportService.buildPdfFromDocs(
                title: 'Formulaire Terrain',
                docs: [root],
                dataKeys: terrainDataKeys,
              ),
            )
          : await _exportService.saveCsvToDevice(
              fileName: fileName,
              csvContent: _exportService.buildCsvFromDocs(
                docs: [root],
                dataKeys: terrainDataKeys,
              ),
            );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? '✅ Enregistré dans Fichiers'
                : '✅ Enregistré dans Téléchargements',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Export impossible: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  String _titleForDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final root = doc.data();
    final title = (root['title'] ?? '').toString().trim();
    if (title.isNotEmpty) return title;
    return 'Formulaire ${doc.id.substring(0, 6)}';
  }

  Widget _activeChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 210,
            child: Container(
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
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) => CustomPaint(
                  painter: WavePainter(
                    animation: _waveController.value,
                    color: const Color(0xFF00D9D9).withOpacity(0.12),
                    waveHeight: 16,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Formulaires terrain recents',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _service.watchMyForms(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Erreur Firestore: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () => setState(() {}),
                                  child: const Text('Reessayer'),
                                ),
                              ],
                            ),
                          );
                        }
                        final docs = snapshot.data?.docs ?? const [];
                        final filtered = _applyFilters(docs);
                        final visible = filtered.take(_visibleCount).toList(growable: false);
                        final places = _buildPlaceOptions(docs);
                        if (!places.contains(_selectedPlace)) {
                          _selectedPlace = 'Tous';
                        }

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D9D9).withOpacity(0.06),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/image/logo.png',
                                    height: 92,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Formulaires recents - Terrain',
                                          style: TextStyle(
                                            color: Color(0xFF1E3A8A),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${filtered.length} resultats',
                                          style: const TextStyle(
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: filtered.isEmpty || _isExporting
                                        ? null
                                        : () => _showExportOptions(filtered: filtered),
                                    icon: _isExporting
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.file_download_outlined),
                                    label: Text(
                                      _exportLoaded > 0 ? 'Export... $_exportLoaded' : 'Exporter',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search_rounded),
                                    hintText: 'Rechercher titre / id observation...',
                                    suffixIcon: _searchController.text.isEmpty
                                        ? null
                                        : IconButton(
                                            onPressed: () {
                                              _searchController.clear();
                                              _onSearchChanged('');
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.close_rounded),
                                          ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => setState(() => _showFilters = !_showFilters),
                                    icon: Icon(
                                      _showFilters
                                          ? Icons.tune_rounded
                                          : Icons.filter_list_rounded,
                                    ),
                                    label: const Text('Filtres'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_status != 'Tous')
                                    _activeChip('Statut: $_status'),
                                  if (_selectedPlace != 'Tous')
                                    _activeChip('Lieu: $_selectedPlace'),
                                  if (_range != null)
                                    _activeChip('Période active'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 180),
                                crossFadeState: _showFilters
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                                firstChild: FormsFilterBar(
                                  searchController: _searchController,
                                  onSearchChanged: _onSearchChanged,
                                  searchHint: 'Rechercher titre / id observation...',
                                  showSearch: false,
                                  statusValue: _status,
                                  onStatusChanged: (v) => setState(() => _status = v ?? 'Tous'),
                                  dateLabel: _dateLabel,
                                  onPickDateRange: _pickRange,
                                  showPlaceFilter: true,
                                  placeValue: _selectedPlace,
                                  placeOptions: places,
                                  onPlaceChanged: (v) => setState(() => _selectedPlace = v ?? 'Tous'),
                                  resultCount: filtered.length,
                                  onReset: _resetFilters,
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: filtered.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade500),
                                            const SizedBox(height: 8),
                                            const Text('Aucun formulaire trouve'),
                                            const SizedBox(height: 8),
                                            OutlinedButton(
                                              onPressed: _resetFilters,
                                              child: const Text('Reinitialiser'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: visible.length + (filtered.length > visible.length ? 1 : 0),
                                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                                        itemBuilder: (context, index) {
                                          if (index >= visible.length) {
                                            return Center(
                                              child: OutlinedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _visibleCount += 20;
                                                  });
                                                },
                                                child: const Text('Charger plus'),
                                              ),
                                            );
                                          }
                                          final doc = visible[index];
                                          final root = doc.data();
                                          final data = _toMap(root['data']);
                                          final status = (root['status'] ?? 'brouillon').toString().toLowerCase();
                                          final title = _titleForDoc(doc);
                                          final idObs = (data['gen_idObservation'] ?? '').toString();
                                          final place = (data['gen_portPeche'] ?? data['gen_zone'] ?? '').toString();
                                          return Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(18),
                                              border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.03),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      width: 34,
                                                      height: 34,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(10),
                                                      ),
                                                      child: const Icon(
                                                        Icons.map_outlined,
                                                        color: Color(0xFF1E3A8A),
                                                        size: 18,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          color: Color(0xFF1E3A8A),
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: _statusColor(status).withOpacity(0.15),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        status,
                                                        style: TextStyle(
                                                          color: _statusColor(status),
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 6,
                                                  children: [
                                                    if (idObs.isNotEmpty) Text('ID: $idObs'),
                                                    if (place.isNotEmpty) Text('Lieu: $place'),
                                                    Text('Maj: ${_fmtDate(root['updatedAt'])}'),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    OutlinedButton.icon(
                                                      onPressed: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (_) => Matrice1Home(formId: doc.id)),
                                                      ),
                                                      icon: const Icon(Icons.open_in_new),
                                                      label: const Text('Ouvrir'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: () => _exportSingleDoc(
                                                        doc: doc,
                                                        asPdf: false,
                                                      ),
                                                      icon: const Icon(Icons.file_download_outlined),
                                                      label: const Text('CSV'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: () => _exportSingleDoc(
                                                        doc: doc,
                                                        asPdf: true,
                                                      ),
                                                      icon: const Icon(Icons.picture_as_pdf_outlined),
                                                      label: const Text('PDF'),
                                                    ),
                                                    OutlinedButton.icon(
                                                      onPressed: () => _confirmDelete(doc.id),
                                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                                      label: const Text('Supprimer'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
