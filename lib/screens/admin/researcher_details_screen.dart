import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../labo/donnees_laboratoire_home.dart';
import '../lek/lek_hub_screen.dart';
import '../terrain/matrice1_home.dart';
import 'widgets/admin_role_guard.dart';

class ResearcherDetailsScreen extends StatefulWidget {
  final String researcherId;

  const ResearcherDetailsScreen({super.key, required this.researcherId});

  @override
  State<ResearcherDetailsScreen> createState() => _ResearcherDetailsScreenState();
}

class _ResearcherDetailsScreenState extends State<ResearcherDetailsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _placeController = TextEditingController();

  bool _loading = true;
  Map<String, dynamic>? _profile;
  List<_ResearcherFormItem> _allForms = [];
  List<_ResearcherFormItem> _filteredForms = [];
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _placeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profileFuture = _db.collection('users').doc(widget.researcherId).get();
      final formsFuture = Future.wait([
        _db
            .collection('terrain_forms')
            .where('ownerId', isEqualTo: widget.researcherId)
            .orderBy('updatedAt', descending: true)
            .limit(30)
            .get(),
        _db
            .collection('lab_forms')
            .where('ownerId', isEqualTo: widget.researcherId)
            .orderBy('updatedAt', descending: true)
            .limit(30)
            .get(),
        _db
            .collection('lek_forms')
            .where('ownerId', isEqualTo: widget.researcherId)
            .orderBy('updatedAt', descending: true)
            .limit(30)
            .get(),
      ]);

      final profileDoc = await profileFuture;
      final snapshots = await formsFuture;

      final merged = <_ResearcherFormItem>[
        ...snapshots[0].docs.map((d) => _fromDoc('Terrain', d)),
        ...snapshots[1].docs.map((d) => _fromDoc('Labo', d)),
        ...snapshots[2].docs.map((d) => _fromDoc('LEK', d)),
      ]..sort((a, b) {
          final ad = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

      if (!mounted) return;
      setState(() {
        _profile = profileDoc.data();
        _allForms = merged;
        _applyFilters();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement des détails')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _ResearcherFormItem _fromDoc(
    String type,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final nested = _toMap(data['data']);
    final location = _readString(data, nested, const [
      'location',
      'place',
      'emplacement',
      'zone',
    ]);
    final date = _readDate(data, nested, const [
      'gen_date',
      'dateEnquete',
      'dateReception',
      'date',
    ]);
    final title = _readString(data, nested, const ['title', 'name']);
    return _ResearcherFormItem(
      id: doc.id,
      type: type,
      title: title.isEmpty ? '$type - ${doc.id.substring(0, 6)}' : title,
      location: location,
      surveyDate: date,
      status: (data['status']?.toString() ?? 'brouillon').trim(),
      updatedAt: _asDate(data['updatedAt']) ?? _asDate(data['createdAt']),
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
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      final direct = DateTime.tryParse(value);
      if (direct != null) return direct;
      final parts = value.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return null;
  }

  void _applyFilters() {
    final placeQuery = _placeController.text.trim().toLowerCase();
    final filtered = _allForms.where((item) {
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
      if (placeQuery.isNotEmpty &&
          !item.location.toLowerCase().contains(placeQuery)) {
        return false;
      }
      return true;
    }).toList();
    _filteredForms = filtered;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
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
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked;
      _applyFilters();
    });
  }

  void _openHub(_ResearcherFormItem item) {
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
        MaterialPageRoute(builder: (_) => DonneesLaboratoireHome(formId: item.id)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LekHubScreen(formId: item.id)),
    );
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

  @override
  Widget build(BuildContext context) {
    final fullName = (_profile?['fullName']?.toString() ?? '').trim();
    final email = (_profile?['email']?.toString() ?? '').trim();
    final phone = (_profile?['phone']?.toString() ?? '').trim();

    return AdminRoleGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Détails chercheur'),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.08),
                    width: 1.2,
                  ),
                ),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? 'Utilisateur' : fullName,
                            style: const TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Email: ${email.isEmpty ? 'N/A' : email}'),
                          Text('Téléphone: ${phone.isEmpty ? 'N/A' : phone}'),
                          Text('UID: ${widget.researcherId}'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _placeController,
                            onChanged: (_) => setState(_applyFilters),
                            decoration: const InputDecoration(
                              labelText: 'Filtre emplacement',
                              prefixIcon: Icon(Icons.place_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickStart,
                                  icon: const Icon(Icons.date_range_rounded),
                                  label: Text(
                                    _startDate == null
                                        ? 'Date début'
                                        : _fmt(_startDate).split(' ').first,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _pickEnd,
                                  icon: const Icon(Icons.event_rounded),
                                  label: Text(
                                    _endDate == null
                                        ? 'Date fin'
                                        : _fmt(_endDate).split(' ').first,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Formulaires récents',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              if (!_loading && _filteredForms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 26),
                  child: Center(child: Text('Aucun formulaire trouvé')),
                )
              else
                ..._filteredForms.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => _openHub(item),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.08),
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.type} - ${item.title}',
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lieu: ${item.location.isEmpty ? 'N/A' : item.location}',
                            ),
                            Text('Date: ${_fmt(item.surveyDate)}'),
                            Text('Statut: ${item.status}'),
                            Text('Mis à jour: ${_fmt(item.updatedAt)}'),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResearcherFormItem {
  final String id;
  final String type;
  final String title;
  final String location;
  final DateTime? surveyDate;
  final String status;
  final DateTime? updatedAt;

  _ResearcherFormItem({
    required this.id,
    required this.type,
    required this.title,
    required this.location,
    required this.surveyDate,
    required this.status,
    required this.updatedAt,
  });
}
