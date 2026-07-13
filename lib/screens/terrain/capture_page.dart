import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'matrice1_home.dart';
import 'variables_environnementales_page.dart';

class CapturePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const CapturePage({super.key, required this.data, required this.formId});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage>
    with SingleTickerProviderStateMixin {
  static const List<String> _rawEspeceOptions = [
    'Anguilla anguilla',
    'Ariesteomorpha foliacea',
    'Balistes capriscus',
    'Belone belone',
    'Boops boops',
    'Callinectes sapidus',
    'Chelidonichthys lucerna',
    'Conger conger',
    'Coryphaena hippurus',
    'Dentex dentex',
    'Dicentrachus labrax',
    'Diplodus sargus',
    'Diplodus vulgaris',
    'Eledone sp',
    'Engraulis encrasicolus',
    'Epinephlus sp',
    'Hexaplex trunculus',
    'Labrus merula',
    'Lichia amia',
    'Limanda limanda',
    'Lithognathus mormyrus',
    'Liza aurata',
    'Loligo vulgaris',
    'Lophius piscatorius',
    'Melicertus kerathurus',
    'Merluccius merluccius',
    'metapenaeus monoceros',
    'Mugil cephalus',
    'Mugil sp',
    'Mullus barbatus',
    'Mullus surmuletus',
    'Oblada melanura',
    'Octopus vulgaris',
    'Pagellus erythrinus',
    'Pagrus pagrus',
    'Parapenaeus longirostris',
    'Penaeus Kerathurus',
    'Pomatomus saltatrix',
    'Portunus segnis',
    'Raja sp',
    'Sardina pilchardus',
    'sardinella aurita',
    'Sarpa salpa',
    'Scomber scombrus',
    'Scorpaena scrofa',
    'Scyliorhinus stellaris',
    'Sepia officinalis',
    'Seriola dumerili',
    'Serranus cabrilla',
    'Solea sp',
    'Sparus aurata',
    'sphyraena sp',
    'spicara maena',
    'Squalus acanthias',
    'Squatina squatina',
    'Trachinus draco',
    'Trachurus sp',
    'Umbrina canariensis',
    'Zeus faber',
    'Autre (préciser)',
  ];
  static final List<String> _especeOptions = () {
    final unique = <String, String>{};
    for (final raw in _rawEspeceOptions) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      unique.putIfAbsent(value.toLowerCase(), () => value);
    }
    final result = unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }();

  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _nomCommunCtrl = TextEditingController();
  final _especeCtrl = TextEditingController();
  final _especeAutreCtrl = TextEditingController();
  final _abondanceCtrl = TextEditingController();
  final _poidsCtrl = TextEditingController();
  String? _selectedEspeceKey;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _nomCommunCtrl.text = (data['cap_nomCommun'] ?? '').toString();
    _especeCtrl.text = (data['cap_espece'] ?? '').toString();
    _especeAutreCtrl.text = (data['cap_especeAutre'] ?? '').toString();
    _abondanceCtrl.text = (data['cap_abondance'] ?? '').toString();
    _poidsCtrl.text = (data['cap_poidsTotal'] ?? '').toString();
    _selectedEspeceKey = _resolveEspeceKey(data['cap_espece']);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _nomCommunCtrl.dispose();
    _especeCtrl.dispose();
    _especeAutreCtrl.dispose();
    _abondanceCtrl.dispose();
    _poidsCtrl.dispose();
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

  String? _resolveEspeceKey(dynamic rawValue) {
    final value = (rawValue ?? '').toString().trim();
    if (value.isEmpty) return null;
    final target = value == 'Autre' ? 'Autre (préciser)' : value;
    final index = _especeOptions.indexOf(target);
    if (index < 0) return null;
    return index.toString();
  }

  void _goNext() {
    final selectedEspece = data['cap_espece']?.toString() ?? '';
    if (selectedEspece == 'Autre' && _especeAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez préciser l'espèce.")),
      );
      return;
    }
    _service.updateFormData(widget.formId, data, stepCompleted: 3);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VariablesEnvironnementalesPage(formId: widget.formId, data: data),
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
                      const Text(
                        'Capture',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u00C9tape 3/5',
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
                            controller: _nomCommunCtrl,
                            decoration: _dec("Nom commun/Local"),
                            onChanged: (v) {
                              data['cap_nomCommun'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedEspeceKey,
                            isExpanded: true,
                            decoration: _dec("Esp\u00E8ce (nom scientifique)"),
                            hint: const Text('Choisir...'),
                            items: List.generate(_especeOptions.length, (
                              index,
                            ) {
                              final label = _especeOptions[index];
                              return DropdownMenuItem<String>(
                                value: index.toString(),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            onChanged: (key) {
                              setState(() => _selectedEspeceKey = key);
                              if (key == null) return;
                              final selected = _especeOptions[int.parse(key)];
                              _especeCtrl.text = selected;
                              if (selected == 'Autre (préciser)') {
                                data['cap_espece'] = 'Autre';
                              } else {
                                data['cap_espece'] = selected;
                                _especeAutreCtrl.clear();
                                data.remove('cap_especeAutre');
                              }
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          if ((data['cap_espece'] ?? '').toString() ==
                              'Autre') ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _especeAutreCtrl,
                              decoration: _dec("Préciser l'espèce"),
                              onChanged: (v) {
                                data['cap_especeAutre'] = v;
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _abondanceCtrl,
                            decoration: _dec("Abondance (n)"),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              data['cap_abondance'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _poidsCtrl,
                            decoration: _dec("Poids total (g)"),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              data['cap_poidsTotal'] = v;
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
