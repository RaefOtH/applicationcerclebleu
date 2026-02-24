import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/csv_export_service.dart';
import '../../services/export_service.dart';
import '../../services/firestore_db.dart';
import '../../services/lab_form_service.dart';
import '../../utils/csv_columns.dart';
import 'analyse_laboratoire_page1.dart';
import 'analyse_crabe_bleu_page2.dart';
import 'epibionts_page3.dart';
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
  late AnimationController _waveController;
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => setState(() {}));
  }

  Future<void> _exportCurrentFormCsv() async {
    if (widget.formId.trim().isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = await FirestoreDb.db
          .collection('lab_forms')
          .doc(widget.formId)
          .get();
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
                ? '✅ CSV enregistre dans Fichiers'
                : '✅ CSV enregistre dans Telechargements',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Export CSV impossible: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCurrentFormPdf() async {
    if (widget.formId.trim().isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = await FirestoreDb.db
          .collection('lab_forms')
          .doc(widget.formId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('Formulaire introuvable.');
      }
      final fileName = 'lab_form_${_csvService.fileStampNow()}.pdf';
      final bytes = await _exportService.buildPdfFromDocs(
        title: 'Formulaire Laboratoire',
        docs: [doc.data()!],
        dataKeys: labDataKeys,
      );
      final saved = await _exportService.saveBytesToDevice(
        fileName: fileName,
        bytes: bytes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? '✅ PDF enregistré dans Fichiers'
                : '✅ PDF enregistré dans Téléchargements',
          ),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Export PDF impossible: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2D4BA8),
                    Color(0xFF1E3A8A),
                  ],
                ),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withOpacity(0.12),
                      waveHeight: 20,
                    ),
                    size: Size.infinite,
                  );
                },
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
                      const Text(
                        'Données Laboratoire',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D9D9).withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/image/logo.png',
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder(
                  stream: _service.watchForm(widget.formId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Erreur Firestore: ${snapshot.error}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.data() != null) {
                      final doc = snapshot.data!.data()!;
                      final map = doc['data'] as Map<String, dynamic>? ?? {};
                      _data = Map<String, dynamic>.from(map);
                      final status = (doc['status'] ?? 'brouillon').toString();
                      final step = (doc['stepCompleted'] ?? 0).toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Statut: $status • Progression: $step/4',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }
                    return const SizedBox(height: 6);
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final gridWidth = constraints.maxWidth;
                      final horizontalPadding = 20.0;
                      final availableWidth =
                          gridWidth - (horizontalPadding * 2);
                      final tileWidth = (availableWidth - 14) / 2;
                      final tileHeight = tileWidth < 150
                          ? 148.0
                          : (tileWidth * 1.02);
                      final maxGridHeight = tileHeight * 2 + 14;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: availableWidth,
                            maxHeight: maxGridHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    mainAxisExtent: tileHeight,
                                  ),
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                final items = [
                                  _GridItem(
                                    title:
                                        'Infos générales\nanalyse laboratoire',
                                    icon: Icons.science_rounded,
                                    color: const Color(0xFF00D9D9),
                                    onTap: () => _open(
                                      AnalyseLaboratoirePage1(
                                        formId: widget.formId,
                                        data: _data,
                                      ),
                                    ),
                                  ),
                                  _GridItem(
                                    title: 'Analyse crabe bleu',
                                    icon: Icons.bug_report_rounded,
                                    color: const Color(0xFF1E3A8A),
                                    onTap: () => _open(
                                      AnalyseCrabeBleuPage2(
                                        formId: widget.formId,
                                        data: _data,
                                      ),
                                    ),
                                  ),
                                  _GridItem(
                                    title: 'Epibionts',
                                    icon: Icons.eco_rounded,
                                    color: const Color(0xFF00B8B8),
                                    onTap: () => _open(
                                      EpibiontsPage3(
                                        formId: widget.formId,
                                        data: _data,
                                      ),
                                    ),
                                  ),
                                  _GridItem(
                                    title: 'Remarques',
                                    icon: Icons.note_alt_rounded,
                                    color: const Color(0xFF2D4BA8),
                                    onTap: () => _open(
                                      RemarquesPage4(
                                        formId: widget.formId,
                                        data: _data,
                                      ),
                                    ),
                                  ),
                                ];

                                final item = items[index];
                                return _GridButton(
                                  title: item.title,
                                  icon: item.icon,
                                  color: item.color,
                                  onTap: item.onTap,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _isExporting || widget.formId.trim().isEmpty
                              ? null
                              : _exportCurrentFormCsv,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.file_download_outlined),
                          label: const Text('Exporter CSV'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _isExporting || widget.formId.trim().isEmpty
                              ? null
                              : _exportCurrentFormPdf,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Exporter PDF'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF00B8B8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: _PrimaryGradientButton(
                          text: 'Retour',
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
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
            final iconBoxSize = compact ? 44.0 : 52.0;
            final iconSize = compact ? 24.0 : 28.0;
            final spacing = compact ? 8.0 : 12.0;
            final fontSize = compact ? 12.5 : 14.0;
            return Container(
              padding: EdgeInsets.all(compact ? 12 : 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(0.12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
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

class _PrimaryGradientButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryGradientButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
