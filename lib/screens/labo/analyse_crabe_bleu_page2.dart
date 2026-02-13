import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../painters/wave_painter.dart';
import '../../services/lab_form_service.dart';
import 'epibionts_page3.dart';

class AnalyseCrabeBleuPage2 extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const AnalyseCrabeBleuPage2({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<AnalyseCrabeBleuPage2> createState() => _AnalyseCrabeBleuPage2State();
}

class _AnalyseCrabeBleuPage2State extends State<AnalyseCrabeBleuPage2>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final LabFormService _service = LabFormService();

  final _qcCtrl = TextEditingController();
  final _especeCtrl = TextEditingController();
  final _idIndividuCtrl = TextEditingController();
  final _sexeCtrl = TextEditingController();
  final _stadeCtrl = TextEditingController();
  final _maturiteCtrl = TextEditingController();
  final _cwCtrl = TextEditingController();
  final _clCtrl = TextEditingController();
  final _poidsTotalCtrl = TextEditingController();

  final _appendGCtrl = TextEditingController();
  final _appendDCtrl = TextEditingController();
  final _pincesCtrl = TextEditingController();
  final _couleurOeufsCtrl = TextEditingController();

  final _poidsGonadesCtrl = TextEditingController();
  final _poidsOeufsCtrl = TextEditingController();
  final _indiceGonadoCtrl = TextEditingController();
  final _poidsSpermathequeCtrl = TextEditingController();

  final _stadeMueCtrl = TextEditingController();
  final _tauxProteinesCtrl = TextEditingController();
  final _tauxLipidesCtrl = TextEditingController();
  final _tauxProteines2Ctrl = TextEditingController();
  final _humiditeCtrl = TextEditingController();
  final _cendresCtrl = TextEditingController();

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _qcCtrl.text = (data['qcFlag'] ?? '').toString();
    _especeCtrl.text = (data['espece'] ?? '').toString();
    _idIndividuCtrl.text = (data['idIndividu'] ?? '').toString();
    _sexeCtrl.text = (data['sexe'] ?? '').toString();
    _stadeCtrl.text = (data['stade'] ?? '').toString();
    _maturiteCtrl.text = (data['maturite'] ?? '').toString();
    _cwCtrl.text = (data['cw'] ?? '').toString();
    _clCtrl.text = (data['cl'] ?? '').toString();
    _poidsTotalCtrl.text = (data['poidsTotal'] ?? '').toString();

    _appendGCtrl.text = (data['appendicesGauche'] ?? '').toString();
    _appendDCtrl.text = (data['appendicesDroit'] ?? '').toString();
    _pincesCtrl.text = (data['pincesManquantes'] ?? '').toString();
    _couleurOeufsCtrl.text = (data['couleurOeufs'] ?? '').toString();

    _poidsGonadesCtrl.text = (data['poidsGonades'] ?? '').toString();
    _poidsOeufsCtrl.text = (data['poidsOeufs'] ?? '').toString();
    _indiceGonadoCtrl.text = (data['indiceGonado'] ?? '').toString();
    _poidsSpermathequeCtrl.text =
        (data['poidsSpermatheque'] ?? '').toString();

    _stadeMueCtrl.text = (data['stadeMue'] ?? '').toString();
    _tauxProteinesCtrl.text = (data['tauxProteines'] ?? '').toString();
    _tauxLipidesCtrl.text = (data['tauxLipides'] ?? '').toString();
    _tauxProteines2Ctrl.text = (data['tauxProteines2'] ?? '').toString();
    _humiditeCtrl.text = (data['humidite'] ?? '').toString();
    _cendresCtrl.text = (data['cendres'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _qcCtrl.dispose();
    _especeCtrl.dispose();
    _idIndividuCtrl.dispose();
    _sexeCtrl.dispose();
    _stadeCtrl.dispose();
    _maturiteCtrl.dispose();
    _cwCtrl.dispose();
    _clCtrl.dispose();
    _poidsTotalCtrl.dispose();

    _appendGCtrl.dispose();
    _appendDCtrl.dispose();
    _pincesCtrl.dispose();
    _couleurOeufsCtrl.dispose();

    _poidsGonadesCtrl.dispose();
    _poidsOeufsCtrl.dispose();
    _indiceGonadoCtrl.dispose();
    _poidsSpermathequeCtrl.dispose();

    _stadeMueCtrl.dispose();
    _tauxProteinesCtrl.dispose();
    _tauxLipidesCtrl.dispose();
    _tauxProteines2Ctrl.dispose();
    _humiditeCtrl.dispose();
    _cendresCtrl.dispose();
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

  List<TextInputFormatter> _intOnly() => [
        FilteringTextInputFormatter.digitsOnly,
      ];

  List<TextInputFormatter> _decimalOnly() => [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d*)?$')),
      ];

  Widget _fieldText({
    required String label,
    required TextEditingController ctrl,
    required String key,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(label),
      onChanged: (v) => data[key] = v,
    );
  }

  Widget _fieldInt({
    required String label,
    required TextEditingController ctrl,
    required String key,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(label),
      keyboardType: TextInputType.number,
      inputFormatters: _intOnly(),
      onChanged: (v) => data[key] = v,
    );
  }

  Widget _fieldDecimal({
    required String label,
    required TextEditingController ctrl,
    required String key,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimalOnly(),
      onChanged: (v) => data[key] = v,
    );
  }

  void _goNext() {
    _service.updateFormData(
      widget.formId,
      data,
      stepCompleted: 2,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EpibiontsPage3(
          formId: widget.formId,
          data: data,
        ),
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
                        'Analyse crabe bleu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 2/4',
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
                        _fieldInt(
                          label: "QC_Flag (0=OK, 1=à vérifier, 2=manquant)",
                          ctrl: _qcCtrl,
                          key: "qcFlag",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Espèce",
                          ctrl: _especeCtrl,
                          key: "espece",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "ID_Individu",
                          ctrl: _idIndividuCtrl,
                          key: "idIndividu",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Sexe",
                          ctrl: _sexeCtrl,
                          key: "sexe",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Stade (juvénile/adulte)",
                          ctrl: _stadeCtrl,
                          key: "stade",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Stade de maturité",
                          ctrl: _maturiteCtrl,
                          key: "maturite",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "CW (mm)",
                          ctrl: _cwCtrl,
                          key: "cw",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "CL (mm)",
                          ctrl: _clCtrl,
                          key: "cl",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Poids total",
                          ctrl: _poidsTotalCtrl,
                          key: "poidsTotal",
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        _fieldInt(
                          label: "Nbre d’appendices gauche",
                          ctrl: _appendGCtrl,
                          key: "appendicesGauche",
                        ),
                        const SizedBox(height: 12),
                        _fieldInt(
                          label: "Nbre d’appendices droit",
                          ctrl: _appendDCtrl,
                          key: "appendicesDroit",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Pinces manquantes (oui/non)",
                          ctrl: _pincesCtrl,
                          key: "pincesManquantes",
                        ),
                        const SizedBox(height: 12),
                        _fieldText(
                          label: "Couleur des œufs",
                          ctrl: _couleurOeufsCtrl,
                          key: "couleurOeufs",
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        _fieldDecimal(
                          label: "Poids des gonades (g)",
                          ctrl: _poidsGonadesCtrl,
                          key: "poidsGonades",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Poids des œufs (g)",
                          ctrl: _poidsOeufsCtrl,
                          key: "poidsOeufs",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Indice gonadosomatique",
                          ctrl: _indiceGonadoCtrl,
                          key: "indiceGonado",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Poids de la spermathèque",
                          ctrl: _poidsSpermathequeCtrl,
                          key: "poidsSpermatheque",
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        _fieldText(
                          label: "Stade de la mue",
                          ctrl: _stadeMueCtrl,
                          key: "stadeMue",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Taux des protéines",
                          ctrl: _tauxProteinesCtrl,
                          key: "tauxProteines",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Taux des lipides",
                          ctrl: _tauxLipidesCtrl,
                          key: "tauxLipides",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Taux des protéines (colonne 2)",
                          ctrl: _tauxProteines2Ctrl,
                          key: "tauxProteines2",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Humidité",
                          ctrl: _humiditeCtrl,
                          key: "humidite",
                        ),
                        const SizedBox(height: 12),
                        _fieldDecimal(
                          label: "Cendres",
                          ctrl: _cendresCtrl,
                          key: "cendres",
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
