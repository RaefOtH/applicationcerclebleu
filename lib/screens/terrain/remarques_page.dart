import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';

class RemarquesPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const RemarquesPage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<RemarquesPage> createState() => _RemarquesPageState();
}

class _RemarquesPageState extends State<RemarquesPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final _remarquesCtrl = TextEditingController();
  late AnimationController _waveController;
  final TerrainFormService _service = TerrainFormService();

  bool _pecheurReticent = false;
  bool _infoPartielle = false;
  bool _gpsEstime = false;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _remarquesCtrl.text = (data['rem_text'] ?? '').toString();
    _pecheurReticent = (data['rem_pecheurReticent'] ?? false) as bool;
    _infoPartielle = (data['rem_infoPartielle'] ?? false) as bool;
    _gpsEstime = (data['rem_gpsEstime'] ?? false) as bool;

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _remarquesCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _finish() {
    data['rem_text'] = _remarquesCtrl.text;
    data['rem_pecheurReticent'] = _pecheurReticent;
    data['rem_infoPartielle'] = _infoPartielle;
    data['rem_gpsEstime'] = _gpsEstime;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Données complètes",
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w700,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              children: data.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          e.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Text(e.value.toString()),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveToFirestore() async {
    data['rem_text'] = _remarquesCtrl.text;
    data['rem_pecheurReticent'] = _pecheurReticent;
    data['rem_infoPartielle'] = _infoPartielle;
    data['rem_gpsEstime'] = _gpsEstime;
    await _service.updateFormData(
      widget.formId,
      data,
      stepCompleted: 5,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Données enregistrées')),
      );
    }
  }

  Future<void> _submit() async {
    data['rem_text'] = _remarquesCtrl.text;
    data['rem_pecheurReticent'] = _pecheurReticent;
    data['rem_infoPartielle'] = _infoPartielle;
    data['rem_gpsEstime'] = _gpsEstime;
    await _service.updateFormData(
      widget.formId,
      data,
      stepCompleted: 5,
    );
    await _service.submitForm(widget.formId);
    if (mounted) {
      Navigator.pop(context);
    }
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
                        'Remarques',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 5/5',
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
                        CheckboxListTile(
                          value: _pecheurReticent,
                          onChanged: (v) {
                            setState(() => _pecheurReticent = v ?? false);
                            data['rem_pecheurReticent'] = _pecheurReticent;
                          },
                          title: const Text("Pêcheur réticent"),
                        ),
                        CheckboxListTile(
                          value: _infoPartielle,
                          onChanged: (v) {
                            setState(() => _infoPartielle = v ?? false);
                            data['rem_infoPartielle'] = _infoPartielle;
                          },
                          title: const Text("Information partielle"),
                        ),
                        CheckboxListTile(
                          value: _gpsEstime,
                          onChanged: (v) {
                            setState(() => _gpsEstime = v ?? false);
                            data['rem_gpsEstime'] = _gpsEstime;
                          },
                          title: const Text("GPS estimé (pas mesuré)"),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _sectionCard(children: [
                        TextFormField(
                          controller: _remarquesCtrl,
                          maxLines: 12,
                          minLines: 6,
                          decoration: const InputDecoration(
                            labelText: "Remarques",
                            hintText:
                                "Ex: Pêcheur réticent, information partielle, GPS estimé (pas mesuré)...",
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          onChanged: (v) => data['rem_text'] = v,
                        ),
                      ]),
                      const SizedBox(height: 16),
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
                              text: 'Enregistrer',
                              icon: Icons.save_rounded,
                              onPressed: _saveToFirestore,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryGradientButton(
                              text: 'Soumettre',
                              icon: Icons.send_rounded,
                              onPressed: _submit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _PrimaryGradientButton(
                              text: 'Terminer',
                              icon: Icons.check,
                              onPressed: _finish,
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
