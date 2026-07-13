import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'firestore_db.dart';

enum StatsRange { today, days7, days30, all, custom }

class StatsFilters {
  final StatsRange range;
  final DateTimeRange? customRange;
  final String? selectedOwnerId;
  final String? selectedPlace;
  final String? selectedLab;

  const StatsFilters({
    required this.range,
    this.customRange,
    this.selectedOwnerId,
    this.selectedPlace,
    this.selectedLab,
  });
}

class DashboardStatsResult {
  final int totalTerrain;
  final int totalLabo;
  final int totalLek; // Résout l'erreur affichée sur image_cea32d.png
  final int totalPortsUniques;
  final int totalCrabes;
  final List<StatsEntry> topPorts;
  final List<StatsEntry> topEspeces;
  final List<StatsEntry> topRegionsLek;
  final List<OwnerEntry> ownerOptions;
  final List<String> placeOptions;
  final List<String> labOptions;

  const DashboardStatsResult({
    required this.totalTerrain,
    required this.totalLabo,
    required this.totalLek,
    required this.totalPortsUniques,
    required this.totalCrabes,
    required this.topPorts,
    required this.topEspeces,
    required this.topRegionsLek,
    required this.ownerOptions,
    required this.placeOptions,
    required this.labOptions,
  });
}

class OwnerEntry {
  final String id;
  final String name;

  const OwnerEntry({
    required this.id,
    required this.name,
  });
}

class StatsEntry {
  final String label;
  final int value;

  const StatsEntry({
    required this.label,
    required this.value,
  });
}

class StatsService {
  final FirebaseFirestore _db = FirestoreDb.db;

