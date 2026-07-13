import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../painters/wave_painter.dart';
import '../../services/firestore_db.dart';
import '../../services/lab_form_service.dart';
import 'analyse_crabe_bleu_page2.dart';
import 'donnees_laboratoire_home.dart';

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
  final FirebaseFirestore _db = FirestoreDb.db;
  final List<String> _terrainObservationIds = [];
  bool _loadingObservationIds = true;

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
    _loadTerrainObservationIds();

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
      suffixIcon: suffixIcon,
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
  }

  Map<String, dynamic> _toMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  Future<void> _loadTerrainObservationIds() async {
    try {
      final snap = await _db
          .collection('terrain_forms')
          .orderBy('updatedAt', descending: true)
          .get();
      final seen = <String>{};
      final ordered = <String>[];
      for (final doc in snap.docs) {
        final root = doc.data();
        final nested = _toMap(root['data']);
        final candidates = [
          (nested['gen_idObservation'] ?? '').toString().trim(),
          (root['observationId'] ?? '').toString().trim(),
        ];
        for (final id in candidates) {
          if (id.isEmpty) continue;
          if (seen.add(id)) ordered.add(id);
        }
      }
      final current = _idObservationCtrl.text.trim();
      if (current.isNotEmpty && !seen.contains(current)) {
        ordered.insert(0, current);
      }
      if (!mounted) return;
      setState(() {
        _terrainObservationIds
          ..clear()
          ..addAll(ordered);
        _loadingObservationIds = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingObservationIds = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de charger les ID terrain.")),
      );
    }
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
      _service.scheduleFullDataSave(widget.formId, data);
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
      onChanged: (v) {
        data[key] = v;
        _service.scheduleFullDataSave(widget.formId, data);
      },
    );
  }

  Widget _idObservationDropdown() {
    final current = _idObservationCtrl.text.trim();
    final initialValue = _terrainObservationIds.contains(current)
        ? current
        : null;
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      isExpanded: true,
      decoration: _dec(
        "ID_Observation",
        suffixIcon: _loadingObservationIds
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
      hint: Text(
        _loadingObservationIds
            ? 'Chargement des observations...'
            : 'Choisir...',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      items: _terrainObservationIds
          .map(
            (id) => DropdownMenuItem<String>(
              value: id,
              child: Text(id, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: _loadingObservationIds || _terrainObservationIds.isEmpty
          ? null
          : (value) {
              final selected = value ?? '';
              _idObservationCtrl.text = selected;
              data['idObservation'] = selected;
              _service.scheduleFullDataSave(widget.formId, data);
            },
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

    _service.updateFormData(widget.formId, data, stepCompleted: 1);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AnalyseCrabeBleuPage2(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToLabHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DonneesLaboratoireHome(formId: widget.formId),
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
                        onPressed: _goToLabHome,
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
                          _idObservationDropdown(),
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
                                _dateReceptionCtrl,
                                'dateReception',
                              ),
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
                              onPressed: () =>
                                  _pickDate(_dateAnalyseCtrl, 'dateAnalyse'),
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
                                    content: Text('Données enregistrées'),
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
