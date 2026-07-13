import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'matrice1_home.dart';
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
  static const List<String> _substratOptions = [
    'vase',
    'sable',
    'fond dur',
    'cailloutis et galets',
    'fond dur et roches',
    'vases sableuses',
    'Herbiers (posidonie, Zostère, Cymodocée…)',
    'algues',
    'Autre (préciser)',
  ];
  static const List<String> _profondeurOptions = [
    "Hors de l'eau",
    'Nageant juste en dessous de la surface',
    'Entre 0 et 1 m',
    'Entre 1 et 3 m',
    'Supérieure à 3 m',
    'Autre (préciser)',
  ];

  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _substratCtrl = TextEditingController();
  final _substratAutreCtrl = TextEditingController();
  final _profondeurCtrl = TextEditingController();
  final _profondeurAutreCtrl = TextEditingController();
  final _temperatureCtrl = TextEditingController();
  final _oxygeneCtrl = TextEditingController();
  final _saliniteCtrl = TextEditingController();
  String? _selectedSubstrat;
  String? _selectedProfondeur;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _substratCtrl.text = (data['env_substrat'] ?? '').toString();
    _substratAutreCtrl.text = (data['env_substratAutre'] ?? '').toString();
    _profondeurCtrl.text = (data['env_profondeur'] ?? '').toString();
    _profondeurAutreCtrl.text = (data['env_profondeurAutre'] ?? '').toString();
    _temperatureCtrl.text = (data['env_temperature'] ?? '').toString();
    _oxygeneCtrl.text = (data['env_oxygene'] ?? '').toString();
    _saliniteCtrl.text = (data['env_salinite'] ?? '').toString();
    _selectedSubstrat = _safeOption(data['env_substrat'], _substratOptions);
    _selectedProfondeur = _safeOption(
      data['env_profondeur'],
      _profondeurOptions,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _substratCtrl.dispose();
    _substratAutreCtrl.dispose();
    _profondeurCtrl.dispose();
    _profondeurAutreCtrl.dispose();
    _temperatureCtrl.dispose();
    _oxygeneCtrl.dispose();
    _saliniteCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    hintText: 'Saisir ici...',
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    floatingLabelAlignment: FloatingLabelAlignment.start,
    labelStyle: const TextStyle(
      color: Color(0xFF1E3A8A),
      fontWeight: FontWeight.w600,
    ),
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

  String? _safeOption(dynamic raw, List<String> options) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  void _goNext() {
    if ((_selectedSubstrat ?? '') == 'Autre (préciser)' &&
        _substratAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez préciser le substrat.')),
      );
      return;
    }
    if ((_selectedProfondeur ?? '') == 'Autre (préciser)' &&
        _profondeurAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez préciser la profondeur.')),
      );
      return;
    }
    _service.updateFormData(widget.formId, data, stepCompleted: 4);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RemarquesPage(formId: widget.formId, data: data),
      ),
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
                        onPressed: _goToTerrainHome,
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Variables environnementales',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\u00C9tape 4/5',
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
                          DropdownButtonFormField<String>(
                            initialValue: _selectedSubstrat,
                            isExpanded: true,
                            decoration: _dec("Type de substrat"),
                            hint: const Text('Choisir...'),
                            items: _substratOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedSubstrat = value);
                              if (value != null) {
                                _substratCtrl.text = value;
                                data['env_substrat'] = value;
                                if (value != 'Autre (préciser)') {
                                  _substratAutreCtrl.clear();
                                  data.remove('env_substratAutre');
                                }
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              }
                            },
                          ),
                          if (_selectedSubstrat == 'Autre (préciser)') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _substratAutreCtrl,
                              decoration: _dec('Préciser le substrat'),
                              onChanged: (v) {
                                data['env_substratAutre'] = v;
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedProfondeur,
                            isExpanded: true,
                            decoration: _dec("Profondeur"),
                            hint: const Text('Choisir...'),
                            items: _profondeurOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedProfondeur = value);
                              if (value != null) {
                                _profondeurCtrl.text = value;
                                data['env_profondeur'] = value;
                                if (value != 'Autre (préciser)') {
                                  _profondeurAutreCtrl.clear();
                                  data.remove('env_profondeurAutre');
                                }
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              }
                            },
                          ),
                          if (_selectedProfondeur == 'Autre (préciser)') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _profondeurAutreCtrl,
                              decoration: _dec('Préciser la profondeur'),
                              onChanged: (v) {
                                data['env_profondeurAutre'] = v;
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _temperatureCtrl,
                            decoration: _dec("Temp\u00E9rature (\u00B0C)"),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) {
                              data['env_temperature'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _oxygeneCtrl,
                            decoration: _dec("Oxyg\u00E8ne"),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) {
                              data['env_oxygene'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _saliniteCtrl,
                            decoration: _dec("Salinit\u00E9 (psu)"),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) {
                              data['env_salinite'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Pr\u00E9c\u00E9dent',
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
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
          width: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
