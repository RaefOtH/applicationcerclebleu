import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'impact_ecologique_page.dart';
import 'lek_home.dart';
import 'unite_de_peche_page.dart';

class _OptionItem {
  final String code;
  final String label;
  const _OptionItem(this.code, this.label);
}

class _EspeceControllers {
  final String prefix;

  final anneeCtrl = TextEditingController();
  final environnementCtrl = TextEditingController();
  final distApparitionCtrl = TextEditingController();
  final distActuelleCtrl = TextEditingController();
  final profondeurCtrl = TextEditingController();
  final zonesSensiblesCtrl = TextEditingController();
  final tailleMoyenneCtrl = TextEditingController();
  final zonePlusAffecteeCtrl = TextEditingController();
  final abondanceAnneesClesCtrl = TextEditingController();
  final tendanceAnneesClesCtrl = TextEditingController();

  String? typeFond;
  String? abondance5ans;
  List<String> saisonForteAbondance = [];
  List<String> saisonReproduction = [];
  List<String> presenceJuveniles = [];
  String? evolutionQuantites;
  String? tendance;

  _EspeceControllers(this.prefix);

  void loadFrom(Map<String, dynamic> data) {
    anneeCtrl.text = (data['${prefix}_annee1ereObservation'] ?? '').toString();
    environnementCtrl.text = (data['${prefix}_environnement'] ?? '').toString();
    distApparitionCtrl.text = (data['${prefix}_distributionApparition'] ?? '').toString();
    distActuelleCtrl.text = (data['${prefix}_distributionActuelle'] ?? '').toString();
    profondeurCtrl.text = (data['${prefix}_profondeur'] ?? '').toString();
    zonesSensiblesCtrl.text = (data['${prefix}_zonesSensibles'] ?? '').toString();
    tailleMoyenneCtrl.text = (data['${prefix}_tailleMoyenne'] ?? '').toString();
    zonePlusAffecteeCtrl.text = (data['${prefix}_zonePlusAffectee'] ?? '').toString();
    abondanceAnneesClesCtrl.text = (data['${prefix}_abondanceAnneesCles'] ?? '').toString();
    tendanceAnneesClesCtrl.text = (data['${prefix}_tendanceAnneesCles'] ?? '').toString();

    typeFond = _nullIfEmpty(data['${prefix}_typeFond']);
    abondance5ans = _nullIfEmpty(data['${prefix}_abondance5ans']);
    saisonForteAbondance = _listFromCsv(data['${prefix}_saisonForteAbondance']);
    saisonReproduction = _listFromCsv(data['${prefix}_saisonReproduction']);
    presenceJuveniles = _listFromCsv(data['${prefix}_presenceJuveniles']);
    evolutionQuantites = _nullIfEmpty(data['${prefix}_evolutionQuantites']);
    tendance = _nullIfEmpty(data['${prefix}_tendance']);
  }

  static String? _nullIfEmpty(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  static List<String> _listFromCsv(dynamic v) {
    final str = (v ?? '').toString().trim();
    if (str.isEmpty) return [];
    return str.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void dispose() {
    anneeCtrl.dispose();
    environnementCtrl.dispose();
    distApparitionCtrl.dispose();
    distActuelleCtrl.dispose();
    profondeurCtrl.dispose();
    zonesSensiblesCtrl.dispose();
    tailleMoyenneCtrl.dispose();
    zonePlusAffecteeCtrl.dispose();
    abondanceAnneesClesCtrl.dispose();
    tendanceAnneesClesCtrl.dispose();
  }
}

class DynamiqueDuCrabePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const DynamiqueDuCrabePage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<DynamiqueDuCrabePage> createState() => _DynamiqueDuCrabePageState();
}

class _DynamiqueDuCrabePageState extends State<DynamiqueDuCrabePage>
    with SingleTickerProviderStateMixin {
  static const List<_OptionItem> _ouiNonOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
  ];

  static const List<_OptionItem> _typeFondOptions = [
    _OptionItem('S', 'Sable (S)'),
    _OptionItem('V', 'Vase (V)'),
    _OptionItem('R', 'Roche (R)'),
    _OptionItem('H', 'Herbier (H)'),
  ];

  static const List<_OptionItem> _saisonOptions = [
    _OptionItem('H', 'Hiver (H)'),
    _OptionItem('P', 'Printemps (P)'),
    _OptionItem('E', 'Été (E)'),
    _OptionItem('A', 'Automne (A)'),
  ];

