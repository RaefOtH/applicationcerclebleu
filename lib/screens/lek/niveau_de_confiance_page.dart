import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import '../../widgets/app_feedback.dart';
import 'lek_home.dart';

class NiveauDeConfiancePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const NiveauDeConfiancePage({super.key, required this.data, required this.formId});

  @override
  State<NiveauDeConfiancePage> createState() => _NiveauDeConfiancePageState();
}

class _NiveauDeConfiancePageState extends State<NiveauDeConfiancePage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final _remarquesCtrl = TextEditingController();
  late AnimationController _waveController;
  final LekFormService _service = LekFormService();

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
      MaterialPageRoute(builder: (_) => LekHome(formId: widget.formId)),
      (route) => route.isFirst,
    );
  }

  void _goToLekHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LekHome(formId: widget.formId)),
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
                      color: const Color(0xFF00D9D9).withValues(alpha: 0.12),
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
                        onPressed: _goToLekHome,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Niveau de confiance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u00C9tape 9/9',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
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
                          TextFormField(
                            controller: _remarquesCtrl,
                            maxLines: 12,
                            minLines: 6,
                            decoration: _dec(
                              label: "Niveau de confiance",
                              hint:
                                  "Ex: Niveau de confiance",
                              alignLabelWithHint: true,
                            ),
                            onChanged: (v) {
                              data['Niveau de confiance_niveau de confiance'] = v;
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
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withValues(alpha: 0.08),
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
            color: const Color(0xFF00D9D9).withValues(alpha: 0.35),
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
