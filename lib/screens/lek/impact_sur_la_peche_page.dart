import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'lek_home.dart';
import 'impact_ecologique_page.dart';
import 'adaptation_locale_page.dart';

/// Simple code/label pair used by the dropdowns of this page.
class _OptionItem {
  final String code;
  final String label;
  const _OptionItem(this.code, this.label);
}

class ImpactSurLaPechePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const ImpactSurLaPechePage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<ImpactSurLaPechePage> createState() => _ImpactSurLaPechePageState();
}

class _ImpactSurLaPechePageState extends State<ImpactSurLaPechePage>
    with SingleTickerProviderStateMixin {
  static const List<_OptionItem> _ouiNonOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
  ];

  static const List<_OptionItem> _frequenceOptions = [
    _OptionItem('Jamais', 'Jamais'),
    _OptionItem('Rarement', 'Rarement'),
    _OptionItem('Souvent', 'Souvent'),
  ];

  static const List<_OptionItem> _tendanceCompleteOptions = [
    _OptionItem('Aug', 'Augmentation (Aug)'),
    _OptionItem('Dim', 'Diminution (Dim)'),
    _OptionItem('St', 'Stable (St)'),
    _OptionItem('Var', 'Variable (année(s) clé(s))'),
  ];

  static const List<_OptionItem> _tendanceSimpleOptions = [
    _OptionItem('Aug', 'Augmentation (Aug)'),
    _OptionItem('Dim', 'Diminution (Dim)'),
    _OptionItem('St', 'Stable (St)'),
  ];

  static const List<_OptionItem> _acceptationOptions = [
    _OptionItem('Non', 'Non'),
    _OptionItem('Plus ou moins', 'Plus ou moins'),
    _OptionItem('Bonne', 'Bonne'),
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();
  late AnimationController _waveController;

  // ---- Dégâts / gêne générale
  String? _degatsEngins;
  final TextEditingController _enginPlusImpacteCtrl = TextEditingController();

  String? _degatsPhysiquePecheurOuiNon;
  final TextEditingController _degatsPhysiquePecheurDescriptionCtrl =
      TextEditingController();

  String? _augmentationChargeOuiNon;
  final TextEditingController _augmentationChargeDescriptionCtrl =
      TextEditingController();

  String? _degatsPhysiqueCapturesOuiNon;

  // ---- Evolutions des captures totales
  String? _evolutionCapturesOuiNon;
  String? _evolutionCapturesTendance;
  final TextEditingController _evolutionCapturesTendanceAnneesClesCtrl =
      TextEditingController();
  final TextEditingController _evolutionCapturesDepuisQuandCtrl =
      TextEditingController();
  final TextEditingController _especeDominante1Ctrl = TextEditingController();
  final TextEditingController _especeDominante2Ctrl = TextEditingController();
  final TextEditingController _especeDominante3Ctrl = TextEditingController();

  // ---- Evolution de la catégorie de taille des espèces capturées
  String? _evolutionTailleOuiNon;
  String? _evolutionTailleTendance;
  final TextEditingController _evolutionTailleTendanceAnneesClesCtrl =
      TextEditingController();
  final TextEditingController _evolutionTailleDepuisQuandCtrl =
      TextEditingController();
  final TextEditingController _evolutionTailleZonePlusAffecteeCtrl =
      TextEditingController();
  final TextEditingController _especeAffectee1Ctrl = TextEditingController();
  final TextEditingController _especeAffectee2Ctrl = TextEditingController();
  final TextEditingController _especeAffectee3Ctrl = TextEditingController();

  // ---- Impact sur la rentabilité du pêcheur
  String? _acceptationCrabe;
  String? _tendanceValeur;
  final TextEditingController _tendanceValeurAnneesClesCtrl =
      TextEditingController();

  final TextEditingController _prixVenteConsommateurCtrl =
      TextEditingController();
  final TextEditingController _prixIndustrieCtrl = TextEditingController();
  final TextEditingController _prixIntermediaireCtrl = TextEditingController();
  String? _tendanceRentabilite;
  String? _tendanceChiffreAffaire;
  final TextEditingController _variationChiffreAffaireCtrl =
      TextEditingController();
  String? _tendanceDepenses;
  final TextEditingController _variationDepensesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _degatsEngins = _nullIfEmpty(data['impact_peche_degatsEngins']);
    _enginPlusImpacteCtrl.text =
        (data['impact_peche_enginPlusImpacte'] ?? '').toString();

    _degatsPhysiquePecheurOuiNon =
        _nullIfEmpty(data['impact_peche_degatsPhysiquePecheur_ouiNon']);
    _degatsPhysiquePecheurDescriptionCtrl.text =
        (data['impact_peche_degatsPhysiquePecheur_description'] ?? '').toString();

    _augmentationChargeOuiNon =
        _nullIfEmpty(data['impact_peche_augmentationCharge_ouiNon']);
    _augmentationChargeDescriptionCtrl.text =
        (data['impact_peche_augmentationCharge_description'] ?? '').toString();

    _degatsPhysiqueCapturesOuiNon =
        _nullIfEmpty(data['impact_peche_degatsPhysiqueCaptures_ouiNon']);

    _evolutionCapturesOuiNon =
        _nullIfEmpty(data['impact_peche_evolutionCapturesTotales_ouiNon']);
    _evolutionCapturesTendance =
        _nullIfEmpty(data['impact_peche_evolutionCapturesTotales_tendance']);
    _evolutionCapturesTendanceAnneesClesCtrl.text =
        (data['impact_peche_evolutionCapturesTotales_tendanceAnneesCles'] ?? '')
            .toString();
    _evolutionCapturesDepuisQuandCtrl.text =
        (data['impact_peche_evolutionCapturesTotales_depuisQuand'] ?? '').toString();
    _especeDominante1Ctrl.text =
        (data['impact_peche_evolutionCapturesTotales_espece1'] ?? '').toString();
    _especeDominante2Ctrl.text =
        (data['impact_peche_evolutionCapturesTotales_espece2'] ?? '').toString();
    _especeDominante3Ctrl.text =
        (data['impact_peche_evolutionCapturesTotales_espece3'] ?? '').toString();

    _evolutionTailleOuiNon =
        _nullIfEmpty(data['impact_peche_evolutionTailleEspeces_ouiNon']);
    _evolutionTailleTendance =
        _nullIfEmpty(data['impact_peche_evolutionTailleEspeces_tendance']);
    _evolutionTailleTendanceAnneesClesCtrl.text =
        (data['impact_peche_evolutionTailleEspeces_tendanceAnneesCles'] ?? '')
            .toString();
    _evolutionTailleDepuisQuandCtrl.text =
        (data['impact_peche_evolutionTailleEspeces_depuisQuand'] ?? '').toString();
    _evolutionTailleZonePlusAffecteeCtrl.text =
        (data['impact_peche_evolutionTailleEspeces_zonePlusAffectee'] ?? '')
            .toString();

    _especeAffectee1Ctrl.text =
        (data['impact_peche_evolutionTailleEspeces_espece1_nom'] ?? '').toString();
    _especeAffectee2Ctrl.text =
        (data['impact_peche_evolutionTailleEspeces_espece2_nom'] ?? '').toString();
    _especeAffectee3Ctrl.text =
        (data['impact_peche_evolutionTailleEspeces_espece3_nom'] ?? '').toString();

    // Migration des anciennes données "±" vers "Plus ou moins"
    String? rawAcceptation = _nullIfEmpty(data['impact_peche_acceptationCrabe']);
    if (rawAcceptation == '±') {
      rawAcceptation = 'Plus ou moins';
      _save('impact_peche_acceptationCrabe', 'Plus ou moins');
    }
    _acceptationCrabe = rawAcceptation;

    _tendanceValeur = _nullIfEmpty(data['impact_peche_tendanceValeur']);
    _tendanceValeurAnneesClesCtrl.text =
        (data['impact_peche_tendanceValeurAnneesCles'] ?? '').toString();

    _prixVenteConsommateurCtrl.text =
        (data['impact_peche_prixVenteConsommateur'] ?? '').toString();
    _prixIndustrieCtrl.text = (data['impact_peche_prixIndustrie'] ?? '').toString();
    _prixIntermediaireCtrl.text =
        (data['impact_peche_prixIntermediaireMareyeurs'] ?? '').toString();
    _tendanceRentabilite = _nullIfEmpty(data['impact_peche_tendanceRentabilite']);
    _tendanceChiffreAffaire =
        _nullIfEmpty(data['impact_peche_tendanceChiffreAffaire']);
    _variationChiffreAffaireCtrl.text =
        (data['impact_peche_variationChiffreAffaire'] ?? '').toString();
    _tendanceDepenses = _nullIfEmpty(data['impact_peche_tendanceDepenses']);
    _variationDepensesCtrl.text =
        (data['impact_peche_variationDepenses'] ?? '').toString();

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
    _enginPlusImpacteCtrl.dispose();
    _degatsPhysiquePecheurDescriptionCtrl.dispose();
    _augmentationChargeDescriptionCtrl.dispose();
    _evolutionCapturesTendanceAnneesClesCtrl.dispose();
    _evolutionCapturesDepuisQuandCtrl.dispose();
    _especeDominante1Ctrl.dispose();
    _especeDominante2Ctrl.dispose();
    _especeDominante3Ctrl.dispose();
    _evolutionTailleTendanceAnneesClesCtrl.dispose();
    _evolutionTailleDepuisQuandCtrl.dispose();
    _evolutionTailleZonePlusAffecteeCtrl.dispose();
    _especeAffectee1Ctrl.dispose();
    _especeAffectee2Ctrl.dispose();
    _especeAffectee3Ctrl.dispose();
    _tendanceValeurAnneesClesCtrl.dispose();
    _prixVenteConsommateurCtrl.dispose();
    _prixIndustrieCtrl.dispose();
    _prixIntermediaireCtrl.dispose();
    _variationChiffreAffaireCtrl.dispose();
    _variationDepensesCtrl.dispose();
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
    // Garde-fou : vérifie si la valeur actuelle correspond à l'une des options proposées
    final bool valueExists = value != null && options.any((o) => o.code == value);
    final String? safeValue = valueExists ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: safeValue,
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

  Widget _lightSubHeader(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E7EA),
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

  Widget _plainLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 12);

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 6);
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (_) => AdaptationLocalePage(formId: widget.formId, data: data),
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
                        'Impact sur la pêche',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 6/9',
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
                      // ---- Dégâts / gêne générale
                      _sectionCard(
                        children: [
                          _dropdownField(
                            label: 'Dégâts sur les engins',
                            options: _frequenceOptions,
                            value: _degatsEngins,
                            dataKey: 'impact_peche_degatsEngins',
                            onChanged: (v) => setState(() => _degatsEngins = v),
                            helperText: 'Jamais / Rarement / Souvent',
                          ),
                          if (_degatsEngins != null && _degatsEngins != 'Jamais') ...[
                            _gap(),
                            _textField(
                              controller: _enginPlusImpacteCtrl,
                              label: 'Engin le plus impacté',
                              dataKey: 'impact_peche_enginPlusImpacte',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Dégâts physique sur le pêcheur',
                            options: _ouiNonOptions,
                            value: _degatsPhysiquePecheurOuiNon,
                            dataKey: 'impact_peche_degatsPhysiquePecheur_ouiNon',
                            onChanged: (v) => setState(
                                () => _degatsPhysiquePecheurOuiNon = v),
                            helperText: 'oui / non - si oui, décrire',
                          ),
                          if (_degatsPhysiquePecheurOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _degatsPhysiquePecheurDescriptionCtrl,
                              label: 'Décrire',
                              dataKey: 'impact_peche_degatsPhysiquePecheur_description',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Augmentation de la charge de travail',
                            options: _ouiNonOptions,
                            value: _augmentationChargeOuiNon,
                            dataKey: 'impact_peche_augmentationCharge_ouiNon',
                            onChanged: (v) =>
                                setState(() => _augmentationChargeOuiNon = v),
                            helperText: 'oui / non - si oui, décrire',
                          ),
                          if (_augmentationChargeOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _augmentationChargeDescriptionCtrl,
                              label: 'Décrire',
                              dataKey: 'impact_peche_augmentationCharge_description',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Dégâts physique sur les captures',
                            options: _ouiNonOptions,
                            value: _degatsPhysiqueCapturesOuiNon,
                            dataKey: 'impact_peche_degatsPhysiqueCaptures_ouiNon',
                            onChanged: (v) => setState(
                                () => _degatsPhysiqueCapturesOuiNon = v),
                            helperText: 'oui / non',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Evolutions des captures totales
                      _sectionCard(
                        children: [
                          _subHeader('Evolutions des captures totales'),
                          _dropdownField(
                            label: 'Evolutions des captures totales',
                            options: _ouiNonOptions,
                            value: _evolutionCapturesOuiNon,
                            dataKey: 'impact_peche_evolutionCapturesTotales_ouiNon',
                            onChanged: (v) =>
                                setState(() => _evolutionCapturesOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          if (_evolutionCapturesOuiNon == 'Oui') ...[
                            _gap(),
                            _dropdownField(
                              label: 'Tendance',
                              options: _tendanceCompleteOptions,
                              value: _evolutionCapturesTendance,
                              dataKey: 'impact_peche_evolutionCapturesTotales_tendance',
                              onChanged: (v) =>
                                  setState(() => _evolutionCapturesTendance = v),
                              helperText: 'Aug / Dim / St / Var (année clés)',
                            ),
                            if (_evolutionCapturesTendance == 'Var') ...[
                              _gap(),
                              _textField(
                                controller:
                                    _evolutionCapturesTendanceAnneesClesCtrl,
                                label: 'Année(s) clé(s)',
                                dataKey:
                                    'impact_peche_evolutionCapturesTotales_tendanceAnneesCles',
                              ),
                            ],
                            _gap(),
                            _textField(
                              controller: _evolutionCapturesDepuisQuandCtrl,
                              label: 'Depuis quand',
                              dataKey:
                                  'impact_peche_evolutionCapturesTotales_depuisQuand',
                            ),
                            _plainLabel('Espèces dominantes'),
                            _textField(
                              controller: _especeDominante1Ctrl,
                              label: 'Espèce 1',
                              dataKey: 'impact_peche_evolutionCapturesTotales_espece1',
                              helperText: 'Nom / carte (initiale Sp)',
                            ),
                            _gap(),
                            _textField(
                              controller: _especeDominante2Ctrl,
                              label: 'Espèce 2',
                              dataKey: 'impact_peche_evolutionCapturesTotales_espece2',
                              helperText: 'Nom / carte (initiale Sp)',
                            ),
                            _gap(),
                            _textField(
                              controller: _especeDominante3Ctrl,
                              label: 'Espèce 3',
                              dataKey: 'impact_peche_evolutionCapturesTotales_espece3',
                              helperText: 'Nom / carte (initiale Sp)',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Evolution de la catégorie de taille des espèces
                      _sectionCard(
                        children: [
                          _subHeader(
                              'Evolution de la catégorie de taille des espèces capturées'),
                          _dropdownField(
                            label:
                                'Evolution de la catégorie de taille des espèces capturées',
                            options: _ouiNonOptions,
                            value: _evolutionTailleOuiNon,
                            dataKey: 'impact_peche_evolutionTailleEspeces_ouiNon',
                            onChanged: (v) =>
                                setState(() => _evolutionTailleOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          if (_evolutionTailleOuiNon == 'Oui') ...[
                            _gap(),
                            _dropdownField(
                              label: 'Tendance',
                              options: _tendanceCompleteOptions,
                              value: _evolutionTailleTendance,
                              dataKey: 'impact_peche_evolutionTailleEspeces_tendance',
                              onChanged: (v) =>
                                  setState(() => _evolutionTailleTendance = v),
                              helperText: 'Aug / Dim / St / Var (année clés)',
                            ),
                            if (_evolutionTailleTendance == 'Var') ...[
                              _gap(),
                              _textField(
                                controller: _evolutionTailleTendanceAnneesClesCtrl,
                                label: 'Année(s) clé(s)',
                                dataKey:
                                    'impact_peche_evolutionTailleEspeces_tendanceAnneesCles',
                              ),
                            ],
                            _gap(),
                            _textField(
                              controller: _evolutionTailleDepuisQuandCtrl,
                              label: 'Depuis quand',
                              dataKey: 'impact_peche_evolutionTailleEspeces_depuisQuand',
                            ),
                            _gap(),
                            _textField(
                              controller: _evolutionTailleZonePlusAffecteeCtrl,
                              label: 'Nom de la zone la plus affectée',
                              dataKey:
                                  'impact_peche_evolutionTailleEspeces_zonePlusAffectee',
                            ),
                            _plainLabel('Espèces les plus affectées'),
                            _textField(
                              controller: _especeAffectee1Ctrl,
                              label: 'Espèce 1',
                              dataKey: 'impact_peche_evolutionTailleEspeces_espece1_nom',
                            ),
                            _gap(),
                            _textField(
                              controller: _especeAffectee2Ctrl,
                              label: 'Espèce 2',
                              dataKey: 'impact_peche_evolutionTailleEspeces_espece2_nom',
                            ),
                            _gap(),
                            _textField(
                              controller: _especeAffectee3Ctrl,
                              label: 'Espèce 3',
                              dataKey: 'impact_peche_evolutionTailleEspeces_espece3_nom',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Impact sur la rentabilité du pêcheur
                      _sectionCard(
                        children: [
                          _sectionHeader(
                              'Impact sur la rentabilité du pêcheur durant les cinq dernières années'),
                          _dropdownField(
                            label:
                                'Acceptation du crabe pour la commercialisation',
                            options: _acceptationOptions,
                            value: _acceptationCrabe,
                            dataKey: 'impact_peche_acceptationCrabe',
                            onChanged: (v) =>
                                setState(() => _acceptationCrabe = v),
                            helperText: 'Non / Plus ou moins / Bonne',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Tendance de la valeur',
                            options: _tendanceCompleteOptions,
                            value: _tendanceValeur,
                            dataKey: 'impact_peche_tendanceValeur',
                            onChanged: (v) =>
                                setState(() => _tendanceValeur = v),
                            helperText: 'Aug / Dim / St / Var (année clés)',
                          ),
                          if (_tendanceValeur == 'Var') ...[
                            _gap(),
                            _textField(
                              controller: _tendanceValeurAnneesClesCtrl,
                              label: 'Année(s) clé(s)',
                              dataKey: 'impact_peche_tendanceValeurAnneesCles',
                            ),
                          ],
                          _lightSubHeader('Prix de vente actuel'),
                          _textField(
                            controller: _prixVenteConsommateurCtrl,
                            label: 'Prix vente consommateur',
                            dataKey: 'impact_peche_prixVenteConsommateur',
                            helperText: 'Valeur en DT',
                            numeric: true,
                          ),
                          _gap(),
                          _textField(
                            controller: _prixIndustrieCtrl,
                            label: 'Prix industrie',
                            dataKey: 'impact_peche_prixIndustrie',
                            helperText: 'Valeur en DT',
                            numeric: true,
                          ),
                          _gap(),
                          _textField(
                            controller: _prixIntermediaireCtrl,
                            label: 'Prix intermédiaire (mareyeurs)',
                            dataKey: 'impact_peche_prixIntermediaireMareyeurs',
                            helperText: 'Valeur en DT',
                            numeric: true,
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Tendance de votre rentabilité',
                            options: _tendanceSimpleOptions,
                            value: _tendanceRentabilite,
                            dataKey: 'impact_peche_tendanceRentabilite',
                            onChanged: (v) =>
                                setState(() => _tendanceRentabilite = v),
                            helperText: 'Aug / Dim / St',
                          ),
                          _gap(),
                          _dropdownField(
                            label: "Tendance chiffre d'affaire",
                            options: _tendanceSimpleOptions,
                            value: _tendanceChiffreAffaire,
                            dataKey: 'impact_peche_tendanceChiffreAffaire',
                            onChanged: (v) =>
                                setState(() => _tendanceChiffreAffaire = v),
                            helperText: 'Aug / Dim / St',
                          ),
                          _gap(),
                          _textField(
                            controller: _variationChiffreAffaireCtrl,
                            label: "% variation chiffre d'affaire",
                            dataKey: 'impact_peche_variationChiffreAffaire',
                            helperText: 'Valeur en %',
                            numeric: true,
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Tendance des dépenses',
                            options: _tendanceSimpleOptions,
                            value: _tendanceDepenses,
                            dataKey: 'impact_peche_tendanceDepenses',
                            onChanged: (v) =>
                                setState(() => _tendanceDepenses = v),
                            helperText: 'Aug / Dim / St',
                          ),
                          _gap(),
                          _textField(
                            controller: _variationDepensesCtrl,
                            label: '% variations des dépenses',
                            dataKey: 'impact_peche_variationDepenses',
                            helperText: 'Valeur en %',
                            numeric: true,
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
                                _service.updateFormData(widget.formId, data, stepCompleted: 5);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImpactEcologiquePage(formId: widget.formId, data: data),
                                  ),
                                );
                              },
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