  static const List<_OptionItem> _tendanceOptions = [
    _OptionItem('Aug', 'Augmentation (Aug)'),
    _OptionItem('Dim', 'Diminution (Dim)'),
    _OptionItem('St', 'Stable (St)'),
    _OptionItem('Var', 'Variable (année(s) clé(s))'),
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();

  late final _EspeceControllers _sapidus = _EspeceControllers('dynamique_crabe_sapidus');
  late final _EspeceControllers _segnis = _EspeceControllers('dynamique_crabe_segnis');
  late final _EspeceControllers _confondues = _EspeceControllers('dynamique_crabe_confondues');

  String? _distinction2Especes;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _distinction2Especes = _EspeceControllers._nullIfEmpty(data['dynamique_crabe_distinction2Especes']);
    _sapidus.loadFrom(data);
    _segnis.loadFrom(data);
    _confondues.loadFrom(data);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sapidus.dispose();
    _segnis.dispose();
    _confondues.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _save(String key, String value) {
    data[key] = value;
    _service.scheduleFullDataSave(widget.formId, data);
  }

  InputDecoration _dec(String label, {String? helperText}) => InputDecoration(
        labelText: label,
        hintText: 'Saisir ici...',
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String dataKey,
    String? helperText,
    bool numeric = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _dec(label, helperText: helperText),
      onChanged: (v) => _save(dataKey, v),
    );
  }

  Widget _dropdownField({
    required String label,
    required List<_OptionItem> options,
    required String? value,
    required String dataKey,
    required ValueChanged<String?> onChanged,
    String? helperText,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _dec(label, helperText: helperText),
      hint: const Text('Choisir...'),
      items: options
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.code,
              child: Text(o.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        onChanged(v);
        _save(dataKey, v ?? '');
      },
    );
  }

