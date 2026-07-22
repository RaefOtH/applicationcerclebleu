import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'firestore_db.dart';

class CsvSaveResult {
  final String fileName;
  final String savedLocation;
  final File? shareableFile;

  const CsvSaveResult({
    required this.fileName,
    required this.savedLocation,
    this.shareableFile,
  });
}

class CsvExportService {
  final FirebaseFirestore _db = FirestoreDb.db;
  static const String _delimiter = ';';
  static const String _filteredDelimiter = ',';

  Future<File> exportTerrainCsv({required bool isAdmin, required String uid}) {
    return _exportCollectionCsv(
      collection: 'terrain_forms',
      type: 'TERRAIN',
      isAdmin: isAdmin,
      uid: uid,
    );
  }

  Future<File> exportLabCsv({required bool isAdmin, required String uid}) {
    return _exportCollectionCsv(
      collection: 'lab_forms',
      type: 'LAB',
      isAdmin: isAdmin,
      uid: uid,
    );
  }

  Future<File> exportLekCsv({required bool isAdmin, required String uid}) {
    return _exportCollectionCsv(
      collection: 'lek_forms',
      type: 'LEK',
      isAdmin: isAdmin,
      uid: uid,
    );
  }

  Future<File> exportAllCsv({
    required bool isAdmin,
    required String uid,
  }) async {
    final bundles = await Future.wait([
      _fetchCollectionDocs(
        collection: 'terrain_forms',
        type: 'TERRAIN',
        isAdmin: isAdmin,
        uid: uid,
      ),
      _fetchCollectionDocs(
        collection: 'lab_forms',
        type: 'LAB',
        isAdmin: isAdmin,
        uid: uid,
      ),
    ]);

    final allRows = <_ExportRow>[...bundles[0], ...bundles[1]];

    if (allRows.isEmpty) {
      throw StateError('Aucune donnee a exporter.');
    }

    return _writeCsvFile(type: 'TOUT', rows: allRows);
  }

  Future<File> _exportCollectionCsv({
    required String collection,
    required String type,
    required bool isAdmin,
    required String uid,
  }) async {
    final rows = await _fetchCollectionDocs(
      collection: collection,
      type: type,
      isAdmin: isAdmin,
      uid: uid,
    );
    if (rows.isEmpty) {
      throw StateError('Aucune donnee a exporter.');
    }
    return _writeCsvFile(type: type, rows: rows);
  }

