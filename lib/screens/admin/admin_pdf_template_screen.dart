import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../painters/wave_painter.dart';
import '../../services/export_service.dart';
import '../../services/firestore_db.dart';
import 'widgets/admin_role_guard.dart';

class AdminPdfTemplateScreen extends StatefulWidget {
  const AdminPdfTemplateScreen({super.key});

  @override
  State<AdminPdfTemplateScreen> createState() => _AdminPdfTemplateScreenState();
}

class _AdminPdfTemplateScreenState extends State<AdminPdfTemplateScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirestoreDb.db;
  final ExportService _exportService = ExportService();
  final TextEditingController _appNameCtrl = TextEditingController();
  final TextEditingController _subtitleCtrl = TextEditingController();
  final TextEditingController _footerCtrl = TextEditingController();
  late final AnimationController _waveController;

  bool _loading = true;
  bool _saving = false;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _appNameCtrl.addListener(_refreshPreview);
    _subtitleCtrl.addListener(_refreshPreview);
    _footerCtrl.addListener(_refreshPreview);
    _loadTemplate();
  }

  @override
  void dispose() {
    _appNameCtrl.removeListener(_refreshPreview);
    _subtitleCtrl.removeListener(_refreshPreview);
    _footerCtrl.removeListener(_refreshPreview);
    _appNameCtrl.dispose();
    _subtitleCtrl.dispose();
    _footerCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadTemplate() async {
    setState(() => _loading = true);
    try {
      final doc = await _db
          .collection('app_settings')
          .doc('pdf_template')
          .get();
      final data = doc.data() ?? {};
      _appNameCtrl.text = (data['appName']?.toString() ?? 'Cercle Bleu').trim();
      _subtitleCtrl.text =
          (data['subtitle']?.toString() ?? 'Template PDF Application').trim();
      _footerCtrl.text =
          (data['footer']?.toString() ?? 'Document genere par Cercle Bleu')
              .trim();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur chargement template PDF')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveTemplate() async {
    setState(() => _saving = true);
    try {
      await _db.collection('app_settings').doc('pdf_template').set({
        'appName': _appNameCtrl.text.trim(),
        'subtitle': _subtitleCtrl.text.trim(),
        'footer': _footerCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Template PDF mis a jour')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur sauvegarde template PDF')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openPdfPreview() async {
    setState(() => _previewing = true);
    try {
      final demoDocs = <Map<String, dynamic>>[
        {
          'title': 'Apercu template PDF',
          'ownerName': 'Admin',
          'status': 'brouillon',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
          'lastEditedAt': DateTime.now(),
          'submittedAt': null,
          'data': <String, dynamic>{
            'zone': 'Port exemple',
            'commentaire': 'Ceci est un apercu du template PDF configure.',
          },
        },
      ];
      final bytes = await _exportService.buildPdfFromDocs(
        title: 'Apercu Template',
        docs: demoDocs,
        dataKeys: const ['zone', 'commentaire'],
        labels: const {'zone': 'Zone', 'commentaire': 'Commentaire'},
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              _PdfPreviewPage(title: 'Apercu Template PDF', bytes: bytes),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d ouvrir l apercu PDF')),
      );
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminRoleGuard(
      child: Scaffold(
        body: Stack(
          children: [
            SizedBox(
              height: 230,
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
                      waveHeight: 20,
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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
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
                            'Template PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadTemplate,
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
                              children: [
                                _fieldCard(),
                                const SizedBox(height: 14),
                                _previewCard(),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _previewing
                                              ? null
                                              : _openPdfPreview,
                                          icon: const Icon(
                                            Icons.picture_as_pdf_rounded,
                                          ),
                                          label: Text(
                                            _previewing
                                                ? 'Ouverture...'
                                                : 'Ouvrir l apercu PDF',
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF00B8B8,
                                            ),
                                            minimumSize: const Size.fromHeight(
                                              50,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _saving
                                              ? null
                                              : _saveTemplate,
                                          icon: const Icon(Icons.save_outlined),
                                          label: Text(
                                            _saving
                                                ? 'Enregistrement...'
                                                : 'Enregistrer',
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF1E3A8A,
                                            ),
                                            minimumSize: const Size.fromHeight(
                                              50,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldCard() {
    InputDecoration dec(String label) => InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      isDense: true,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _appNameCtrl,
            decoration: dec('Nom application PDF'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitleCtrl,
            decoration: dec('Sous-titre PDF'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _footerCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: dec('Pied de page PDF'),
          ),
        ],
      ),
    );
  }

  Widget _previewCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apercu template',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _appNameCtrl.text.trim().isEmpty
                      ? 'Cercle Bleu'
                      : _appNameCtrl.text.trim(),
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleCtrl.text.trim().isEmpty
                      ? 'Template PDF Application'
                      : _subtitleCtrl.text.trim(),
                  style: const TextStyle(color: Color(0xFF334155)),
                ),
                const Divider(height: 22),
                const Text(
                  'Contenu formulaire ...',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                Text(
                  _footerCtrl.text.trim().isEmpty
                      ? 'Document genere par Cercle Bleu'
                      : _footerCtrl.text.trim(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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

class _PdfPreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const _PdfPreviewPage({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: PdfPreview(
        build: (format) async => bytes,
        canChangePageFormat: false,
        canChangeOrientation: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'template_apercu.pdf',
        maxPageWidth: 700,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}
