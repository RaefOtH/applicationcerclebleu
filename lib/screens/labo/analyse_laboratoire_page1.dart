import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lab_form_service.dart';
import 'analyse_crabe_bleu_page2.dart';

class AnalyseLaboratoirePage1 extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const AnalyseLaboratoirePage1({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<AnalyseLaboratoirePage1> createState() =>
      _AnalyseLaboratoirePage1State();
}

class _AnalyseLaboratoirePage1State extends State<AnalyseLaboratoirePage1>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final LabFormService _service = LabFormService();

  final _idObservationCtrl = TextEditingController();
  final _dateReceptionCtrl = TextEditingController();
  final _idLaboratoireCtrl = TextEditingController();
  final _idAnalysteCtrl = TextEditingController();
  final _dateAnalyseCtrl = TextEditingController();

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _idObservationCtrl.text = (data['idObservation'] ?? '').toString();
    _dateReceptionCtrl.text = (data['dateReception'] ?? '').toString();
    _idLaboratoireCtrl.text = (data['idLaboratoire'] ?? '').toString();
    _idAnalysteCtrl.text = (data['idAnalyste'] ?? '').toString();
    _dateAnalyseCtrl.text = (data['dateAnalyse'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _idObservationCtrl.dispose();
    _dateReceptionCtrl.dispose();
    _idLaboratoireCtrl.dispose();
    _idAnalysteCtrl.dispose();
    _dateAnalyseCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
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
  }

  Future<void> _pickDate(TextEditingController ctrl, String key) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final txt =
          "${picked.day.toString().padLeft(2, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.year}";
      setState(() => ctrl.text = txt);
      data[key] = txt;
    }
  }

  Widget _textField({
    required String label,
    required TextEditingController ctrl,
    required String key,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: ctrl,
      readOnly: readOnly,
      onTap: onTap,
      decoration: _dec(label, suffixIcon: suffixIcon),
      onChanged: (v) => data[key] = v,
    );
  }

  bool get _canGoNext =>
      _idObservationCtrl.text.trim().isNotEmpty &&
          _dateReceptionCtrl.text.trim().isNotEmpty;

  void _goNext() {
    if (!_canGoNext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Remplir ID_Observation et Date de réception."),
        ),
      );
      return;
    }

    _service.updateFormData(
      widget.formId,
      data,
      stepCompleted: 1,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyseCrabeBleuPage2(
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
                        'Infos générales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 1/4',
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
                      _sectionCard(
                        children: [
                          _textField(
                            label: "ID_Observation",
                            ctrl: _idObservationCtrl,
                            key: "idObservation",
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            label: "Date de réception labo",
                            ctrl: _dateReceptionCtrl,
                            key: "dateReception",
                            readOnly: true,
                            onTap: () =>
                                _pickDate(_dateReceptionCtrl, 'dateReception'),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _pickDate(
                                  _dateReceptionCtrl, 'dateReception'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            label: "ID_Laboratoire",
                            ctrl: _idLaboratoireCtrl,
                            key: "idLaboratoire",
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            label: "ID_Analyste",
                            ctrl: _idAnalysteCtrl,
                            key: "idAnalyste",
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            label: "Date de l’analyse",
                            ctrl: _dateAnalyseCtrl,
                            key: "dateAnalyse",
                            readOnly: true,
                            onTap: () =>
                                _pickDate(_dateAnalyseCtrl, 'dateAnalyse'),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: () => _pickDate(
                                  _dateAnalyseCtrl, 'dateAnalyse'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Enregistrer',
                              icon: Icons.save_rounded,
                              onPressed: () {
                                _service.updateFormData(
                                  widget.formId,
                                  data,
                                  stepCompleted: 1,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Données enregistrées')),
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
