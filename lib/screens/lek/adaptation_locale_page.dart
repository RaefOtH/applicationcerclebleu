import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'etat_des_lieux_page.dart';
import 'lek_home.dart';


class AdaptationLocalePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const AdaptationLocalePage({super.key, required this.data, required this.formId});

  @override
  State<AdaptationLocalePage> createState() => _AdaptationLocalePageState();
}

class _AdaptationLocalePageState extends State<AdaptationLocalePage>
    with SingleTickerProviderStateMixin {
  static const List<String> _typeObservationOptions = [
    'À bord',
    'Au port',
    'Expérimental',
  ];

  static const List<_EnginOption> _enginOptions = [
    _EnginOption(
      label: 'Chaluts : (TBB,OTB,OTT,OTP,PTB,TB,OTM,PTM,TM,TSP,TX)',
      code: 'CHALUTS',
      group: 'chalut',
    ),
    _EnginOption(
      label: 'Senne tournante coulissante : PS',
      code: 'PS',
      group: 'minimal',
    ),
    _EnginOption(
      label: 'Filets tournants : SUX',
      code: 'SUX',
      group: 'minimal',
    ),
    _EnginOption(label: 'Filet encerclant : LA', code: 'LA', group: 'fenc'),
    _EnginOption(label: 'Seine de plage : SB', code: 'SB', group: 'minimal'),
    _EnginOption(label: 'Seine : SX', code: 'SX', group: 'minimal'),
    _EnginOption(
      label: 'Trémails et maillants combinés : GTN',
      code: 'GTN',
      group: 'comb',
    ),
    _EnginOption(
      label: 'Filets maillants dérivants : GND',
      code: 'GND',
      group: 'minimal',
    ),
    _EnginOption(
      label: 'Filets maillants encerclants : GNC',
      code: 'GNC',
      group: 'minimal',
    ),
    _EnginOption(
      label: 'Trémails : (GTR, GTRcrev, GTRseiche)',
      code: 'GTR',
      group: 'tr',
    ),
    _EnginOption(
      label: 'Filets monofilament : MoFi',
      code: 'MoFi',
      group: 'mofi',
    ),
    _EnginOption(
      label: 'Pièges (Nasses,casiers,pierre,gargoulettes,Verveux...) : FIX',
      code: 'FIX',
      group: 'fix',
    ),
    _EnginOption(label: 'Autre (préciser)', code: 'AUTRE', group: 'minimal'),
  ];

  static final Map<String, List<_ConditionalFieldDef>> _conditionalFields = {
    'chalut': const [
      _ConditionalFieldDef('suivi_chalut_type', 'Type de chalut'),
      _ConditionalFieldDef(
        'suivi_chalut_longueurRalingueInf',
        'Longueur ralingue inférieure',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_chalut_ouvertureVerticale',
        'Ouverture verticale',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_chalut_ouvertureHorizontale',
        'Ouverture horizontale',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_chalut_mailleCul',
        'Maille de cul de chalut',
        numeric: true,
      ),
      _ConditionalFieldDef('suivi_chalut_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_chalut_autre', 'Autre (préciser)'),
    ],
    'mofi': const [
      _ConditionalFieldDef('suivi_mofi_longueur', 'Longueur', numeric: true),
      _ConditionalFieldDef('suivi_mofi_hauteur', 'Hauteur', numeric: true),
      _ConditionalFieldDef('suivi_mofi_maille', 'Maille', numeric: true),
      _ConditionalFieldDef(
        'suivi_mofi_nbPiecesArmement',
        'Nbre de pièces par armement',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_mofi_nbArmements',
        'Nbre armements',
        numeric: true,
      ),
      _ConditionalFieldDef('suivi_mofi_typeFiletDroit', 'Type de filet droit'),
      _ConditionalFieldDef('suivi_mofi_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_mofi_autre', 'Autre (préciser)'),
    ],
    'comb': const [
      _ConditionalFieldDef('suivi_comb_longueur', 'Longueur', numeric: true),
      _ConditionalFieldDef('suivi_comb_hauteur', 'Hauteur', numeric: true),
      _ConditionalFieldDef(
        'suivi_comb_mailleCentrale',
        'Maille / Maille centrale',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_comb_mailleExterieure',
        'Maille extérieure',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_comb_nbPiecesArmement',
        'Nbre de pièces par armement',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_comb_nbArmements',
        'Nbre armements',
        numeric: true,
      ),
      _ConditionalFieldDef('suivi_comb_typeFiletDroit', 'Type de filet droit'),
      _ConditionalFieldDef('suivi_comb_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_comb_autre', 'Autre (préciser)'),
    ],
    'tr': const [
      _ConditionalFieldDef('suivi_tr_longueur', 'Longueur', numeric: true),
      _ConditionalFieldDef('suivi_tr_hauteur', 'Hauteur', numeric: true),
      _ConditionalFieldDef(
        'suivi_tr_mailleCentrale',
        'Maille / Maille centrale',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_tr_mailleExterieure',
        'Maille extérieure',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_tr_nbPiecesArmement',
        'Nbre de pièces par armement',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_tr_nbArmements',
        'Nbre armements',
        numeric: true,
      ),
      _ConditionalFieldDef('suivi_tr_typeFiletDroit', 'Type de filet droit'),
      _ConditionalFieldDef('suivi_tr_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_tr_autre', 'Autre (préciser)'),
    ],
    'fenc': const [
      _ConditionalFieldDef('suivi_fenc_longueur', 'Longueur', numeric: true),
      _ConditionalFieldDef(
        'suivi_fenc_hauteurChute',
        'Hauteur (chute)',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_fenc_mailleAile',
        'Maille aile',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_fenc_maillePoche',
        'Maille poche',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_fenc_typeFiletTournant',
        'Type de filet tournant',
      ),
      _ConditionalFieldDef('suivi_fenc_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_fenc_autre', 'Autre (préciser)'),
    ],
    'fix': const [
      _ConditionalFieldDef('suivi_fix_diametre', 'Diamètre', numeric: true),
      _ConditionalFieldDef('suivi_fix_hauteur', 'Hauteur', numeric: true),
      _ConditionalFieldDef('suivi_fix_ouverture', 'Ouverture', numeric: true),
      _ConditionalFieldDef('suivi_fix_maille', 'Maille', numeric: true),
      _ConditionalFieldDef('suivi_fix_nbre', 'Nbre', numeric: true),
      _ConditionalFieldDef('suivi_fix_typePiege', 'Type de piège'),
      _ConditionalFieldDef('suivi_fix_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_fix_autre', 'Autre (préciser)'),
    ],
    'minimal': const [
      _ConditionalFieldDef('suivi_engin_nomLocal', 'Nom local'),
      _ConditionalFieldDef('suivi_engin_autre', 'Autre (préciser)'),
    ],
  };

  static final Set<String> _legacyConditionalKeys = {
    'suivi_nc_diametre',
    'suivi_nc_hauteur',
    'suivi_nc_ouverture',
    'suivi_nc_maille',
    'suivi_nc_nbre',
    'suivi_nc_typeNasses',
    'suivi_p_diametre',
    'suivi_p_nbre',
    'suivi_p_typePieges',
  };

  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _typeEnginAutreCtrl = TextEditingController();
  final _nbPiecesCtrl = TextEditingController();
  final _idNavireCtrl = TextEditingController();
  final _idNasseCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final Map<String, TextEditingController> _dynamicCtrls = {};
  String? _selectedTypeObservation;
  _EnginOption? _selectedEnginOption;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _selectedTypeObservation = _safeOption(
      data['suivi_typeObservation'],
      _typeObservationOptions,
    );
    _typeEnginAutreCtrl.text = (data['suivi_typeEnginAutre'] ?? '').toString();
    _nbPiecesCtrl.text = (data['suivi_nbPieces'] ?? '').toString();
    _idNavireCtrl.text = (data['suivi_idNavire'] ?? '').toString();
    _idNasseCtrl.text = (data['suivi_idNasse'] ?? '').toString();
    _debutCtrl.text = (data['suivi_debut'] ?? '').toString();
    _finCtrl.text = (data['suivi_fin'] ?? '').toString();

    final savedLabel = (data['suivi_typeEngin'] ?? '').toString().trim();
    final savedCode = (data['suivi_typeEnginCode'] ?? '').toString().trim();
    _selectedEnginOption = _findEnginOption(savedLabel, savedCode);

    for (final defs in _conditionalFields.values) {
      for (final def in defs) {
        _dynamicCtrls.putIfAbsent(
          def.key,
          () => TextEditingController(text: (data[def.key] ?? '').toString()),
        );
      }
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _typeEnginAutreCtrl.dispose();
    _nbPiecesCtrl.dispose();
    _idNavireCtrl.dispose();
    _idNasseCtrl.dispose();
    _debutCtrl.dispose();
    _finCtrl.dispose();
    for (final ctrl in _dynamicCtrls.values) {
      ctrl.dispose();
    }
    _waveController.dispose();
    super.dispose();
  }

  _EnginOption? _findEnginOption(String label, String code) {
    for (final option in _enginOptions) {
      if (label.isNotEmpty && option.label == label) return option;
      if (code.isNotEmpty && option.code == code) return option;
    }
    return null;
  }

  String? _safeOption(dynamic raw, List<String> options) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) => InputDecoration(
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

  void _onTypeEnginChanged(_EnginOption? option) {
    setState(() => _selectedEnginOption = option);
    if (option == null) {
      data.remove('suivi_typeEngin');
      data.remove('suivi_typeEnginCode');
    } else {
      data['suivi_typeEngin'] = option.label;
      data['suivi_typeEnginCode'] = option.code;
    }
    _clearInactiveConditionalData();
    if (option == null || option.code != 'AUTRE') {
      _typeEnginAutreCtrl.clear();
      data.remove('suivi_typeEnginAutre');
    }
    _service.scheduleFullDataSave(widget.formId, data);
  }

  void _clearInactiveConditionalData() {
    final activeGroup = _selectedEnginOption?.group;
    for (final entry in _conditionalFields.entries) {
      if (entry.key == activeGroup) continue;
      for (final def in entry.value) {
        data.remove(def.key);
        _dynamicCtrls[def.key]?.clear();
      }
    }
    for (final key in _legacyConditionalKeys) {
      data.remove(key);
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String key,
    bool numeric = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: _dec(label, suffixIcon: suffixIcon),
      onChanged: (v) {
        data[key] = v;
        _service.scheduleFullDataSave(widget.formId, data);
      },
    );
  }

  Widget _buildConditionalSection() {
    final group = _selectedEnginOption?.group;
    if (group == null) return const SizedBox.shrink();
    final defs = _conditionalFields[group];
    if (defs == null || defs.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Détails type d'engin",
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(defs.length, (index) {
          final def = defs[index];
          final widget = _field(
            controller: _dynamicCtrls[def.key]!,
            label: def.label,
            key: def.key,
            numeric: def.numeric,
          );
          if (index == defs.length - 1) return widget;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget,
          );
        }),
      ],
    );
  }

  void _goNext() {
    if (_selectedTypeObservation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir un type d'observation."),
        ),
      );
      return;
    }
    if (_selectedEnginOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir un type d'engin.")),
      );
      return;
    }
    if (_selectedEnginOption!.code == 'AUTRE' &&
        _typeEnginAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez préciser le type d'engin.")),
      );
      return;
    }
    data['suivi_typeObservation'] = _selectedTypeObservation!;
    data['suivi_typeEngin'] = _selectedEnginOption!.label;
    data['suivi_typeEnginCode'] = _selectedEnginOption!.code;
    if (_selectedEnginOption!.code == 'AUTRE') {
      data['suivi_typeEnginAutre'] = _typeEnginAutreCtrl.text.trim();
    } else {
      data.remove('suivi_typeEnginAutre');
    }
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EtatDesLieuxPage(formId: widget.formId, data: data),
      ),
    );
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
                          DropdownButtonFormField<String>(
                            initialValue: _selectedTypeObservation,
                            isExpanded: true,
                            decoration: _dec("Type d'observation"),
                            hint: const Text('Choisir...'),
                            items: _typeObservationOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedTypeObservation = value);
                              if (value == null) {
                                data.remove('suivi_typeObservation');
                              } else {
                                data['suivi_typeObservation'] = value;
                              }
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<_EnginOption>(
                            initialValue: _selectedEnginOption,
                            isExpanded: true,
                            decoration: _dec("Type d'engin"),
                            hint: const Text('Choisir...'),
                            items: _enginOptions
                                .map(
                                  (option) => DropdownMenuItem<_EnginOption>(
                                    value: option,
                                    child: Text(
                                      option.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: _onTypeEnginChanged,
                          ),
                          if (_selectedEnginOption?.code == 'AUTRE') ...[
                            const SizedBox(height: 12),
                            _field(
                              controller: _typeEnginAutreCtrl,
                              label: 'Préciser',
                              key: 'suivi_typeEnginAutre',
                            ),
                          ],
                          if (_selectedEnginOption != null) ...[
                            const SizedBox(height: 12),
                            _buildConditionalSection(),
                          ],
                          const SizedBox(height: 12),
                          _field(
                            controller: _nbPiecesCtrl,
                            label: 'Nombre de pièces (nasse/filet)',
                            key: 'suivi_nbPieces',
                            numeric: true,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _idNavireCtrl,
                            label: 'ID du navire (Nom & Immatriculation)',
                            key: 'suivi_idNavire',
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _idNasseCtrl,
                            label: 'ID de la nasse',
                            key: 'suivi_idNasse',
                            numeric: true,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _debutCtrl,
                            label: 'Opération de pêche - Début (24h)',
                            key: 'suivi_debut',
                            readOnly: true,
                            onTap: () =>
                                _pickTime24h(_debutCtrl, 'suivi_debut'),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _pickTime24h(_debutCtrl, 'suivi_debut'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _finCtrl,
                            label: 'Opération de pêche - Fin (24h)',
                            key: 'suivi_fin',
                            readOnly: true,
                            onTap: () => _pickTime24h(_finCtrl, 'suivi_fin'),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.access_time),
                              onPressed: () =>
                                  _pickTime24h(_finCtrl, 'suivi_fin'),
                            ),
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

class _EnginOption {
  final String label;
  final String code;
  final String group;

  const _EnginOption({
    required this.label,
    required this.code,
    required this.group,
  });
}

class _ConditionalFieldDef {
  final String key;
  final String label;
  final bool numeric;

  const _ConditionalFieldDef(this.key, this.label, {this.numeric = false});
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
