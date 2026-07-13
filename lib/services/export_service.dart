import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:media_store_plus/media_store_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';

import 'csv_export_service.dart';
import 'firestore_db.dart';

typedef ProgressCallback = void Function(int loaded);

class ExportService {
  final FirebaseFirestore _db = FirestoreDb.db;

  static const List<String> _rootColumns = <String>[
    'title',
    'ownerName',
    'status',
    'createdAt',
    'updatedAt',
    'lastEditedAt',
    'submittedAt',
  ];

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchAllDocuments({
    required String collection,
    String? ownerId,
    int pageSize = 300,
    ProgressCallback? onProgress,
  }) async {
    Query<Map<String, dynamic>> base = _db
        .collection(collection)
        .orderBy('updatedAt', descending: true)
        .limit(pageSize);
    if (ownerId != null && ownerId.isNotEmpty) {
      base = base.where('ownerId', isEqualTo: ownerId);
    }

    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query = base;
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snap = await query.get();
      if (snap.docs.isEmpty) {
        break;
      }
      out.addAll(snap.docs);
      onProgress?.call(out.length);
      if (snap.docs.length < pageSize) {
        break;
      }
      cursor = snap.docs.last;
    }

    return out;
  }

  String buildCsvFromDocs({
    required List<Map<String, dynamic>> docs,
    required List<String> dataKeys,
    Map<String, String> labels = const {},
  }) {
    final headers = <String>[
      ..._rootColumns.map((k) => labels[k] ?? _humanize(k)),
      ...dataKeys.map((k) => labels[k] ?? _humanize(k)),
    ];
    final rows = docs.map((root) {
      final data = _asMap(root['data']);
      final rootValues = <String>[
        (root['title'] ?? '').toString(),
        (root['ownerName'] ?? '').toString(),
        (root['status'] ?? '').toString(),
        _formatDate(root['createdAt']),
        _formatDate(root['updatedAt']),
        _formatDate(root['lastEditedAt']),
        _formatDate(root['submittedAt']),
      ];
      final dataValues = dataKeys
          .map((k) => (data[k] ?? '').toString())
          .toList();
      return <String>[...rootValues, ...dataValues];
    }).toList();

    final csv = StringBuffer()..writeln(headers.map(_escapeCell).join(','));
    for (final row in rows) {
      csv.writeln(row.map(_escapeCell).join(','));
    }
    return csv.toString();
  }

  Future<Uint8List> buildPdfFromDocs({
    required String title,
    required List<Map<String, dynamic>> docs,
    required List<String> dataKeys,
    Map<String, String> labels = const {},
  }) async {
    final pdf = pw.Document();
    final template = await _loadPdfTemplate();
    pw.MemoryImage? logo;
    try {
      final logoBytes = await rootBundle.load('assets/image/logo.png');
      logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    for (var i = 0; i < docs.length; i++) {
      final root = docs[i];
      final data = _asMap(root['data']);
      final rows = <List<String>>[
        ['Titre', (root['title'] ?? '').toString()],
        ['Responsable', (root['ownerName'] ?? '').toString()],
        ['Statut', (root['status'] ?? '').toString()],
        ['Créé le', _formatDate(root['createdAt'])],
        ['Mis à jour', _formatDate(root['updatedAt'])],
        ['Dernière édition', _formatDate(root['lastEditedAt'])],
        ['Soumis le', _formatDate(root['submittedAt'])],
      ];

      for (final key in dataKeys) {
        final value = (data[key] ?? '').toString();
        if (value.isEmpty) continue;
        rows.add([labels[key] ?? _humanize(key), value]);
      }

      pdf.addPage(
        pw.MultiPage(
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerLeft,
            margin: const pw.EdgeInsets.only(top: 14),
            child: pw.Text(
              template.footer,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey),
            ),
          ),
          build: (context) => [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 66,
                    height: 66,
                    margin: const pw.EdgeInsets.only(right: 10),
                    child: pw.Image(logo),
                  ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      template.appName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      template.subtitle.isEmpty ? title : template.subtitle,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Formulaire ${i + 1}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.blueGrey100),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.3),
                1: const pw.FlexColumnWidth(4),
              },
              children: rows
                  .map(
                    (r) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            r[0],
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            r[1],
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    }

    return pdf.save();
  }

  Future<CsvSaveResult> saveCsvToDevice({
    required String fileName,
    required String csvContent,
  }) async {
    final bytes = <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(csvContent)];
    return saveBytesToDevice(fileName: fileName, bytes: bytes);
  }

  Future<CsvSaveResult> saveBytesToDevice({
    required String fileName,
    required List<int> bytes,
  }) async {
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

    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return CsvSaveResult(
      fileName: fileName,
      savedLocation: file.path,
      shareableFile: file,
    );
  }

  String fileStampNow() {
    final d = DateTime.now();
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$y$m${day}_$hh$mm';
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

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return {};
  }

  String _formatDate(dynamic value) {
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

  String _humanize(String key) {
    final clean = key.replaceAll('_', ' ');
    if (clean.isEmpty) return key;
    return clean[0].toUpperCase() + clean.substring(1);
  }

  String _escapeCell(String input) {
    final escaped = input.replaceAll('"', '""');
    final needsQuotes =
        escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n');
    if (!needsQuotes) return escaped;
    return '"$escaped"';
  }

  Future<_PdfTemplateSettings> _loadPdfTemplate() async {
    try {
      final doc = await _db
          .collection('app_settings')
          .doc('pdf_template')
          .get();
      final data = doc.data() ?? const <String, dynamic>{};
      final appName = (data['appName']?.toString() ?? '').trim();
      final subtitle = (data['subtitle']?.toString() ?? '').trim();
      final footer = (data['footer']?.toString() ?? '').trim();
      return _PdfTemplateSettings(
        appName: appName.isEmpty ? 'Cercle Bleu' : appName,
        subtitle: subtitle,
        footer: footer.isEmpty ? 'Document genere par Cercle Bleu' : footer,
      );
    } catch (_) {
      return const _PdfTemplateSettings(
        appName: 'Cercle Bleu',
        subtitle: '',
        footer: 'Document genere par Cercle Bleu',
      );
    }
  }
}

class _PdfTemplateSettings {
  final String appName;
  final String subtitle;
  final String footer;

  const _PdfTemplateSettings({
    required this.appName,
    required this.subtitle,
    required this.footer,
  });
}
