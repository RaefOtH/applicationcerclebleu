import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'matrice1_home.dart';
import 'variables_environnementales_page.dart';

class CapturePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const CapturePage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage>
    with SingleTickerProviderStateMixin {
  static const List<String> _especeOptions = [
    'Belone belone',
    'Squatina squatina',
    'Anguilla anguilla',
    'Mugil sp',
    'Balistes capriscus',
    'Lophius piscatorius',
    'Liza aurata',
    'Liza aurata',
    'Hexaplex trunculus',
    'Boops boops',
    'Eledone sp',
    'sphyraena sp',
    'Loligo vulgaris',
    'Parapenaeus longirostris',
    'Squalus acanthias',
    'Conger conger',
    'Coryphaena hippurus',
    'Portunus segnis',
    'metapenaeus monoceros',
    'Ariesteomorpha foliacea',
    'Melicertus kerathurus',
    'Sparus aurata',
    'Dentex dentex',
    'Chelidonichthys lucerna',
    'Labrus merula',
    'Lichia amia',
    'Limanda limanda',
    'Dicentrachus labrax',
    'Scomber scombrus',
    'Lithognathus mormyrus',
    'Merluccius merluccius',
    'Epinephlus sp',
    'Mugil cephalus',
    'Mugil cephalus',
    'Oblada melanura',
    'Umbrina canariensis',
    'Pagellus erythrinus',
    'Pagrus pagrus',
    'Octopus vulgaris',
    'Raja sp',
    'Scorpaena scrofa',
    'Mullus barbatus',
    'Mullus surmuletus',
    'Scyliorhinus stellaris',
    'Zeus faber',
    'Sardina pilchardus',
    'sardinella aurita',
    'Diplodus sargus',
    'Sarpa salpa',
    'Trachurus sp',
    'Sepia officinalis',
    'Seriola dumerili',
    'Serranus cabrilla',
    'Pomatomus saltatrix',
    'Solea sp',
    'Diplodus vulgaris',
    'spicara maena',
    'Trachinus draco',
    'Portunus segnis',
    'Callinectes sapidus',
  ];

  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _nomCommunCtrl = TextEditingController();
  final _especeCtrl = TextEditingController();
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
    _abondanceCtrl.dispose();
    _poidsCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        hintText: 'Saisir ici...',
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
        ),
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
    final index = _especeOptions.indexOf(value);
    if (index < 0) return null;
    return index.toString();
  }

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 3);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VariablesEnvironnementalesPage(
          formId: widget.formId,
          data: data,
        ),
      ),
    );
  }

  void _goToTerrainHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Matrice1Home(formId: widget.formId),
      ),
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
                          controller: _nomCommunCtrl,
                          decoration: _dec("Nom commun/Local"),
                          onChanged: (v) {
                            data['cap_nomCommun'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEspeceKey,
                          isExpanded: true,
                          decoration: _dec("Esp\u00E8ce (nom scientifique)"),
                          hint: const Text('Choisir...'),
                          items: List.generate(_especeOptions.length, (index) {
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
                            data['cap_espece'] = selected;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _abondanceCtrl,
                          decoration: _dec("Abondance (n)"),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            data['cap_abondance'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _poidsCtrl,
                          decoration: _dec("Poids total (g)"),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            data['cap_poidsTotal'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                      ]),
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
