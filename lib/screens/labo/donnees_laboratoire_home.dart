import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/csv_export_service.dart';
import '../../services/export_service.dart';
import '../../services/firestore_db.dart';
import '../../services/lab_form_service.dart';
import '../../utils/csv_columns.dart';
import 'analyse_crabe_bleu_page2.dart';
import 'analyse_laboratoire_page1.dart';
import 'epibionts_page3.dart';
import 'lab_attachments_screen.dart';
import 'remarques_page4.dart';

class DonneesLaboratoireHome extends StatefulWidget {
  final String formId;
  const DonneesLaboratoireHome({super.key, required this.formId});

  @override
  State<DonneesLaboratoireHome> createState() => _DonneesLaboratoireHomeState();
}

class _DonneesLaboratoireHomeState extends State<DonneesLaboratoireHome>
    with SingleTickerProviderStateMixin {
  final LabFormService _service = LabFormService();
  final CsvExportService _csvService = CsvExportService();
  final ExportService _exportService = ExportService();
  Map<String, dynamic> _data = <String, dynamic>{};
  late final AnimationController _waveController;
  bool _isExporting = false;

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
    _waveController.dispose();
    super.dispose();
  }

  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then(
      (_) => setState(() {}),
    );
  }

  Future<void> _exportCurrentFormCsv() async {
    if (widget.formId.trim().isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = await FirestoreDb.db.collection('lab_forms').doc(widget.formId).get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('Formulaire introuvable.');
      }
      final csv = _csvService.buildCsvFromSingleForm(
        doc: doc.data()!,
        dataKeys: labDataKeys,
        headers: const {},
      );
      final fileName = 'lab_form_${_csvService.fileStampNow()}.csv';
      final saved = await _csvService.saveCsvToDevice(fileName, csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? 'CSV enregistre dans Fichiers'
                : 'CSV enregistre dans Telechargements',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export CSV impossible: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCurrentFormPdf() async {
    if (widget.formId.trim().isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = await FirestoreDb.db.collection('lab_forms').doc(widget.formId).get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('Formulaire introuvable.');
      }
      final fileName = 'lab_form_${_csvService.fileStampNow()}.pdf';
      final bytes = await _exportService.buildPdfFromDocs(
        title: 'Formulaire Laboratoire',
        docs: [doc.data()!],
        dataKeys: labDataKeys,
      );
      final saved = await _exportService.saveBytesToDevice(fileName: fileName, bytes: bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? 'PDF enregistre dans Fichiers'
                : 'PDF enregistre dans Telechargements',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export PDF impossible: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_GridItem>[
      _GridItem(
        title: 'Infos generales analyse laboratoire',
        icon: Icons.science_rounded,
        color: const Color(0xFF00D9D9),
        onTap: () => _open(AnalyseLaboratoirePage1(formId: widget.formId, data: _data)),
      ),
      _GridItem(
        title: 'Analyse crabe bleu',
        icon: Icons.bug_report_rounded,
        color: const Color(0xFF1E3A8A),
        onTap: () => _open(AnalyseCrabeBleuPage2(formId: widget.formId, data: _data)),
      ),
      _GridItem(
        title: 'Epibionts',
        icon: Icons.eco_rounded,
        color: const Color(0xFF00B8B8),
        onTap: () => _open(EpibiontsPage3(formId: widget.formId, data: _data)),
      ),
      _GridItem(
        title: 'Remarques',
        icon: Icons.note_alt_rounded,
        color: const Color(0xFF2D4BA8),
        onTap: () => _open(RemarquesPage4(formId: widget.formId, data: _data)),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 230,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8), Color(0xFF1E3A8A)],
                ),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) => CustomPaint(
                  painter: WavePainter(
                    animation: _waveController.value,
                    color: const Color(0xFF00D9D9).withValues(alpha: 0.12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Donnees laboratoire',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D9D9).withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/image/logo.png', height: 86, fit: BoxFit.contain),
                ),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: _service.watchForm(widget.formId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Erreur Firestore',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final doc = snapshot.data!.data()!;
                      final map = doc['data'] as Map<String, dynamic>? ?? {};
                      _data = Map<String, dynamic>.from(map);
                      final status = (doc['status'] ?? 'brouillon').toString();
                      final step = (doc['stepCompleted'] ?? 0).toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Statut : $status | Progression : $step/4',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 8);
                  },
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF5F9FF),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final gridWidth = constraints.maxWidth;
                        final horizontalPadding = 16.0;
                        final availableWidth = gridWidth - (horizontalPadding * 2);
                        final tileWidth = (availableWidth - 12) / 2;
                        final tileHeight = tileWidth < 150 ? 144.0 : (tileWidth * 0.96);

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _open(LabAttachmentsScreen(formId: widget.formId)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.attach_file_rounded, color: Color(0xFF1E3A8A)),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'Pieces jointes',
                                            style: TextStyle(
                                              color: Color(0xFF1E3A8A),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        Icon(Icons.chevron_right_rounded, color: Color(0xFF1E3A8A)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: tileHeight,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return _GridButton(
                                    title: item.title,
                                    icon: item.icon,
                                    color: item.color,
                                    onTap: item.onTap,
                                  );
                                },
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _BottomActionButton(
                                      text: 'CSV',
                                      icon: _isExporting
                                          ? null
                                          : Icons.file_download_outlined,
                                      isLoading: _isExporting,
                                      color: const Color(0xFF1E3A8A),
                                      onTap: _isExporting || widget.formId.trim().isEmpty
                                          ? null
                                          : _exportCurrentFormCsv,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _BottomActionButton(
                                      text: 'PDF',
                                      icon: Icons.picture_as_pdf_outlined,
                                      color: const Color(0xFF00B8B8),
                                      onTap: _isExporting || widget.formId.trim().isEmpty
                                          ? null
                                          : _exportCurrentFormPdf,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _BottomActionButton(
                                      text: 'Retour',
                                      icon: Icons.arrow_back_rounded,
                                      color: const Color(0xFF2D4BA8),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
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

class _GridItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _GridItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _GridButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_GridButton> createState() => _GridButtonState();
}

class _GridButtonState extends State<_GridButton> {
  double _scale = 1.0;

  void _setScale(bool pressed) {
    setState(() => _scale = pressed ? 0.97 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(true),
      onTapUp: (_) => _setScale(false),
      onTapCancel: () => _setScale(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 145;
            final iconBoxSize = compact ? 44.0 : 50.0;
            final iconSize = compact ? 24.0 : 28.0;
            final spacing = compact ? 8.0 : 10.0;
            return Container(
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withValues(alpha: 0.12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: iconSize),
                  ),
                  SizedBox(height: spacing),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 12.5 : 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool isLoading;
  final Color color;
  final VoidCallback? onTap;

  const _BottomActionButton({
    required this.text,
    required this.color,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else if (icon != null)
                Icon(icon, size: 16),
              if (isLoading || icon != null) const SizedBox(width: 6),
              Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
