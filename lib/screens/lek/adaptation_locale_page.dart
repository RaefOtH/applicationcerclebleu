import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'lek_home.dart';

import 'impact_sur_la_peche_page.dart';
import 'etat_des_lieux_page.dart';

/// Simple code/label pair used by the dropdowns of this page.
class _OptionItem {
  final String code;
  final String label;
  const _OptionItem(this.code, this.label);
}

class AdaptationLocalePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const AdaptationLocalePage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<AdaptationLocalePage> createState() => _AdaptationLocalePageState();
}

class _AdaptationLocalePageState extends State<AdaptationLocalePage>
    with SingleTickerProviderStateMixin {
  static const List<_OptionItem> _ouiNonOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
  ];

  static const List<_OptionItem> _saisonOptions = [
    _OptionItem('H', 'Hiver (H)'),
    _OptionItem('P', 'Printemps (P)'),
    _OptionItem('E', 'Été (E)'),
    _OptionItem('A', 'Automne (A)'),
  ];

  static const List<_OptionItem> _efficaciteOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Partiellement', 'Partiellement'),
    _OptionItem('Non', 'Non'),
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();
  late AnimationController _waveController;

  // ---- Modification des pratiques de pêche
  String? _modificationPratiques;

  // ---- Types d'adaptations (plusieurs possibles)
  final TextEditingController _modificationEnginsCtrl = TextEditingController();
  final TextEditingController _typeModificationEnginsCtrl =
      TextEditingController();
  String? _enginsHorsUsageOuiNon;
  final TextEditingController _enginsHorsUsageNomCtrl = TextEditingController();
  final TextEditingController _nouveauxEnginsCtrl = TextEditingController();
  final TextEditingController _changementZoneCtrl = TextEditingController();

  // ---- Changement du calendrier de pêche
  String? _changementCalendrierOuiNon;
  final TextEditingController _especesCiblesCtrl = TextEditingController();
  String? _saisonPeche;
  final TextEditingController _autresPreciserCtrl = TextEditingController();

  // ---- Efficacité des adaptations
  String? _efficaciteAdaptations;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _modificationPratiques =
        _nullIfEmpty(data['adaptation_modificationPratiques']);

    _modificationEnginsCtrl.text =
        (data['adaptation_modificationEngins'] ?? '').toString();
    _typeModificationEnginsCtrl.text =
        (data['adaptation_typeModificationEngins'] ?? '').toString();
    _enginsHorsUsageOuiNon =
        _nullIfEmpty(data['adaptation_enginsHorsUsage_ouiNon']);
    _enginsHorsUsageNomCtrl.text =
        (data['adaptation_enginsHorsUsage_nom'] ?? '').toString();
    _nouveauxEnginsCtrl.text =
        (data['adaptation_nouveauxEngins'] ?? '').toString();
    _changementZoneCtrl.text =
        (data['adaptation_changementZone'] ?? '').toString();

    _changementCalendrierOuiNon =
        _nullIfEmpty(data['adaptation_changementCalendrier_ouiNon']);
    _especesCiblesCtrl.text = (data['adaptation_especesCibles'] ?? '').toString();
    _saisonPeche = _nullIfEmpty(data['adaptation_saisonPeche']);
    _autresPreciserCtrl.text =
        (data['adaptation_autresPreciser'] ?? '').toString();

    _efficaciteAdaptations = _nullIfEmpty(data['adaptation_efficacite']);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  static String? _nullIfEmpty(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  void dispose() {
    _modificationEnginsCtrl.dispose();
    _typeModificationEnginsCtrl.dispose();
    _enginsHorsUsageNomCtrl.dispose();
    _nouveauxEnginsCtrl.dispose();
    _changementZoneCtrl.dispose();
    _especesCiblesCtrl.dispose();
    _autresPreciserCtrl.dispose();
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
    bool multiline = false,
  }) {
    return TextFormField(
      controller: controller,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 5 : 1,
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

  // ---- Header bars matching the dark / gray rows of the Excel sheet.

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
        color: const Color(0xFFC7CACF),
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

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 5);
    // TODO: navigate to whatever step follows "adaptation locale" in your
    // flow, e.g.:
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => EtatDesLieuxPage(formId: widget.formId, data: data),
    ));
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
                        'Adaptation locale',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 7/9',
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
                      // ---- Modification des pratiques de pêche
                      _sectionCard(
                        children: [
                          _dropdownField(
                            label: 'Modification des pratiques de pêche',
                            options: _ouiNonOptions,
                            value: _modificationPratiques,
                            dataKey: 'adaptation_modificationPratiques',
                            onChanged: (v) =>
                                setState(() => _modificationPratiques = v),
                            helperText: 'oui / non',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Types d'adaptations (plusieurs possibles)
                      _sectionCard(
                        children: [
                          _subHeader("Types d'adaptations (plusieurs possibles)"),
                          _textField(
                            controller: _modificationEnginsCtrl,
                            label: 'Modification engins',
                            dataKey: 'adaptation_modificationEngins',
                            helperText: 'Nom (code) engin',
                          ),
                          _gap(),
                          _textField(
                            controller: _typeModificationEnginsCtrl,
                            label: 'Type de modification engins',
                            dataKey: 'adaptation_typeModificationEngins',
                            helperText:
                                'Préciser (maillage, nature de filet, longueur, etc.)',
                          ),
                          _gap(),
                          _dropdownField(
                            label: "Engins mis hors d'usage",
                            options: _ouiNonOptions,
                            value: _enginsHorsUsageOuiNon,
                            dataKey: 'adaptation_enginsHorsUsage_ouiNon',
                            onChanged: (v) =>
                                setState(() => _enginsHorsUsageOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          if (_enginsHorsUsageOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _enginsHorsUsageNomCtrl,
                              label: 'Nom (code)',
                              dataKey: 'adaptation_enginsHorsUsage_nom',
                            ),
                          ],
                          _gap(),
                          _textField(
                            controller: _nouveauxEnginsCtrl,
                            label: 'Nouveaux engins',
                            dataKey: 'adaptation_nouveauxEngins',
                            helperText: 'Nom (code)',
                          ),
                          _gap(),
                          _textField(
                            controller: _changementZoneCtrl,
                            label: 'Changement de zone',
                            dataKey: 'adaptation_changementZone',
                            helperText: 'Nom / carte',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Changement du calendrier de pêche
                      _sectionCard(
                        children: [
                          _sectionHeader('Changement du calendrier de pêche'),
                          _dropdownField(
                            label: 'Changement du calendrier de pêche',
                            options: _ouiNonOptions,
                            value: _changementCalendrierOuiNon,
                            dataKey: 'adaptation_changementCalendrier_ouiNon',
                            onChanged: (v) => setState(
                                () => _changementCalendrierOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          _gap(),
                          _textField(
                            controller: _especesCiblesCtrl,
                            label: 'Espèces cibles',
                            dataKey: 'adaptation_especesCibles',
                            helperText: 'Nom',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Saison de pêche',
                            options: _saisonOptions,
                            value: _saisonPeche,
                            dataKey: 'adaptation_saisonPeche',
                            onChanged: (v) => setState(() => _saisonPeche = v),
                            helperText: 'H / P / E / A',
                          ),
                          _gap(),
                          _textField(
                            controller: _autresPreciserCtrl,
                            label: 'Autres à préciser',
                            dataKey: 'adaptation_autresPreciser',
                            helperText: 'détail',
                            multiline: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Efficacité des adaptations
                      _sectionCard(
                        children: [
                          _dropdownField(
                            label: 'Efficacité des adaptations',
                            options: _efficaciteOptions,
                            value: _efficaciteAdaptations,
                            dataKey: 'adaptation_efficacite',
                            onChanged: (v) =>
                                setState(() => _efficaciteAdaptations = v),
                            helperText: 'Oui / Partiellement / Non',
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
                              onPressed: () {
                                    _service.updateFormData(widget.formId, data, stepCompleted: 2);
                                    Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ImpactSurLaPechePage(formId: widget.formId, data:data),
                                      ),
                                   );}
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