  Widget _multiSelectField({
    required String label,
    required List<_OptionItem> options,
    required List<String> selectedValues,
    required String dataKey,
    required ValueChanged<List<String>> onChanged,
    String? helperText,
  }) {
    final displayText = selectedValues.isEmpty
        ? 'Choisir...'
        : options
            .where((o) => selectedValues.contains(o.code))
            .map((o) => o.code)
            .join(', ');

    return InkWell(
      onTap: () async {
        final List<String> tempSelected = List.from(selectedValues);
        final result = await showDialog<List<String>>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: options.map((option) {
                        final isChecked = tempSelected.contains(option.code);
                        return CheckboxListTile(
                          title: Text(option.label),
                          value: isChecked,
                          activeColor: const Color(0xFF00D9D9),
                          onChanged: (bool? checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelected.add(option.code);
                              } else {
                                tempSelected.remove(option.code);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, null),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D9D9),
                      ),
                      onPressed: () => Navigator.pop(context, tempSelected),
                      child: const Text(
                        'Valider',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );

        if (result != null) {
          onChanged(result);
          _save(dataKey, result.join(', '));
        }
      },
      child: InputDecorator(
        decoration: _dec(label, helperText: helperText),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: selectedValues.isEmpty
                      ? const Color(0xFF94A3B8)
                      : Colors.black87,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Color(0xFF1E3A8A)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF52565C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _subHeader(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFDCDEE2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  Widget _buildEspeceSection({
    required String sectionTitle,
    required String evolutionLabel,
    required _EspeceControllers c,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(sectionTitle),
          _textField(
            controller: c.anneeCtrl,
            label: 'Année 1ère observation',
            dataKey: '${c.prefix}_annee1ereObservation',
          ),
          _gap(),
          _textField(
            controller: c.environnementCtrl,
            label: 'Environnement (T°, S%, saison..)',
            dataKey: '${c.prefix}_environnement',
          ),
          _gap(),
          _textField(
            controller: c.distApparitionCtrl,
            label: "Distribution à l'apparition",
            dataKey: '${c.prefix}_distributionApparition',
            helperText: 'Zone (carte vert pointillée)',
          ),
          _gap(),
          _textField(
            controller: c.distActuelleCtrl,
            label: 'Distribution actuelle',
            dataKey: '${c.prefix}_distributionActuelle',
            helperText: 'Zone (carte vert continu)',
          ),
          _gap(),
          _textField(
            controller: c.profondeurCtrl,
            label: 'Profondeur',
            dataKey: '${c.prefix}_profondeur',
            numeric: true,
          ),
          _gap(),
          _dropdownField(
            label: 'Type de fond',
            options: _typeFondOptions,
            value: c.typeFond,
            dataKey: '${c.prefix}_typeFond',
            onChanged: (v) => setState(() => c.typeFond = v),
            helperText: 'S / V / R / H',
          ),
          _gap(),
          _textField(
            controller: c.zonesSensiblesCtrl,
            label: 'Zones sensibles à proximité',
            dataKey: '${c.prefix}_zonesSensibles',
            helperText: 'AMP, herbiers, nurseries, etc.',
          ),
          _gap(),
          _dropdownField(
            label: 'Abondance depuis les 5 dernières années',
            options: _tendanceOptions,
            value: c.abondance5ans,
            dataKey: '${c.prefix}_abondance5ans',
            onChanged: (v) => setState(() => c.abondance5ans = v),
            helperText: 'Aug / Dim / St / Var (année clés)',
          ),
          if (c.abondance5ans == 'Var') ...[
            _gap(),
            _textField(
              controller: c.abondanceAnneesClesCtrl,
              label: 'Année(s) clé(s)',
              dataKey: '${c.prefix}_abondanceAnneesCles',
            ),
          ],
          _gap(),
          _multiSelectField(
            label: 'Saison de plus forte abondance',
            options: _saisonOptions,
            selectedValues: c.saisonForteAbondance,
            dataKey: '${c.prefix}_saisonForteAbondance',
            onChanged: (v) => setState(() => c.saisonForteAbondance = v),
            helperText: 'H / P / E / A (Choix multiples)',
          ),
          _gap(),
          _multiSelectField(
            label: 'Saison de reproduction',
            options: _saisonOptions,
            selectedValues: c.saisonReproduction,
            dataKey: '${c.prefix}_saisonReproduction',
            onChanged: (v) => setState(() => c.saisonReproduction = v),
            helperText: 'H / P / E / A (Choix multiples)',
          ),
          _gap(),
          _multiSelectField(
            label: 'Présence de juvéniles',
            options: _saisonOptions,
            selectedValues: c.presenceJuveniles,
            dataKey: '${c.prefix}_presenceJuveniles',
            onChanged: (v) => setState(() => c.presenceJuveniles = v),
            helperText: 'H / P / E / A (Choix multiples)',
          ),
          _gap(),
          _textField(
            controller: c.tailleMoyenneCtrl,
            label: 'Taille moyenne observée',
            dataKey: '${c.prefix}_tailleMoyenne',
            helperText: 'en cm',
            numeric: true,
          ),
          _subHeader(evolutionLabel),
          _dropdownField(
            label: 'Evolution des quantités capturées',
            options: _ouiNonOptions,
            value: c.evolutionQuantites,
            dataKey: '${c.prefix}_evolutionQuantites',
            onChanged: (v) => setState(() => c.evolutionQuantites = v),
            helperText: 'oui / non',
          ),
          if (c.evolutionQuantites == 'Oui') ...[
            _gap(),
            _dropdownField(
              label: 'Tendance',
              options: _tendanceOptions,
              value: c.tendance,
              dataKey: '${c.prefix}_tendance',
              onChanged: (v) => setState(() => c.tendance = v),
              helperText: 'Aug / Dim / St / Var (année clés)',
            ),
            if (c.tendance == 'Var') ...[
              _gap(),
              _textField(
                controller: c.tendanceAnneesClesCtrl,
                label: 'Année(s) clé(s)',
                dataKey: '${c.prefix}_tendanceAnneesCles',
              ),
            ],
            _gap(),
            _textField(
              controller: c.zonePlusAffecteeCtrl,
              label: 'Zone la plus affectée',
              dataKey: '${c.prefix}_zonePlusAffectee',
              helperText: 'Nom / carte',
            ),
          ],
        ],
      ),
    );
  }

  void _goNext() {
    data['dynamique_crabe_distinction2Especes'] = _distinction2Especes ?? '';
    _service.updateFormData(widget.formId, data, stepCompleted: 4);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImpactEcologiquePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goBack() {
    _service.updateFormData(widget.formId, data, stepCompleted: 3);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniteDePechePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToLekHome() {
    _service.updateFormData(widget.formId, data, stepCompleted: 4);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LekHome(formId: widget.formId)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showBothSpecies = _distinction2Especes != 'Non';

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
                        'Dynamique du crabe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 4/9',
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
                          const Text(
                            'Dynamique du crabe (photos des deux espèces)',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _dropdownField(
                            label: 'Distinction entre les 2 espèces',
                            options: _ouiNonOptions,
                            value: _distinction2Especes,
                            dataKey: 'dynamique_crabe_distinction2Especes',
                            onChanged: (v) => setState(() => _distinction2Especes = v),
                            helperText: 'oui / non : si non passer à a.3',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _sectionCard(
                        children: [
                          if (showBothSpecies) ...[
                            _buildEspeceSection(
                              sectionTitle: 'a-1 C. Sapidus',
                              evolutionLabel:
                                  'a-1-1-Evolution des quantités capturées de crabe durant les 5 dernières années',
                              c: _sapidus,
                            ),
                            _buildEspeceSection(
                              sectionTitle: 'a-2 P. segis',
                              evolutionLabel:
                                  'a-2-1-Evolution des quantités capturées de crabe durant les 5 dernières années',
                              c: _segnis,
                            ),
                          ],
                          _buildEspeceSection(
                            sectionTitle: 'a-3 Les 2 espèces conf',
                            evolutionLabel:
                                'a-3-1-Evolution des quantités capturées de crabe durant les 5 dernières années',
                            c: _confondues,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Précédent',
                              icon: Icons.arrow_back,
                              onPressed: _goBack,
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
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