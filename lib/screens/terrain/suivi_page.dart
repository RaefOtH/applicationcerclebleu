import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/terrain_form_service.dart';
import 'capture_page.dart';
import 'matrice1_home.dart';

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
  static const List<String> _enginCodeOptions = [
    "Senne tournante coulissante : PS",
    "Chaluts : CH (Crevettier, Mediterranien, GOV, pélagique)",
    "Filets tournants : FT",
    "Trémails et maillants combinés : TMC",
    "Filets maillants dérivants : MD",
    "Filets maillants encerclants : MEC",
    "Trémails : TR (poisson, Crevettes, Seiche)",
    "Filets monofilament : MoFi",
    "Nasses (casiers) : NC",
    "Pièges (pierre, gargoulettes, Verveux...) : P",
    "Autre (préciser)",
  ];

  static const List<String> _enginTypeOptions = [
    "chalut",
    "Monofilament",
    "combiné",
    "Trémail",
    "Filet encerclant",
    "Nasse",
    "piége",
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
    ],
    'Monofilament': const [
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
      _ConditionalFieldDef(
        'suivi_mofi_typeFiletDroit',
        'Type de filet droit',
      ),
    ],
    'combiné': const [
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
      _ConditionalFieldDef(
        'suivi_comb_typeFiletDroit',
        'Type de filet droit',
      ),
    ],
    'Trémail': const [
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
    ],
    'Filet encerclant': const [
      _ConditionalFieldDef('suivi_fenc_longueur', 'Longueur', numeric: true),
      _ConditionalFieldDef(
        'suivi_fenc_hauteurChute',
        'Hauteur (chute)',
        numeric: true,
      ),
      _ConditionalFieldDef('suivi_fenc_mailleAile', 'Maille aile', numeric: true),
      _ConditionalFieldDef(
        'suivi_fenc_maillePoche',
        'Maille poche',
        numeric: true,
      ),
      _ConditionalFieldDef(
        'suivi_fenc_typeFiletTournant',
        'Type de filet tournant',
      ),
    ],
    'Nasse': const [
      _ConditionalFieldDef('suivi_nc_diametre', 'Diamètre', numeric: true),
      _ConditionalFieldDef('suivi_nc_hauteur', 'Hauteur', numeric: true),
      _ConditionalFieldDef('suivi_nc_ouverture', 'Ouverture', numeric: true),
      _ConditionalFieldDef('suivi_nc_maille', 'Maille', numeric: true),
      _ConditionalFieldDef('suivi_nc_nbre', 'Nbre', numeric: true),
      _ConditionalFieldDef('suivi_nc_typeNasses', 'Type des nasses'),
    ],
    'piége': const [
      _ConditionalFieldDef('suivi_p_diametre', 'Diamètre', numeric: true),
      _ConditionalFieldDef('suivi_p_nbre', 'Nbre', numeric: true),
      _ConditionalFieldDef('suivi_p_typePieges', 'Type des pièges'),
    ],
  };

  late final Map<String, dynamic> data;
  final TerrainFormService _service = TerrainFormService();

  final _typeObservationCtrl = TextEditingController();
  final _typeEnginAutreCtrl = TextEditingController();
  final _nbPiecesCtrl = TextEditingController();
  final _idNavireCtrl = TextEditingController();
  final _idNasseCtrl = TextEditingController();
  final _debutCtrl = TextEditingController();
  final _finCtrl = TextEditingController();
  final Map<String, TextEditingController> _dynamicCtrls = {};
  String? _selectedEnginCode;
  String? _selectedEnginType;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
    _typeObservationCtrl.text =
        (data['suivi_typeObservation'] ?? '').toString();
    _typeEnginAutreCtrl.text = (data['suivi_typeEnginAutre'] ?? '').toString();
    _nbPiecesCtrl.text = (data['suivi_nbPieces'] ?? '').toString();
    _idNavireCtrl.text = (data['suivi_idNavire'] ?? '').toString();
    _idNasseCtrl.text = (data['suivi_idNasse'] ?? '').toString();
    _debutCtrl.text = (data['suivi_debut'] ?? '').toString();
    _finCtrl.text = (data['suivi_fin'] ?? '').toString();
    _selectedEnginCode =
        _safeOption(data['suivi_typeEnginCode'], _enginCodeOptions);
    _selectedEnginType =
        _safeOption(data['suivi_typeEngin'], _enginTypeOptions);

    for (final defs in _conditionalFields.values) {
      for (final def in defs) {
        _dynamicCtrls[def.key] =
            TextEditingController(text: (data[def.key] ?? '').toString());
      }
    }

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _typeObservationCtrl.dispose();
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

  String? _safeOption(dynamic raw, List<String> options) {
    final value = (raw ?? '').toString().trim();
    if (value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  InputDecoration _dec(String label, {Widget? suffixIcon}) => InputDecoration(
        labelText: label,
        hintText: 'Saisir ici...',
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 14,
        ),
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
      final txt = "$hh:$mm";
      setState(() => ctrl.text = txt);
      data[key] = txt;
      _service.scheduleFullDataSave(widget.formId, data);
    }
  }

  void _onTypeEnginChanged(String? value) {
    setState(() => _selectedEnginType = value);
    if (value != null) {
      data['suivi_typeEngin'] = value;
    }
    _clearInactiveConditionalData();
    _service.scheduleFullDataSave(widget.formId, data);
  }

  void _clearInactiveConditionalData() {
    final activeType = _selectedEnginType;
    for (final entry in _conditionalFields.entries) {
      if (entry.key == activeType) continue;
      for (final def in entry.value) {
        data.remove(def.key);
        _dynamicCtrls[def.key]?.clear();
      }
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

  String _sectionTitleForType(String type) {
    switch (type) {
      case 'chalut':
        return 'Détails Chalut';
      case 'Monofilament':
        return 'Détails Monofilament';
      case 'combiné':
        return 'Détails Combiné';
      case 'Trémail':
        return 'Détails Trémail';
      case 'Filet encerclant':
        return 'Détails Filet encerclant';
      case 'Nasse':
        return 'Détails Nasse';
      case 'piége':
        return 'Détails Piége';
      default:
        return 'Détails';
    }
  }

  Widget _buildConditionalSection() {
    final type = _selectedEnginType;
    if (type == null) return const SizedBox.shrink();
    final defs = _conditionalFields[type];
    if (defs == null || defs.isEmpty) return const SizedBox.shrink();

    return _sectionCard(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _sectionTitleForType(type),
            style: const TextStyle(
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
          if (index == defs.length - 1) {
            return widget;
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: widget,
          );
        }),
      ],
    );
  }

  void _goNext() {
    if (_selectedEnginCode == "Autre (préciser)" &&
        _typeEnginAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez préciser l'autre type d'engin.")),
      );
      return;
    }
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturePage(formId: widget.formId, data: data),
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
                        'Suivi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\u00C9tape 2/5',
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
                        _field(
                          controller: _typeObservationCtrl,
                          label:
                              "Type d'observation (\u00E0 bord / au port / exp\u00E9rimental)",
                          key: 'suivi_typeObservation',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEnginCode,
                          isExpanded: true,
                          decoration: _dec("Type d'engin (code)"),
                          hint: const Text('Choisir...'),
                          items: _enginCodeOptions
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
                            setState(() => _selectedEnginCode = value);
                            if (value != null) {
                              data['suivi_typeEnginCode'] = value;
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                            if (value != "Autre (préciser)") {
                              _typeEnginAutreCtrl.clear();
                              data.remove('suivi_typeEnginAutre');
                              _service.scheduleFullDataSave(widget.formId, data);
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        if (_selectedEnginCode == "Autre (préciser)") ...[
                          _field(
                            controller: _typeEnginAutreCtrl,
                            label: "Autre type d'engin (précisez)",
                            key: 'suivi_typeEnginAutre',
                          ),
                          const SizedBox(height: 12),
                        ],
                        DropdownButtonFormField<String>(
                          initialValue: _selectedEnginType,
                          isExpanded: true,
                          decoration: _dec("Type d'engin"),
                          hint: const Text('Choisir...'),
                          items: _enginTypeOptions
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
                          onChanged: _onTypeEnginChanged,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _nbPiecesCtrl,
                          label: "Nombre de pièces (nasse/filet)",
                          key: 'suivi_nbPieces',
                          numeric: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _idNavireCtrl,
                          label: "ID du navire (Nom & Immatriculation)",
                          key: 'suivi_idNavire',
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _idNasseCtrl,
                          label: "ID de la nasse",
                          key: 'suivi_idNasse',
                          numeric: true,
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _debutCtrl,
                          label: "Op\u00E9ration de p\u00EAche - D\u00E9but (24h)",
                          key: 'suivi_debut',
                          readOnly: true,
                          onTap: () => _pickTime24h(_debutCtrl, 'suivi_debut'),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () =>
                                _pickTime24h(_debutCtrl, 'suivi_debut'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _field(
                          controller: _finCtrl,
                          label: "Op\u00E9ration de p\u00EAche - Fin (24h)",
                          key: 'suivi_fin',
                          readOnly: true,
                          onTap: () => _pickTime24h(_finCtrl, 'suivi_fin'),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () => _pickTime24h(_finCtrl, 'suivi_fin'),
                          ),
                        ),
                      ]),
                      if (_selectedEnginType != null) ...[
                        const SizedBox(height: 16),
                        _buildConditionalSection(),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Pr\u00E9c\u00E9dent',
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

class _ConditionalFieldDef {
  final String key;
  final String label;
  final bool numeric;

  const _ConditionalFieldDef(
    this.key,
    this.label, {
    this.numeric = false,
  });
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