  Future<DashboardStatsResult> fetchDashboardStats({
    required bool isAdmin,
    required String? uid,
    required StatsFilters filters,
  }) async {
    Query<Map<String, dynamic>> terrainQuery = _db.collection('terrain_forms');
    Query<Map<String, dynamic>> laboQuery = _db.collection('lab_forms');
    Query<Map<String, dynamic>> lekQuery = _db.collection('lek_forms');

    if (!isAdmin && (uid ?? '').trim().isNotEmpty) {
      final safeUid = uid!.trim();
      terrainQuery = terrainQuery.where('ownerId', isEqualTo: safeUid);
      laboQuery = laboQuery.where('ownerId', isEqualTo: safeUid);
      lekQuery = lekQuery.where('ownerId', isEqualTo: safeUid);
    } else if (isAdmin && (filters.selectedOwnerId ?? '').trim().isNotEmpty) {
      final selectedOwner = filters.selectedOwnerId!.trim();
      terrainQuery = terrainQuery.where('ownerId', isEqualTo: selectedOwner);
      laboQuery = laboQuery.where('ownerId', isEqualTo: selectedOwner);
      lekQuery = lekQuery.where('ownerId', isEqualTo: selectedOwner);
    }

    final results = await Future.wait([
      terrainQuery.get(),
      laboQuery.get(),
      lekQuery.get(),
    ]);

    final terrainDocs = results[0].docs;
    final laboDocs = results[1].docs;
    final lekDocs = results[2].docs;

    final filteredTerrain = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final filteredLabo = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final filteredLek = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final ownerOptions = <String, String>{};
    final placeSet = <String>{};
    final labSet = <String>{};

    // --- 1. PARCOURS TERRAIN ---
    for (final doc in terrainDocs) {
      final root = doc.data();
      final ownerId = (root['ownerId'] ?? '').toString().trim();
      final ownerName = (root['ownerName'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        ownerOptions[ownerId] = ownerName.isEmpty ? ownerId : ownerName;
      }
      final data = _toMap(root['data']);
      final port = (data['gen_portPeche'] ?? '').toString().trim();
      final zone = (data['gen_zone'] ?? '').toString().trim();
      if (port.isNotEmpty) placeSet.add(port);
      if (zone.isNotEmpty) placeSet.add(zone);

      if (!_isInRange(root, filters)) continue;
      if (!_matchPlaceFilter(data, filters.selectedPlace)) continue;
      filteredTerrain.add(doc);
    }

    // --- 2. PARCOURS LABO ---
    for (final doc in laboDocs) {
      final root = doc.data();
      final ownerId = (root['ownerId'] ?? '').toString().trim();
      final ownerName = (root['ownerName'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        ownerOptions[ownerId] = ownerName.isEmpty ? ownerId : ownerName;
      }
      final data = _toMap(root['data']);
      final lab = (data['idLaboratoire'] ?? '').toString().trim();
      if (lab.isNotEmpty) labSet.add(lab);

      if (!_isInRange(root, filters)) continue;
      if (!_matchLabFilter(data, filters.selectedLab)) continue;
      filteredLabo.add(doc);
    }

    // --- 3. PARCOURS LEK ---
    final regionLekTotals = <String, int>{};
    for (final doc in lekDocs) {
      final root = doc.data();
      final ownerId = (root['ownerId'] ?? '').toString().trim();
      final ownerName = (root['ownerName'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        ownerOptions[ownerId] = ownerName.isEmpty ? ownerId : ownerName;
      }
      final data = _toMap(root['data']);
      
      // Extraction basée sur csv_columns.dart (clés de l'enquête LEK)
      final port = (data['portPeche'] ?? '').toString().trim();
      final zone = (data['Zone'] ?? '').toString().trim();
      if (port.isNotEmpty) placeSet.add(port);
      if (zone.isNotEmpty) placeSet.add(zone);

      if (!_isInRange(root, filters)) continue;
      if (!_matchLekPlaceFilter(data, filters.selectedPlace)) continue;
      filteredLek.add(doc);

      final region = (data['region'] ?? '').toString().trim();
      if (region.isNotEmpty) {
        regionLekTotals[region] = (regionLekTotals[region] ?? 0) + 1;
      }
    }

    // --- CALCULS STATISTIQUES FINAUX ---
    final uniquePorts = <String>{};
    final portTotals = <String, int>{};
    final speciesTotals = <String, int>{};
    var totalCrabes = 0;

    for (final doc in filteredTerrain) {
      final root = doc.data();
      final data = _toMap(root['data']);
      final port = (data['gen_portPeche'] ?? '').toString().trim();
      if (port.isNotEmpty) {
        uniquePorts.add(port);
      }

      final abundance = _parseCount(data['cap_abondance']);
      totalCrabes += abundance;

      if (port.isNotEmpty && abundance > 0) {
        portTotals[port] = (portTotals[port] ?? 0) + abundance;
      }
      final species = (data['cap_espece'] ?? '').toString().trim();
      if (species.isNotEmpty && abundance > 0) {
        speciesTotals[species] = (speciesTotals[species] ?? 0) + abundance;
      }
    }

    final owners = ownerOptions.entries
        .map((e) => OwnerEntry(id: e.key, name: e.value))
        .toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final places = placeSet.toList(growable: false)..sort();
    final labs = labSet.toList(growable: false)..sort();

    return DashboardStatsResult(
      totalTerrain: filteredTerrain.length,
      totalLabo: filteredLabo.length,
      totalLek: filteredLek.length,
      totalPortsUniques: uniquePorts.length,
      totalCrabes: totalCrabes,
      topPorts: _toTopEntries(portTotals),
      topEspeces: _toTopEntries(speciesTotals),
      topRegionsLek: _toTopEntries(regionLekTotals),
      ownerOptions: owners,
      placeOptions: places,
      labOptions: labs,
    );
  }

  bool _isInRange(Map<String, dynamic> root, StatsFilters filters) {
    final range = filters.range;
    if (range == StatsRange.all) return true;

    final updatedAt = root['updatedAt'];
    final createdAt = root['createdAt'];
    DateTime? d;
    if (updatedAt is Timestamp) d = updatedAt.toDate();
    if (d == null && createdAt is Timestamp) d = createdAt.toDate();
    if (d == null) return false;

    if (range == StatsRange.custom) {
      final custom = filters.customRange;
      if (custom == null) return true;
      final start = DateTime(custom.start.year, custom.start.month, custom.start.day);
      final end = DateTime(
        custom.end.year,
        custom.end.month,
        custom.end.day,
        23,
        59,
        59,
      );
      return !d.isBefore(start) && !d.isAfter(end);
    }

    final now = DateTime.now();
    DateTime start;
    switch (range) {
      case StatsRange.today:
        start = DateTime(now.year, now.month, now.day);
        break;
      case StatsRange.days7:
        start = now.subtract(const Duration(days: 7));
        break;
      case StatsRange.days30:
        start = now.subtract(const Duration(days: 30));
        break;
      case StatsRange.all:
      case StatsRange.custom:
        return true;
    }
    return !d.isBefore(start);
  }

  bool _matchPlaceFilter(Map<String, dynamic> data, String? selectedPlace) {
    final place = (selectedPlace ?? '').trim();
    if (place.isEmpty || place == 'Tous') return true;
    final port = (data['gen_portPeche'] ?? '').toString().trim().toLowerCase();
    final zone = (data['gen_zone'] ?? '').toString().trim().toLowerCase();
    final wanted = place.toLowerCase();
    return port == wanted || zone == wanted;
  }

  bool _matchLekPlaceFilter(Map<String, dynamic> data, String? selectedPlace) {
    final place = (selectedPlace ?? '').trim();
    if (place.isEmpty || place == 'Tous') return true;
    final port = (data['portPeche'] ?? '').toString().trim().toLowerCase();
    final zone = (data['Zone'] ?? '').toString().trim().toLowerCase();
    final wanted = place.toLowerCase();
    return port == wanted || zone == wanted;
  }

  bool _matchLabFilter(Map<String, dynamic> data, String? selectedLab) {
    final lab = (selectedLab ?? '').trim();
    if (lab.isEmpty || lab == 'Tous') return true;
    final idLab = (data['idLaboratoire'] ?? '').toString().trim().toLowerCase();
    return idLab == lab.toLowerCase();
  }

  int _parseCount(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    final s = value.toString().trim();
    if (s.isEmpty) return 0;
    final normalized = s.replaceAll(',', '.');
    final n = double.tryParse(normalized);
    if (n == null) return 0;
    return n.round();
  }

  Map<String, dynamic> _toMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<StatsEntry> _toTopEntries(Map<String, int> source) {
    final entries = source.entries
        .map((e) => StatsEntry(label: e.key, value: e.value))
        .toList(growable: false);
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList(growable: false);
  }
}