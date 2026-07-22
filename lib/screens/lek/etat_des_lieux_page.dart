import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'adaptation_locale_page.dart';
import 'lek_home.dart';
import 'niveau_de_confiance_page.dart';

class _OptionItem {
  final String code;
  final String label;
  const _OptionItem(this.code, this.label);
}

class EtatDesLieuxPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const EtatDesLieuxPage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<EtatDesLieuxPage> createState() => _EtatDesLieuxPageState();
}

class _EtatDesLieuxPageState extends State<EtatDesLieuxPage>
    with SingleTickerProviderStateMixin {
  static const List<_OptionItem> _ouiNonOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
  ];

  static const List<_OptionItem> _perceptionOptions = [
    _OptionItem('Nuisance', 'Nuisance'),
    _OptionItem('Ressource', 'Ressource'),
    _OptionItem('LesDeux', 'Les deux'),
  ];

  static const List<_OptionItem> _etatGestionOptions = [
    _OptionItem('Bonne', 'Bonne'),
    _OptionItem('plus ou moins', 'plus ou moins'),
    _OptionItem('Inexistante', 'Inexistante'),
  ];

  static const List<_OptionItem> _interetOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
    _OptionItem('Indifferent', 'Indifférent'),
  ];

  static const List<_OptionItem> _etatMilieuOptions = [
    _OptionItem('Bon', 'Bon'),
    _OptionItem('plus ou moins', 'plus ou moins'),
    _OptionItem('Mauvais', 'Mauvais'),
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();
  late AnimationController _waveController;

  String? _perceptionCrabe;
  String? _etatGestionCrabe;
  String? _interetImplicationGestion;

  String? _affiliationOuiNon;
  final TextEditingController _affiliationTypeCtrl = TextEditingController();

  String? _reglementationAdequate;

  final TextEditingController _mesuresGestionProposeesCtrl = TextEditingController();

  String? _bloomsOuiNon;
  final TextEditingController _bloomsAnneeCtrl = TextEditingController();

  String? _pollutionsOuiNon;
  final TextEditingController _pollutionsTypeCtrl = TextEditingController();

  String? _etatMilieuEaux;
  String? _etatFond;

  String? _problemesCommercialisationOuiNon;
  final TextEditingController _problemesCommercialisationPreciserCtrl = TextEditingController();

  final TextEditingController _principalProblemeCtrl = TextEditingController();
  final TextEditingController _suggestionAmeliorationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _perceptionCrabe = _nullIfEmpty(data['etatlieux_perceptionCrabe']);
    _etatGestionCrabe = _nullIfEmpty(data['etatlieux_etatGestionCrabe']);
    _interetImplicationGestion = _nullIfEmpty(data['etatlieux_interetImplicationGestion']);

    _affiliationOuiNon = _nullIfEmpty(data['etatlieux_affiliation_ouiNon']);
    _affiliationTypeCtrl.text = (data['etatlieux_affiliation_type'] ?? '').toString();

    _reglementationAdequate = _nullIfEmpty(data['etatlieux_reglementationAdequate']);

    _mesuresGestionProposeesCtrl.text = (data['etatlieux_mesuresGestionProposees'] ?? '').toString();

    _bloomsOuiNon = _nullIfEmpty(data['etatlieux_blooms_ouiNon']);
    _bloomsAnneeCtrl.text = (data['etatlieux_blooms_annee'] ?? '').toString();

    _pollutionsOuiNon = _nullIfEmpty(data['etatlieux_pollutions_ouiNon']);
    _pollutionsTypeCtrl.text = (data['etatlieux_pollutions_type'] ?? '').toString();

    _etatMilieuEaux = _nullIfEmpty(data['etatlieux_etatMilieuEaux']);
    _etatFond = _nullIfEmpty(data['etatlieux_etatFond']);

    _problemesCommercialisationOuiNon =
        _nullIfEmpty(data['etatlieux_problemesCommercialisation_ouiNon']);
    _problemesCommercialisationPreciserCtrl.text =
        (data['etatlieux_problemesCommercialisation_preciser'] ?? '').toString();

    _principalProblemeCtrl.text = (data['etatlieux_principalProbleme'] ?? '').toString();
    _suggestionAmeliorationCtrl.text = (data['etatlieux_suggestionAmelioration'] ?? '').toString();

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
    _affiliationTypeCtrl.dispose();
    _mesuresGestionProposeesCtrl.dispose();
    _bloomsAnneeCtrl.dispose();
    _pollutionsTypeCtrl.dispose();
    _problemesCommercialisationPreciserCtrl.dispose();
    _principalProblemeCtrl.dispose();
    _suggestionAmeliorationCtrl.dispose();
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

  Widget _gap() => const SizedBox(height: 12);

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 8);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NiveauDeConfiancePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goBack() {
    _service.updateFormData(widget.formId, data, stepCompleted: 7);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdaptationLocalePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToLekHome() {
    _service.updateFormData(widget.formId, data, stepCompleted: 8);
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
                        'Etat des lieux',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 8/9',
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
                          _dropdownField(
                            label: 'Perception de crabe',
                            options: _perceptionOptions,
                            value: _perceptionCrabe,
                            dataKey: 'etatlieux_perceptionCrabe',
                            onChanged: (v) => setState(() => _perceptionCrabe = v),
                            helperText: 'Nuisance / ressource / les deux',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Etat de la gestion du crabe',
                            options: _etatGestionOptions,
                            value: _etatGestionCrabe,
                            dataKey: 'etatlieux_etatGestionCrabe',
                            onChanged: (v) => setState(() => _etatGestionCrabe = v),
                            helperText: 'Bonne / plus ou moins / inexistante',
                          ),
                          _gap(),
                          _dropdownField(
                            label: "Intérêt dans l'implication de la gestion de CB",
                            options: _interetOptions,
                            value: _interetImplicationGestion,
                            dataKey: 'etatlieux_interetImplicationGestion',
                            onChanged: (v) => setState(() => _interetImplicationGestion = v),
                            helperText: 'oui / non / indifférent',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Affiliation GDAP SMSA ou association',
                            options: _ouiNonOptions,
                            value: _affiliationOuiNon,
                            dataKey: 'etatlieux_affiliation_ouiNon',
                            onChanged: (v) => setState(() => _affiliationOuiNon = v),
                            helperText: 'oui / non et type',
                          ),
                          if (_affiliationOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _affiliationTypeCtrl,
                              label: 'Type',
                              dataKey: 'etatlieux_affiliation_type',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Réglementation adéquate',
                            options: _ouiNonOptions,
                            value: _reglementationAdequate,
                            dataKey: 'etatlieux_reglementationAdequate',
                            onChanged: (v) => setState(() => _reglementationAdequate = v),
                            helperText: 'oui / non',
                          ),
                          _gap(),
                          _textField(
                            controller: _mesuresGestionProposeesCtrl,
                            label: 'Mesures de gestion proposées',
                            dataKey: 'etatlieux_mesuresGestionProposees',
                            helperText: 'détail',
                            multiline: true,
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Blooms, anomalies, mortalités',
                            options: _ouiNonOptions,
                            value: _bloomsOuiNon,
                            dataKey: 'etatlieux_blooms_ouiNon',
                            onChanged: (v) => setState(() => _bloomsOuiNon = v),
                            helperText: 'oui / non et année',
                          ),
                          if (_bloomsOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _bloomsAnneeCtrl,
                              label: 'Année',
                              dataKey: 'etatlieux_blooms_annee',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Pollutions',
                            options: _ouiNonOptions,
                            value: _pollutionsOuiNon,
                            dataKey: 'etatlieux_pollutions_ouiNon',
                            onChanged: (v) => setState(() => _pollutionsOuiNon = v),
                            helperText: 'oui / non et type',
                          ),
                          if (_pollutionsOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _pollutionsTypeCtrl,
                              label: 'Type',
                              dataKey: 'etatlieux_pollutions_type',
                            ),
                          ],
                          _gap(),
                          _dropdownField(
                            label: 'Etat du milieu (eaux)',
                            options: _etatMilieuOptions,
                            value: _etatMilieuEaux,
                            dataKey: 'etatlieux_etatMilieuEaux',
                            onChanged: (v) => setState(() => _etatMilieuEaux = v),
                            helperText: 'Bon / plus ou moins / mauvais',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Etat du Fond',
                            options: _etatMilieuOptions,
                            value: _etatFond,
                            dataKey: 'etatlieux_etatFond',
                            onChanged: (v) => setState(() => _etatFond = v),
                            helperText: 'Bon / plus ou moins / mauvais',
                          ),
                          _gap(),
                          _dropdownField(
                            label: 'Problèmes concernant la commercialisation',
                            options: _ouiNonOptions,
                            value: _problemesCommercialisationOuiNon,
                            dataKey: 'etatlieux_problemesCommercialisation_ouiNon',
                            onChanged: (v) => setState(() => _problemesCommercialisationOuiNon = v),
                            helperText: 'oui / non - préciser',
                          ),
                          if (_problemesCommercialisationOuiNon == 'Oui') ...[
                            _gap(),
                            _textField(
                              controller: _problemesCommercialisationPreciserCtrl,
                              label: 'Préciser',
                              dataKey: 'etatlieux_problemesCommercialisation_preciser',
                            ),
                          ],
                          _gap(),
                          _textField(
                            controller: _principalProblemeCtrl,
                            label: 'Principal problème rencontré',
                            dataKey: 'etatlieux_principalProbleme',
                            helperText: 'nom',
                          ),
                          _gap(),
                          _textField(
                            controller: _suggestionAmeliorationCtrl,
                            label: "Suggestion d'amélioration de l'activité",
                            dataKey: 'etatlieux_suggestionAmelioration',
                            helperText: 'détail',
                            multiline: true,
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
                              icon: Icons.check,
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