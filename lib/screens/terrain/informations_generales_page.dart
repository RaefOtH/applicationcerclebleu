import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'suivi_page.dart';

class InformationsGeneralesPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const InformationsGeneralesPage({
    super.key,
    required this.data,
    required this.formId,
  });

  @override
  State<InformationsGeneralesPage> createState() =>
      _InformationsGeneralesPageState();
}

class _InformationsGeneralesPageState extends State<InformationsGeneralesPage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _idEnqueteurCtrl = TextEditingController();
  final _idObservationCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _heureCtrl = TextEditingController();
  final _paysCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _portPecheCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();

  int _qcFlag = 0;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _idEnqueteurCtrl.text = (data['gen_idEnqueteur'] ?? '').toString();
    _idObservationCtrl.text = (data['gen_idObservation'] ?? '').toString();
    _dateCtrl.text = (data['gen_date'] ?? '').toString();
    _heureCtrl.text = (data['gen_heure'] ?? '').toString();
    _paysCtrl.text = (data['gen_pays'] ?? '').toString();
    _regionCtrl.text = (data['gen_region'] ?? '').toString();
    _portPecheCtrl.text = (data['gen_portPeche'] ?? '').toString();
    _zoneCtrl.text = (data['gen_zone'] ?? '').toString();
    _longitudeCtrl.text = (data['gen_longitude'] ?? '').toString();
    _latitudeCtrl.text = (data['gen_latitude'] ?? '').toString();

    final rawQcFlag = data['gen_qcFlag'];
    if (rawQcFlag is int) {
      _qcFlag = rawQcFlag;
    } else if (rawQcFlag is num) {
      _qcFlag = rawQcFlag.toInt();
    } else if (rawQcFlag is String) {
      _qcFlag = int.tryParse(rawQcFlag) ?? 0;
    } else {
      _qcFlag = 0;
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _idEnqueteurCtrl.dispose();
    _idObservationCtrl.dispose();
    _dateCtrl.dispose();
    _heureCtrl.dispose();
    _paysCtrl.dispose();
    _regionCtrl.dispose();
    _portPecheCtrl.dispose();
    _zoneCtrl.dispose();
    _longitudeCtrl.dispose();
    _latitudeCtrl.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final dd = picked.day.toString().padLeft(2, '0');
      final mm = picked.month.toString().padLeft(2, '0');
      final yyyy = picked.year.toString();
      final txt = "$dd-$mm-$yyyy";
      setState(() => _dateCtrl.text = txt);
      data['gen_date'] = txt;
      _service.updateFormData(widget.formId, {'gen_date': txt});
    }
  }

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
    _service.updateFormData(widget.formId, data, stepCompleted: 1);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SuiviPage(formId: widget.formId, data: data),
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
                        'Informations générales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 1/5',
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
                          controller: _idEnqueteurCtrl,
                          decoration: _dec("ID_Enquêteur (Nom & Prénom)"),
                          onChanged: (v) => data['gen_idEnqueteur'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idObservationCtrl,
                          decoration: _dec("ID_Observation"),
                          onChanged: (v) => data['gen_idObservation'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _dec(
                            "Date",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month),
                              onPressed: _pickDate,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _heureCtrl,
                          readOnly: true,
                          onTap: () =>
                              _pickTime24h(_heureCtrl, 'gen_heure'),
                          decoration: _dec(
                            "Heure de l’observation (24h)",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _pickTime24h(_heureCtrl, 'gen_heure'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: _qcFlag,
                          decoration: _dec(
                              "QC_Flag (0=OK, 1=à vérifier, 2=manquant)"),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text("0 - OK")),
                            DropdownMenuItem(
                                value: 1, child: Text("1 - À vérifier")),
                            DropdownMenuItem(
                                value: 2, child: Text("2 - Manquant")),
                          ],
                          onChanged: (v) {
                            setState(() => _qcFlag = v ?? 0);
                            data['gen_qcFlag'] = _qcFlag;
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        TextFormField(
                          controller: _paysCtrl,
                          decoration: _dec("Pays"),
                          onChanged: (v) => data['gen_pays'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _regionCtrl,
                          decoration: _dec("Région"),
                          onChanged: (v) => data['gen_region'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _portPecheCtrl,
                          decoration: _dec("Port de Pêche"),
                          onChanged: (v) => data['gen_portPeche'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _zoneCtrl,
                          decoration: _dec("Nom de la zone (nom local)"),
                          onChanged: (v) => data['gen_zone'] = v,
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        TextFormField(
                          controller: _longitudeCtrl,
                          decoration: _dec("Longitude (décimal)"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['gen_longitude'] = v,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _latitudeCtrl,
                          decoration: _dec("Latitude (décimal)"),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) => data['gen_latitude'] = v,
                        ),
                      ]),
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