  Future<List<_ExportRow>> _fetchCollectionDocs({
    required String collection,
    required String type,
    required bool isAdmin,
    required String uid,
  }) async {
    Query<Map<String, dynamic>> query = _db.collection(collection);
    if (!isAdmin) {
      query = query.where('ownerId', isEqualTo: uid);
    }

    final snap = await query.get();
    if (snap.docs.isEmpty) {
      return const [];
    }

    final ownerIds = <String>{};
    for (final doc in snap.docs) {
      final ownerId = (doc.data()['ownerId'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        ownerIds.add(ownerId);
      }
    }
    final ownerNames = await _loadOwnerNames(ownerIds);

    final rows = <_ExportRow>[];
    for (final doc in snap.docs) {
      final raw = doc.data();
      final ownerId = (raw['ownerId'] ?? '').toString();
      final dataMap = _asStringDynamicMap(raw['data']);
      final flattened = _flattenMap(dataMap);

      rows.add(
        _ExportRow(
          metadata: {
            'type': type,
            'ownerName': ownerNames[ownerId] ?? '',
            'status': (raw['status'] ?? '').toString(),
            'createdAt': _toDateString(raw['createdAt']),
            'updatedAt': _toDateString(raw['updatedAt']),
          },
          data: flattened,
        ),
      );
    }
    return rows;
  }

  Future<Map<String, String>> _loadOwnerNames(Set<String> ownerIds) async {
    if (ownerIds.isEmpty) {
      return {};
    }
    final names = <String, String>{};
    await Future.wait(
      ownerIds.map((id) async {
        try {
          final doc = await _db.collection('users').doc(id).get();
          final data = doc.data();
          names[id] = (data?['fullName'] ?? '').toString();
        } catch (_) {
          names[id] = '';
        }
      }),
    );
    return names;
  }

  Future<File> _writeCsvFile({
    required String type,
    required List<_ExportRow> rows,
  }) async {
    final dataHeaders = <String>{};
    for (final row in rows) {
      dataHeaders.addAll(row.data.keys);
    }
    final orderedDataHeaders = dataHeaders.toList()..sort();

    const metadataHeaders = [
      'type',
      'ownerName',
      'status',
      'createdAt',
      'updatedAt',
    ];

    final headers = [...metadataHeaders, ...orderedDataHeaders];
    final buffer = StringBuffer()
      ..writeln(headers.map(_escapeCell).join(_delimiter));

    for (final row in rows) {
      final cells = <String>[];
      for (final h in metadataHeaders) {
        cells.add(_escapeCell((row.metadata[h] ?? '').toString()));
      }
      for (final h in orderedDataHeaders) {
        cells.add(_escapeCell((row.data[h] ?? '').toString()));
      }
      buffer.writeln(cells.join(_delimiter));
    }

    final stamp = _fileDateStamp(DateTime.now());
    final fileName = 'CercleBleu_${type}_$stamp.csv';
    final save = await saveCsvToDevice(fileName, buffer.toString());
    return save.shareableFile ??
        File('${(await getTemporaryDirectory()).path}/$fileName');
  }

  Future<CsvSaveResult> exportFilteredFormsCsv({
    required String filePrefix,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required List<String> dataKeys,
  }) async {
    if (docs.isEmpty) {
      throw StateError('Aucun formulaire a exporter.');
    }

    final headers = <String>[
      'title',
      'status',
      'createdAt',
      'updatedAt',
      'idObservation',
      ...dataKeys,
    ];
    final buffer = StringBuffer()
      ..writeln(headers.map(_escapeFilteredCell).join(_filteredDelimiter));

    for (final doc in docs) {
      final root = doc.data();
      final data = _asStringDynamicMap(root['data']);
      final idObservation =
          (data['gen_idObservation'] ?? data['idObservation'] ?? '').toString();

      final values = <String>[
        (root['title'] ?? '').toString(),
        (root['status'] ?? '').toString(),
        _toReadableDate(root['createdAt']),
        _toReadableDate(root['updatedAt']),
        idObservation,
        ...dataKeys.map((k) => (data[k] ?? '').toString()),
      ];
      buffer.writeln(values.map(_escapeFilteredCell).join(_filteredDelimiter));
    }

    final stamp = _fileDateStamp(DateTime.now());
    final fileName = '${filePrefix}_$stamp.csv';
    return saveCsvToDevice(fileName, buffer.toString());
  }

  Future<CsvSaveResult> saveCsvToDevice(
    String fileName,
    String csvString,
  ) async {
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvString)];

    if (Platform.isAndroid) {
      return _saveAndroid(fileName, bytes);
    }
    if (Platform.isIOS) {
      final docs = await getApplicationDocumentsDirectory();
      final folder = Directory('${docs.path}/Cercle Bleu');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final file = File('${folder.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return CsvSaveResult(
        fileName: fileName,
        savedLocation: 'Fichiers > Cercle Bleu',
        shareableFile: file,
      );
    }

