import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'capture_page.dart';

class SuiviPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const SuiviPage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<SuiviPage> createState() => _SuiviPageState();
}

class _SuiviPageState extends State<SuiviPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _typeObservationCtrl = TextEditingController();
  final _typeEnginCtrl = TextEditingController();
  final _nbPiecesCtrl = TextEditingController();
  final _idNavireCtrl = TextEditingController();
  final _idNasseCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _typeObservationCtrl.text =
        (data['suivi_typeObservation'] ?? '').toString();
    _typeEnginCtrl.text = (data['suivi_typeEngin'] ?? '').toString();
    _nbPiecesCtrl.text = (data['suivi_nbPieces'] ?? '').toString();
    _idNavireCtrl.text = (data['suivi_idNavire'] ?? '').toString();
    _idNasseCtrl.text = (data['suivi_idNasse'] ?? '').toString();
    _debutCtrl.text = (data['suivi_debut'] ?? '').toString();
    _finCtrl.text = (data['suivi_fin'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _typeObservationCtrl.dispose();
    _typeEnginCtrl.dispose();
    _nbPiecesCtrl.dispose();
    _idNavireCtrl.dispose();
    _idNasseCtrl.dispose();
    _debutCtrl.dispose();
    _finCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) => InputDecoration(
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

  Future<void> _pickTime24h(TextEditingController ctrl, String key) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      final txt = "$hh:$mm";
      setState(() => ctrl.text = txt);
      data[key] = txt;
      _service.updateFormData(widget.formId, {key: txt});
    }
  }

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturePage(formId: widget.formId, data: data),
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
                        'Suivi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 2/5',
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
                          controller: _typeObservationCtrl,
                          decoration: _dec(
                              "Type d'observation (à bord / au port / expérimental)"),
                          onChanged: (v) =>
                              data['suivi_typeObservation'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _typeEnginCtrl,
                          decoration: _dec(
                              "Type d'engin (chalut, nasse, filet, ...)"),
                          onChanged: (v) => data['suivi_typeEngin'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nbPiecesCtrl,
                          decoration: _dec("Nombre de pièce (nasse/filet)"),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => data['suivi_nbPieces'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idNavireCtrl,
                          decoration:
                              _dec("ID du navire (Nom & Immatriculation)"),
                          onChanged: (v) => data['suivi_idNavire'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idNasseCtrl,
                          decoration: _dec("ID de la nasse"),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => data['suivi_idNasse'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _debutCtrl,
                          readOnly: true,
                          onTap: () => _pickTime24h(_debutCtrl, 'suivi_debut'),
                          decoration: _dec(
                            "Opération de pêche - Début (24h)",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _pickTime24h(_debutCtrl, 'suivi_debut'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _finCtrl,
                          readOnly: true,
                          onTap: () => _pickTime24h(_finCtrl, 'suivi_fin'),
                          decoration: _dec(
                            "Opération de pêche - Fin (24h)",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _pickTime24h(_finCtrl, 'suivi_fin'),
                            ),
                          ),
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
