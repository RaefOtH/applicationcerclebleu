import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/firestore_db.dart';
import '../../services/terrain_form_service.dart';
import 'matrice1_home.dart';
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
  static const List<String> _paysOptions = ['Tunisie', 'Italie'];
  static const List<String> _regionOptions = ['Nord', 'Est', 'Sud'];
  static const List<String> _portPecheOptions = [
    'Aghir',
    'Ajim',
    'Attaya',
    'Bekalta',
    'Beni Khiar',
    'Biban',
    'Bizerte',
    'Borj Cédria',
    'Boughrara',
    'Cap.Zebib',
    'Chebba',
    'El Awabid',
    'Elgreen',
    'Elketf',
    'Ellouza',
    'Essaloum',
    'Ezzahra',
    'Gabes',
    'Ghannouche',
    'Ghar.El melh',
    'Hammam lif',
    'Hammamet',
    'Hassi Jallaba',
    'Hawaria',
    'Hergla',
    'Houmtsouk',
    'K. Andalous',
    'Kélibia',
    'Khnis',
    'Kratten',
    'Ksibet el Madiouni',
    'La Goulette',
    'Lac Nord',
    'Mahdia',
    'Mahres',
    'Mel. A.errahman',
    'Mellita',
    'Melloulech',
    'Monastir',
    'Port el Kantaoui',
    'Rades',
    'Raoued',
    'Salakta',
    'Sayada',
    'Sfax',
    'Sidi Abdelhamid',
    'Sidi Bou Said',
    'Sidi Daoud',
    'Sidi Mansour',
    'Sidi Mechreg',
    'Skhira',
    'Soluman',
    'Sousse',
    'Tabarka',
    'Teboulba',
    'Tinja',
    'Zabboussa',
    'Zarrat',
    'Zarzis',
    'Zouaraa',
  ];

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

  int? _qcFlag;
  String? _selectedPays;
  String? _selectedRegion;
  String? _selectedPortPeche;
  bool _isGeneratingObservationId = false;
  bool _hasExistingObservationId = false;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _idEnqueteurCtrl.text = (data['gen_idEnqueteur'] ?? '').toString();
    _idObservationCtrl.text = (data['gen_idObservation'] ?? '').toString();
    _hasExistingObservationId = _idObservationCtrl.text.trim().isNotEmpty;
    _dateCtrl.text = (data['gen_date'] ?? '').toString();
    _heureCtrl.text = (data['gen_heure'] ?? '').toString();
    _paysCtrl.text = (data['gen_pays'] ?? '').toString();
    _regionCtrl.text = (data['gen_region'] ?? '').toString();
    _portPecheCtrl.text = (data['gen_portPeche'] ?? '').toString();
    _zoneCtrl.text = (data['gen_zone'] ?? '').toString();
    _longitudeCtrl.text = (data['gen_longitude'] ?? '').toString();
    _latitudeCtrl.text = (data['gen_latitude'] ?? '').toString();

    final rawQcFlag = data['gen_qcFlag'];
    final parsedQc = rawQcFlag is int
        ? rawQcFlag
        : rawQcFlag is num
            ? rawQcFlag.toInt()
            : rawQcFlag is String
                ? int.tryParse(rawQcFlag)
                : null;
    _qcFlag = (parsedQc != null && [0, 1, 2].contains(parsedQc))
        ? parsedQc
        : null;

    _selectedPays = _normalizeStringOption(data['gen_pays'], _paysOptions);
    _selectedRegion =
        _normalizeStringOption(data['gen_region'], _regionOptions);
    _selectedPortPeche =
        _normalizeStringOption(data['gen_portPeche'], _portPecheOptions);

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

  String? _normalizeStringOption(dynamic value, List<String> options) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return options.contains(raw) ? raw : null;
  }

  String _formatYyyyMmDd(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  int _extractSuffix(String value) {
    final parts = value.split('-');
    if (parts.length < 5) return -1;
    return int.tryParse(parts.last) ?? -1;
  }

  Future<bool> _observationIdExists(String observationId) async {
    final rootSnap = await FirestoreDb.db
        .collection('terrain_forms')
        .where('observationId', isEqualTo: observationId)
        .limit(1)
        .get();
    final rootHasOther = rootSnap.docs.any((d) => d.id != widget.formId);
    if (rootHasOther) return true;

    final nestedSnap = await FirestoreDb.db
        .collection('terrain_forms')
        .where('data.gen_idObservation', isEqualTo: observationId)
        .limit(1)
        .get();
    return nestedSnap.docs.any((d) => d.id != widget.formId);
  }

  Future<String> generateObservationId(DateTime date) async {
    final dateKey = _formatYyyyMmDd(date);
    final docs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    final byRootDate = await FirestoreDb.db
        .collection('terrain_forms')
        .where('observationDate', isEqualTo: dateKey)
        .get();
    docs.addAll(byRootDate.docs);

    if (docs.isEmpty) {
      final byDataDate = await FirestoreDb.db
          .collection('terrain_forms')
          .where('data.gen_date', isEqualTo: dateKey)
          .get();
      docs.addAll(byDataDate.docs);
    }

    var next = docs.length + 1;
    for (final doc in docs) {
      final rootId = (doc.data()['observationId'] ?? '').toString();
      final dataMap = (doc.data()['data'] as Map<String, dynamic>?) ?? {};
      final nestedId = (dataMap['gen_idObservation'] ?? '').toString();
      final candidate = rootId.isNotEmpty ? rootId : nestedId;
      if (candidate.startsWith('OBS-TN-$dateKey-')) {
        final suffix = _extractSuffix(candidate);
        if (suffix >= next) next = suffix + 1;
      }
    }

    var generated = 'OBS-TN-$dateKey-${next.toString().padLeft(3, '0')}';
    while (await _observationIdExists(generated)) {
      next += 1;
      generated = 'OBS-TN-$dateKey-${next.toString().padLeft(3, '0')}';
    }
    return generated;
  }

  Future<void> _generateAndSetObservationId(DateTime date) async {
    setState(() => _isGeneratingObservationId = true);
    try {
      final generated = await generateObservationId(date);
      if (!mounted) return;
      setState(() => _idObservationCtrl.text = generated);
      data['gen_idObservation'] = generated;
      data['observationId'] = generated;
      data['observationDate'] = _formatYyyyMmDd(date);
      _service.scheduleFullDataSave(widget.formId, data);
    } on FirebaseException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur génération ID')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur génération ID')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingObservationId = false);
    }
  }

  Future<void> _ensureUniqueObservationIdBeforeContinue() async {
    final dateTxt = _dateCtrl.text.trim();
    if (dateTxt.isEmpty) return;
    if (_idObservationCtrl.text.trim().isEmpty) {
      final parsed = DateTime.tryParse(dateTxt);
      if (parsed != null) await _generateAndSetObservationId(parsed);
      return;
    }
    final exists = await _observationIdExists(_idObservationCtrl.text.trim());
    if (exists) {
      final parsed = DateTime.tryParse(dateTxt);
      if (parsed != null) await _generateAndSetObservationId(parsed);
    }
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
      final txt = _formatYyyyMmDd(picked);
      setState(() => _dateCtrl.text = txt);
      data['gen_date'] = txt;
      _service.scheduleFullDataSave(widget.formId, data);
      if (!_hasExistingObservationId) {
        await _generateAndSetObservationId(picked);
      }
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
      final txt = '$hh:$mm';
      setState(() => ctrl.text = txt);
      data[key] = txt;
      _service.scheduleFullDataSave(widget.formId, data);
    }
  }

  Future<void> _goNext() async {
    await _ensureUniqueObservationIdBeforeContinue();
    if (!mounted) return;
    _service.updateFormData(widget.formId, data, stepCompleted: 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SuiviPage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToTerrainHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => Matrice1Home(formId: widget.formId),
      ),
      (route) => route.isFirst,
    );
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

  Widget _buildStringDropdown({
    required String label,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: _dec(label),
      hint: const Text('Choisir...'),
      items: options
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: onChanged,
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
                        onPressed: _goToTerrainHome,
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
                          decoration: _dec('Enquêteur (nom et prénom)'),
                          onChanged: (v) {
                            data['gen_idEnqueteur'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _idObservationCtrl,
                          readOnly: true,
                          decoration: _dec(
                            'ID observation',
                            suffixIcon: _isGeneratingObservationId
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : const Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _dec(
                            'Date',
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
                          onTap: () => _pickTime24h(_heureCtrl, 'gen_heure'),
                          decoration: _dec(
                            "Heure de l'observation (24h)",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () => _pickTime24h(_heureCtrl, 'gen_heure'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: _qcFlag,
                          isExpanded: true,
                          decoration: _dec('QC_Flag (0=OK, 1=à vérifier, 2=manquant)'),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text('0 - OK')),
                            DropdownMenuItem(value: 1, child: Text('1 - À vérifier')),
                            DropdownMenuItem(value: 2, child: Text('2 - Manquant')),
                          ],
                          onChanged: (v) {
                            setState(() => _qcFlag = v);
                            if (v != null) {
                              data['gen_qcFlag'] = v;
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        _buildStringDropdown(
                          label: 'Pays',
                          options: _paysOptions,
                          value: _selectedPays,
                          onChanged: (v) {
                            setState(() => _selectedPays = v);
                            if (v != null) {
                              _paysCtrl.text = v;
                              data['gen_pays'] = v;
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStringDropdown(
                          label: 'Région',
                          options: _regionOptions,
                          value: _selectedRegion,
                          onChanged: (v) {
                            setState(() => _selectedRegion = v);
                            if (v != null) {
                              _regionCtrl.text = v;
                              data['gen_region'] = v;
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildStringDropdown(
                          label: 'Port de Pêche',
                          options: _portPecheOptions,
                          value: _selectedPortPeche,
                          onChanged: (v) {
                            setState(() => _selectedPortPeche = v);
                            if (v != null) {
                              _portPecheCtrl.text = v;
                              data['gen_portPeche'] = v;
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _zoneCtrl,
                          decoration: _dec('Zone (nom local)'),
                          onChanged: (v) {
                            data['gen_zone'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                      ]),
                      const SizedBox(height: 16),
                      _sectionCard(children: [
                        TextFormField(
                          controller: _longitudeCtrl,
                          decoration: _dec('Longitude (décimal)'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            data['gen_longitude'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _latitudeCtrl,
                          decoration: _dec('Latitude (décimal)'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            data['gen_latitude'] = v;
                            _service.scheduleFullDataSave(widget.formId, data);
                          },
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Enregistrer',
                              icon: Icons.save_rounded,
                              onPressed: () async {
                                await _ensureUniqueObservationIdBeforeContinue();
                                _service.updateFormData(
                                  widget.formId,
                                  data,
                                  stepCompleted: 1,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Données enregistrées')),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
