import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import '../../widgets/app_feedback.dart';
import 'matrice1_home.dart';

class RemarquesPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const RemarquesPage({super.key, required this.data, required this.formId});

  @override
  State<RemarquesPage> createState() => _RemarquesPageState();
}

class _RemarquesPageState extends State<RemarquesPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final _remarquesCtrl = TextEditingController();
  late AnimationController _waveController;
  final TerrainFormService _service = TerrainFormService();

  bool _pecheurReticent = false;
  bool _infoPartielle = false;
  bool _gpsEstime = false;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _remarquesCtrl.text = (data['rem_text'] ?? '').toString();
    _pecheurReticent = (data['rem_pecheurReticent'] ?? false) as bool;
    _infoPartielle = (data['rem_infoPartielle'] ?? false) as bool;
    _gpsEstime = (data['rem_gpsEstime'] ?? false) as bool;

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _remarquesCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    bool alignLabelWithHint = false,
  }) => InputDecoration(
    labelText: label,
    hintText: hint ?? 'Saisir ici...',
    alignLabelWithHint: alignLabelWithHint,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    labelStyle: const TextStyle(
      color: Color(0xFF1E3A8A),
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    floatingLabelStyle: const TextStyle(
      color: Color(0xFF1E3A8A),
      fontWeight: FontWeight.w700,
    ),
    filled: true,
    fillColor: const Color(0xFFF8FBFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF00D9D9), width: 2),
    ),
  );

  Future<void> _finish() async {
    data['rem_text'] = _remarquesCtrl.text;
    data['rem_pecheurReticent'] = _pecheurReticent;
    data['rem_infoPartielle'] = _infoPartielle;
    data['rem_gpsEstime'] = _gpsEstime;
    showModernSuccessSnackBar(context);

    await Future.delayed(const Duration(milliseconds: 2100));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Matrice1Home(formId: widget.formId)),
      (route) => route.isFirst,
    );
  }

  void _goToTerrainHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => Matrice1Home(formId: widget.formId)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 220,
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
                      waveHeight: 18,
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
                        onPressed: _goToTerrainHome,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Remarques',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u00C9tape 5/5',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _sectionCard(
                        children: [
                          CheckboxListTile(
                            value: _pecheurReticent,
                            onChanged: (v) {
                              setState(() => _pecheurReticent = v ?? false);
                              data['rem_pecheurReticent'] = _pecheurReticent;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                            title: const Text("P\u00EAcheur r\u00E9ticent"),
                          ),
                          CheckboxListTile(
                            value: _infoPartielle,
                            onChanged: (v) {
                              setState(() => _infoPartielle = v ?? false);
                              data['rem_infoPartielle'] = _infoPartielle;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                            title: const Text("Information partielle"),
                          ),
                          CheckboxListTile(
                            value: _gpsEstime,
                            onChanged: (v) {
                              setState(() => _gpsEstime = v ?? false);
                              data['rem_gpsEstime'] = _gpsEstime;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                            title: const Text(
                              "GPS estim\u00E9 (pas mesur\u00E9)",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _sectionCard(
                        children: [
                          TextFormField(
                            controller: _remarquesCtrl,
                            maxLines: 12,
                            minLines: 6,
                            decoration: _dec(
                              label: "Remarques",
                              hint:
                                  "Ex: P\u00EAcheur r\u00E9ticent, information partielle, GPS estim\u00E9 (pas mesur\u00E9)...",
                              alignLabelWithHint: true,
                            ),
                            onChanged: (v) {
                              data['rem_text'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PrimaryGradientButton(
                        text: 'Terminer',
                        icon: Icons.check,
                        onPressed: _finish,
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

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(children: children),
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
