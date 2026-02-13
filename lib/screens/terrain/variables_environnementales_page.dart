import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'remarques_page.dart';

class VariablesEnvironnementalesPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const VariablesEnvironnementalesPage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<VariablesEnvironnementalesPage> createState() =>
      _VariablesEnvironnementalesPageState();
}

class _VariablesEnvironnementalesPageState
    extends State<VariablesEnvironnementalesPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _substratCtrl = TextEditingController();
  final _profondeurCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _oxygeneCtrl = TextEditingController();
  final _saliniteCtrl = TextEditingController();

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _substratCtrl.text = (data['env_substrat'] ?? '').toString();
    _profondeurCtrl.text = (data['env_profondeur'] ?? '').toString();
    _temperatureCtrl.text = (data['env_temperature'] ?? '').toString();
    _oxygeneCtrl.text = (data['env_oxygene'] ?? '').toString();
    _saliniteCtrl.text = (data['env_salinite'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _substratCtrl.dispose();
    _profondeurCtrl.dispose();
    _temperatureCtrl.dispose();
    _oxygeneCtrl.dispose();
    _saliniteCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 4);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemarquesPage(formId: widget.formId, data: data),
      ),
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
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Variables environnementales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 4/5',
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
                      _sectionCard(children: [
                        TextFormField(
                          controller: _substratCtrl,
                          decoration: _dec("Type de substrat"),
                          onChanged: (v) => data['env_substrat'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _profondeurCtrl,
                          decoration: _dec("Profondeur (cm)"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['env_profondeur'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _temperatureCtrl,
                          decoration: _dec("Température (°C)"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['env_temperature'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _oxygeneCtrl,
                          decoration: _dec("Oxygène"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['env_oxygene'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _saliniteCtrl,
                          decoration: _dec("Salinité (psu)"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['env_salinite'] = v,
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Précédent',
                              icon: Icons.arrow_back,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PrimaryGradientButton(
                              text: 'Suivant',
                              icon: Icons.arrow_forward,
                              onPressed: _goNext,
                            ),
                          ),
                        ],
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

class _OutlineButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const _OutlineButton({
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: const Color(0xFF1E3A8A)),
      label: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w700,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: const Color(0xFF1E3A8A).withOpacity(0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
