import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/csv_export_service.dart';
import '../../services/export_service.dart';
import '../../services/firestore_db.dart';
import '../../services/lek_form_service.dart';
import '../../utils/csv_columns.dart';
import 'adaptation_locale_page.dart';
import 'dynamique_du_crabe_page.dart';
import 'etat_des_lieux_page.dart';
import 'general_page.dart';
import 'impact_ecologique_page.dart';
import 'impact_sur_la_peche_page.dart';
import 'info_page.dart';
import 'niveau_de_confiance_page.dart';
import 'unite_de_peche_page.dart';

class LekHome extends StatefulWidget {
  final String formId;
  const LekHome({super.key, required this.formId});

  @override
  State<LekHome> createState() => _LekHomeState();
}

class _LekHomeState extends State<LekHome>
    with SingleTickerProviderStateMixin {
  final LekFormService _service = LekFormService();
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

  /// Navigates to a sub-screen and refreshes the home state when returning.
  void _open(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page)).then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _exportCurrentFormCsv() async {
    if (widget.formId.trim().isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final doc = await FirestoreDb.db
          .collection('lek_forms')
          .doc(widget.formId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('Formulaire introuvable.');
      }
      final csv = _csvService.buildCsvFromSingleForm(
        doc: doc.data()!,
        dataKeys: lekDataKeys,
        headers: const {},
      );
      final fileName = 'lek_form_${_csvService.fileStampNow()}.csv';
      final saved = await _csvService.saveCsvToDevice(fileName, csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved.savedLocation == 'Fichiers > Cercle Bleu'
                ? 'CSV enregistré dans Fichiers'
                : 'CSV enregistré dans Téléchargements',
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
      final doc = await FirestoreDb.db
          .collection('lek_forms')
          .doc(widget.formId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw StateError('Formulaire introuvable.');
      }
      final fileName = 'lek_form_${_csvService.fileStampNow()}.pdf';
      final bytes = await _exportService.buildPdfFromDocs(
        title: 'Formulaire Lek',
        docs: [doc.data()!],
        dataKeys: lekDataKeys,
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
                ? 'PDF enregistré dans Fichiers'
                : 'PDF enregistré dans Téléchargements',
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
    return Scaffold(
      body: StreamBuilder(
        stream: _service.watchForm(widget.formId),
        builder: (context, snapshot) {
          // Keep internal data updated live from Firestore
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final docData = snapshot.data!.data()!;
            final map = docData['data'] as Map<String, dynamic>? ?? {};
            _data = Map<String, dynamic>.from(map);
          }

          final topItems = <_GridItem>[
            _GridItem(
              title: 'Informations générales',
              icon: Icons.info_outline,
              color: const Color(0xFF00D9D9),
              onTap: () => _open(
                InformationsGeneralesPage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: "Informations sur l'enquête",
              icon: Icons.assignment_outlined,
              color: const Color(0xFF1E3A8A),
              onTap: () => _open(
                InfoPage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Unité de pêche',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                UniteDePechePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Dynamique du crabe (photos des deux espèces)',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                DynamiqueDuCrabePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Impact écologique',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                ImpactEcologiquePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Impact sur la pêche',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                ImpactSurLaPechePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Adaptation locale',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                AdaptationLocalePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Etat des lieux',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF00B8B8),
              onTap: () => _open(
                EtatDesLieuxPage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
            _GridItem(
              title: 'Niveau de confiance',
              icon: Icons.eco_outlined,
              color: const Color(0xFF2D4BA8),
              onTap: () => _open(
                NiveauDeConfiancePage(
                  formId: widget.formId,
                  data: Map<String, dynamic>.from(_data),
                ),
              ),
            ),
          ];

          String statusText = 'brouillon';
          int stepCompleted = 0;
          if (snapshot.hasData && snapshot.data!.data() != null) {
            final doc = snapshot.data!.data()!;
            statusText = (doc['status'] ?? 'brouillon').toString();
            stepCompleted = (doc['stepCompleted'] ?? 0) as int;
          }

          return Stack(
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
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'Questionnaire LEK',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(
                            0xFF1E3A8A,
                          ).withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF00D9D9,
                            ).withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/image/logo.png',
                        height: 86,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Erreur Firestore',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (snapshot.connectionState ==
                        ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Statut : $statusText | Progression : $stepCompleted/9',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F9FF),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final gridWidth = constraints.maxWidth;
                            const horizontalPadding = 16.0;
                            final availableWidth =
                                gridWidth - (horizontalPadding * 2);
                            final tileWidth = (availableWidth - 12) / 2;
                            final tileHeight =
                                tileWidth < 150 ? 136.0 : (tileWidth * 0.92);

                            return SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                14,
                                16,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 12),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          mainAxisExtent: tileHeight,
                                        ),
                                    itemCount: topItems.length,
                                    itemBuilder: (context, index) {
                                      final item = topItems[index];
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
                                          onTap:
                                              _isExporting ||
                                                      widget.formId
                                                          .trim()
                                                          .isEmpty
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
                                          onTap:
                                              _isExporting ||
                                                      widget.formId
                                                          .trim()
                                                          .isEmpty
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
          );
        },
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
            final compact = constraints.maxHeight < 135;
            final iconBoxSize = compact ? 44.0 : 50.0;
            final iconSize = compact ? 24.0 : 28.0;
            final spacing = compact ? 8.0 : 10.0;
            return Container(
              padding: EdgeInsets.all(compact ? 12 : 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                  width: 1.4,
                ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
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