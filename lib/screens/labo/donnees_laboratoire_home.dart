import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lab_form_service.dart';
import 'analyse_laboratoire_page1.dart';
import 'analyse_crabe_bleu_page2.dart';
import 'epibionts_page3.dart';
import 'remarques_page4.dart';

class DonneesLaboratoireHome extends StatefulWidget {
  final String formId;
  const DonneesLaboratoireHome({super.key, required this.formId});

  @override
  State<DonneesLaboratoireHome> createState() =>
      _DonneesLaboratoireHomeState();
}

class _DonneesLaboratoireHomeState extends State<DonneesLaboratoireHome>
    with SingleTickerProviderStateMixin {
  final LabFormService _service = LabFormService();
  Map<String, dynamic> _data = <String, dynamic>{};
  late AnimationController _waveController;

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => setState(() {}));
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
                      final tileHeight =
                          tileWidth < 150 ? 140.0 : (tileWidth * 0.95);
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
    final width = MediaQuery.of(context).size.width;
    final iconSize = width < 360 ? 26.0 : (width < 400 ? 28.0 : 30.0);
    return GestureDetector(
      onTapDown: (_) => _setScale(true),
      onTapUp: (_) => _setScale(false),
      onTapCancel: () => _setScale(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.12),
                ),
                child: Icon(widget.icon, color: widget.color, size: iconSize),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
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