    // UPDATED FOR WINDOWS DESKTOP
    if (Platform.isWindows) {
      final downloads = await getDownloadsDirectory();
      final baseDir = downloads ?? await getApplicationDocumentsDirectory();
      final folder = Directory('${baseDir.path}/Cercle Bleu');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }
      final file = File('${folder.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return CsvSaveResult(
        fileName: fileName,
        savedLocation: file.path,
        shareableFile: file,
      );
    }

    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return CsvSaveResult(
      fileName: fileName,
      savedLocation: file.path,
      shareableFile: file,
    );
  }

  String buildCsvFromSingleForm({
    required Map<String, dynamic> doc,
    required List<String> dataKeys,
    required Map<String, String> headers,
  }) {
    final data = _asStringDynamicMap(doc['data']);
    final rootColumns = <String>[
      'title',
      'status',
      'createdAt',
      'updatedAt',
      'lastEditedAt',
      'submittedAt',
    ];
    final orderedColumns = <String>[...rootColumns, ...dataKeys];
    final labels = orderedColumns
        .map((key) => headers[key] ?? key)
        .toList(growable: false);

    final row = orderedColumns
        .map((key) {
          if (key == 'createdAt' ||
              key == 'updatedAt' ||
              key == 'lastEditedAt' ||
              key == 'submittedAt') {
            return _toReadableDate(doc[key]);
          }
          if (rootColumns.contains(key)) {
            return (doc[key] ?? '').toString();
          }
          return (data[key] ?? '').toString();
        })
        .toList(growable: false);

    return buildCsvContent(headers: labels, rows: [row]);
  }

  String buildCsvContent({
    required List<String> headers,
    required List<List<String>> rows,
    String delimiter = ',',
  }) {
    final buffer = StringBuffer()
      ..writeln(
        headers.map((h) => _escapeGenericCell(h, delimiter)).join(delimiter),
      );
    for (final row in rows) {
      final normalized = row
          .map((c) => _escapeGenericCell(c, delimiter))
          .join(delimiter);
      buffer.writeln(normalized);
    }
    return buffer.toString();
  }

  String fileStampNow() => _fileDateStamp(DateTime.now());

  String formatDateTimeForCsv(DateTime? value) {
    if (value == null) return '';
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  Future<CsvSaveResult> _saveAndroid(String fileName, List<int> bytes) async {
    final sdk = await _androidSdkInt();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes, flush: true);

    if (sdk >= 29) {
      MediaStore.appFolder = 'Cercle Bleu';
      await MediaStore.ensureInitialized();
      final mediaStore = MediaStore();
      await mediaStore.saveFile(
        tempFilePath: tempFile.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );
      return CsvSaveResult(
        fileName: fileName,
        savedLocation: 'Telechargements',
        shareableFile: tempFile,
      );
    }

    final storage = await Permission.storage.request();
    if (!storage.isGranted) {
      throw StateError('Permission stockage refusee.');
    }
    final targetDir = Directory('/storage/emulated/0/Download');
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return CsvSaveResult(
      fileName: fileName,
      savedLocation: file.path,
      shareableFile: file,
    );
  }

  Future<int> _androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  Map<String, dynamic> _asStringDynamicMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  Map<String, String> _flattenMap(
    Map<String, dynamic> source, {
    String parentKey = '',
  }) {
    final out = <String, String>{};
    for (final entry in source.entries) {
      final key = parentKey.isEmpty ? entry.key : '${parentKey}_${entry.key}';
      final value = entry.value;
      if (value is Map) {
        out.addAll(
          _flattenMap(
            value.map((k, v) => MapEntry(k.toString(), v)),
            parentKey: key,
          ),
        );
      } else if (value is List) {
        out[key] = value.map(_valueToString).join('|');
      } else {
        out[key] = _valueToString(value);
      }
    }
    return out;
  }

  String _valueToString(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is num || value is bool || value is String) {
      return value.toString();
    }
    return jsonEncode(value);
  }

  String _toDateString(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return (value ?? '').toString();
  }

  String _escapeCell(String input) {
    final needsQuotes =
        input.contains(_delimiter) ||
        input.contains('"') ||
        input.contains('\n');
    if (!needsQuotes) {
      return input;
    }
    return '"${input.replaceAll('"', '""')}"';
  }

  String _fileDateStamp(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y$m$day'
        '_$hh$mm';
  }

  String _toReadableDate(dynamic value) {
    DateTime? d;
    if (value is Timestamp) d = value.toDate();
    if (value is DateTime) d = value;
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $hh:$mm';
  }

  String _escapeFilteredCell(String input) {
    final escaped = input.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n');
    if (!needsQuotes) return escaped;
    return '"$escaped"';
  }

  String _escapeGenericCell(String input, String delimiter) {
    final escaped = input.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(delimiter) ||
        escaped.contains('"') ||
        escaped.contains('\n');
    if (!needsQuotes) return escaped;
    return '"$escaped"';
  }
}

class _ExportRow {
  final Map<String, dynamic> metadata;
  final Map<String, String> data;

  const _ExportRow({required this.metadata, required this.data});
}