import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'lek_home.dart';
// TODO: replace with the actual next page of your flow if different.
import 'dynamique_du_crabe_page.dart';
import 'impact_sur_la_peche_page.dart';

/// Simple code/label pair used by the dropdowns of this page.
class _OptionItem {
  final String code;
  final String label;
  const _OptionItem(this.code, this.label);
}

/// A 1-5 evaluation level with an optional sign (+ / -), e.g. "3+", "2-", "4".
class _ScoreValue {
  int? score; // 1..5
  String? sign; // '+' | '-' | null

  _ScoreValue({this.score, this.sign});

  String toStorageString() {
    if (score == null) return '';
    return '$score${sign ?? ''}';
  }

  static _ScoreValue fromStorageString(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return _ScoreValue();
    final signChar = s.endsWith('+') || s.endsWith('-') ? s.substring(s.length - 1) : null;
    final numPart = signChar != null ? s.substring(0, s.length - 1) : s;
    final n = int.tryParse(numPart);
    return _ScoreValue(score: n, sign: signChar);
  }
}

class ImpactEcologiquePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const ImpactEcologiquePage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<ImpactEcologiquePage> createState() => _ImpactEcologiquePageState();
}

class _ImpactEcologiquePageState extends State<ImpactEcologiquePage>
    with SingleTickerProviderStateMixin {
  static const List<_OptionItem> _ouiNonOptions = [
    _OptionItem('Oui', 'Oui'),
    _OptionItem('Non', 'Non'),
  ];

  static const List<_OptionItem> _tendanceOptions = [
    _OptionItem('Aug', 'Augmentation (Aug)'),
    _OptionItem('Dim', 'Diminution (Dim)'),
    _OptionItem('St', 'Stable (St)'),
    _OptionItem('Var', 'Variable (année(s) clé(s))'),
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();
  late AnimationController _waveController;

  // ---- impact sur les habitats
  String? _habitatsOuiNon;
  final _ScoreValue _herbiersDisparaissent = _ScoreValue();
  final _ScoreValue _fondSeCreuse = _ScoreValue();
  final _ScoreValue _retourneLeFond = _ScoreValue();
  final TextEditingController _autreTexteCtrl = TextEditingController();
  final _ScoreValue _autreScore = _ScoreValue();

  // ---- impact sur la biodiversité
  String? _biodiversiteOuiNon;
  String? _tendance;
  final TextEditingController _tendanceAnneesClesCtrl = TextEditingController();
  final TextEditingController _depuisQuandCtrl = TextEditingController();
  final TextEditingController _zonePlusAffecteeCtrl = TextEditingController();

  final TextEditingController _espece1NomCtrl = TextEditingController();
  final _ScoreValue _espece1Score = _ScoreValue();
  final TextEditingController _espece2NomCtrl = TextEditingController();
  final _ScoreValue _espece2Score = _ScoreValue();
  final TextEditingController _espece3NomCtrl = TextEditingController();
  final _ScoreValue _espece3Score = _ScoreValue();

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _habitatsOuiNon = _nullIfEmpty(data['impact_ecologique_habitats_ouiNon']);
    _herbiersDisparaissentAssign(_ScoreValue.fromStorageString(
        data['impact_ecologique_habitats_herbiersDisparaissent']));
    _fondSeCreuseAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_habitats_fondSeCreuse']));
    _retourneLeFondAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_habitats_retourneLeFond']));
    _autreTexteCtrl.text = (data['impact_ecologique_habitats_autreTexte'] ?? '').toString();
    _autreScoreAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_habitats_autreScore']));

    _biodiversiteOuiNon = _nullIfEmpty(data['impact_ecologique_biodiversite_ouiNon']);
    _tendance = _nullIfEmpty(data['impact_ecologique_biodiversite_tendance']);
    _tendanceAnneesClesCtrl.text =
        (data['impact_ecologique_biodiversite_tendanceAnneesCles'] ?? '').toString();
    _depuisQuandCtrl.text = (data['impact_ecologique_biodiversite_depuisQuand'] ?? '').toString();
    _zonePlusAffecteeCtrl.text =
        (data['impact_ecologique_biodiversite_zonePlusAffectee'] ?? '').toString();

    _espece1NomCtrl.text = (data['impact_ecologique_biodiversite_espece1_nom'] ?? '').toString();
    _espece1ScoreAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_biodiversite_espece1_score']));
    _espece2NomCtrl.text = (data['impact_ecologique_biodiversite_espece2_nom'] ?? '').toString();
    _espece2ScoreAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_biodiversite_espece2_score']));
    _espece3NomCtrl.text = (data['impact_ecologique_biodiversite_espece3_nom'] ?? '').toString();
    _espece3ScoreAssign(
        _ScoreValue.fromStorageString(data['impact_ecologique_biodiversite_espece3_score']));

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  // Small helpers so field values loaded from `data` land in the right
  // `_ScoreValue` instance (fields are `final`, only their content mutates).
  void _herbiersDisparaissentAssign(_ScoreValue v) {
    _herbiersDisparaissent.score = v.score;
    _herbiersDisparaissent.sign = v.sign;
  }

  void _fondSeCreuseAssign(_ScoreValue v) {
    _fondSeCreuse.score = v.score;
    _fondSeCreuse.sign = v.sign;
  }

  void _retourneLeFondAssign(_ScoreValue v) {
    _retourneLeFond.score = v.score;
    _retourneLeFond.sign = v.sign;
  }

  void _autreScoreAssign(_ScoreValue v) {
    _autreScore.score = v.score;
    _autreScore.sign = v.sign;
  }

  void _espece1ScoreAssign(_ScoreValue v) {
    _espece1Score.score = v.score;
    _espece1Score.sign = v.sign;
  }

  void _espece2ScoreAssign(_ScoreValue v) {
    _espece2Score.score = v.score;
    _espece2Score.sign = v.sign;
  }

  void _espece3ScoreAssign(_ScoreValue v) {
    _espece3Score.score = v.score;
    _espece3Score.sign = v.sign;
  }

  static String? _nullIfEmpty(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  @override
  void dispose() {
    _autreTexteCtrl.dispose();
    _tendanceAnneesClesCtrl.dispose();
    _depuisQuandCtrl.dispose();
    _zonePlusAffecteeCtrl.dispose();
    _espece1NomCtrl.dispose();
    _espece2NomCtrl.dispose();
    _espece3NomCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _save(String key, String value) {
    data[key] = value;
    _service.scheduleFullDataSave(widget.formId, data);
  }

  void _saveScore(String key, _ScoreValue v) => _save(key, v.toStorageString());

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

  // ---- Header bars matching the dark / light gray rows of the Excel sheet.

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

  /// One circular 1..5 pick button used inside the score rating field.
  Widget _scoreDot({
    required int n,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFF00D9D9) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF00D9D9)
                : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF00D9D9).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$n',
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1E3A8A),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// One '+' or '-' pick button used inside the score rating field.
  Widget _signDot({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFF1E3A8A) : Colors.white,
          border: Border.all(
            color: selected
                ? const Color(0xFF1E3A8A)
                : const Color(0xFF1E3A8A).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF1E3A8A),
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  /// A "niveau d'évaluation" field: pick a level 1 to 5 and, optionally,
  /// a sign (+ or -) to nuance it — e.g. "4+" or "2-".
  Widget _scoreSignField({
    required String label,
    required String dataKey,
    required _ScoreValue value,
    String? helperText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 2),
            Text(
              helperText,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int n = 1; n <= 5; n++)
                _scoreDot(
                  n: n,
                  selected: value.score == n,
                  onTap: () => setState(() {
                    value.score = value.score == n ? null : n;
                    _saveScore(dataKey, value);
                  }),
                ),
              const SizedBox(width: 10),
              _signDot(
                label: '+',
                selected: value.sign == '+',
                onTap: () => setState(() {
                  value.sign = value.sign == '+' ? null : '+';
                  _saveScore(dataKey, value);
                }),
              ),
              const SizedBox(width: 6),
              _signDot(
                label: '-',
                selected: value.sign == '-',
                onTap: () => setState(() {
                  value.sign = value.sign == '-' ? null : '-';
                  _saveScore(dataKey, value);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _especeBlock({
    required String title,
    required TextEditingController nomCtrl,
    required String nomKey,
    required _ScoreValue score,
    required String scoreKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _plainLabel(title),
          _textField(controller: nomCtrl, label: 'Nom', dataKey: nomKey),
          _gap(),
          _scoreSignField(
            label: 'Score',
            dataKey: scoreKey,
            value: score,
            helperText: '1-5 avec + et -',
          ),
        ],
      ),
    );
  }

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 3);

    Navigator.push(context, MaterialPageRoute(
       builder: (_) => ImpactSurLaPechePage(formId: widget.formId, data: data),
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
                        'Impact écologique',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 5/9',
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
                      // ---- Impact sur les habitats
                      _sectionCard(
                        children: [
                          _sectionHeader('Impact sur les habitats'),
                          _dropdownField(
                            label: 'Impact sur les habitats',
                            options: _ouiNonOptions,
                            value: _habitatsOuiNon,
                            dataKey: 'impact_ecologique_habitats_ouiNon',
                            onChanged: (v) => setState(() => _habitatsOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          _subHeader('Détail des changements'),
                          _scoreSignField(
                            label: 'Herbiers disparaissent',
                            dataKey: 'impact_ecologique_habitats_herbiersDisparaissent',
                            value: _herbiersDisparaissent,
                            helperText: 'score 1-5',
                          ),
                          _gap(),
                          _scoreSignField(
                            label: 'Fond se creuse',
                            dataKey: 'impact_ecologique_habitats_fondSeCreuse',
                            value: _fondSeCreuse,
                            helperText: 'score 1-5',
                          ),
                          _gap(),
                          _scoreSignField(
                            label: 'Retourne le fond',
                            dataKey: 'impact_ecologique_habitats_retourneLeFond',
                            value: _retourneLeFond,
                            helperText: 'score 1-5',
                          ),
                          _gap(),
                          _textField(
                            controller: _autreTexteCtrl,
                            label: 'Autre (à préciser)',
                            dataKey: 'impact_ecologique_habitats_autreTexte',
                          ),
                          _gap(),
                          _scoreSignField(
                            label: 'Autre - score',
                            dataKey: 'impact_ecologique_habitats_autreScore',
                            value: _autreScore,
                            helperText: 'score 1-5',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // ---- Impact sur la biodiversité
                      _sectionCard(
                        children: [
                          _sectionHeader('Impact sur la biodiversité'),
                          _dropdownField(
                            label: 'Impact sur la biodiversité',
                            options: _ouiNonOptions,
                            value: _biodiversiteOuiNon,
                            dataKey: 'impact_ecologique_biodiversite_ouiNon',
                            onChanged: (v) =>
                                setState(() => _biodiversiteOuiNon = v),
                            helperText: 'oui / non',
                          ),
                          _subHeader('Détail des changements'),
                          _dropdownField(
                            label: 'Tendance',
                            options: _tendanceOptions,
                            value: _tendance,
                            dataKey: 'impact_ecologique_biodiversite_tendance',
                            onChanged: (v) => setState(() => _tendance = v),
                            helperText: 'Aug / Dim / St / Var (année clés)',
                          ),
                          if (_tendance == 'Var') ...[
                            _gap(),
                            _textField(
                              controller: _tendanceAnneesClesCtrl,
                              label: 'Année(s) clé(s)',
                              dataKey: 'impact_ecologique_biodiversite_tendanceAnneesCles',
                            ),
                          ],
                          _gap(),
                          _textField(
                            controller: _depuisQuandCtrl,
                            label: 'Depuis quand',
                            dataKey: 'impact_ecologique_biodiversite_depuisQuand',
                            helperText: 'année',
                            numeric: true,
                          ),
                          _gap(),
                          _textField(
                            controller: _zonePlusAffecteeCtrl,
                            label: 'Zone la plus affectée',
                            dataKey: 'impact_ecologique_biodiversite_zonePlusAffectee',
                            helperText: 'Nom / carte (*)',
                          ),
                          _plainLabel('Espèces les plus affectées'),
                          _especeBlock(
                            title: 'Espèce 1',
                            nomCtrl: _espece1NomCtrl,
                            nomKey: 'impact_ecologique_biodiversite_espece1_nom',
                            score: _espece1Score,
                            scoreKey: 'impact_ecologique_biodiversite_espece1_score',
                          ),
                          _especeBlock(
                            title: 'Espèce 2',
                            nomCtrl: _espece2NomCtrl,
                            nomKey: 'impact_ecologique_biodiversite_espece2_nom',
                            score: _espece2Score,
                            scoreKey: 'impact_ecologique_biodiversite_espece2_score',
                          ),
                          _especeBlock(
                            title: 'Espèce 3',
                            nomCtrl: _espece3NomCtrl,
                            nomKey: 'impact_ecologique_biodiversite_espece3_nom',
                            score: _espece3Score,
                            scoreKey: 'impact_ecologique_biodiversite_espece3_score',
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
                                      builder: (_) => DynamiqueDuCrabePage(formId: widget.formId, data:data),
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