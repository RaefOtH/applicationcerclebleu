import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'general_page.dart';
import 'lek_home.dart';
import 'unite_de_peche_page.dart';

class InfoPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const InfoPage({super.key, required this.data, required this.formId});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>
    with SingleTickerProviderStateMixin {
  static const List<String> _niveauEducationOptions = [
    'Sans instruction (SI)',
    'Primaire (Pr)',
    'Moyen (Mo)',
    'Secondaire (Sec)',
    'Universitaire (Univ)',
  ];

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();

  final _codePecheurCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _niveauCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _otherActivityController = TextEditingController();

  String? _selectedGenre;
  String? _selectedProprietaireLocataire;
  String? _selectedRole;
  String? _selectedNiveauEducation;
  String? _selectedCnss;
  String? _selectedActivity;

  late AnimationController _waveController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _codePecheurCtrl.text = (data['info_code_du_pecheur'] ?? '').toString();
    _ageCtrl.text = (data['info_age'] ?? '').toString();

    // Récupération de l'expérience (extraction du nombre si déjà présent sous forme "X ans")
    final rawExp = (data['info_experience'] ?? '').toString();
    final expNum = RegExp(r'\d+').firstMatch(rawExp)?.group(0) ?? rawExp;
    _experienceCtrl.text = expNum;

    _niveauCtrl.text = (data['info_niveauInstruction'] ?? '').toString();
    _zoneCtrl.text = (data['info_zone_de_Peche'] ?? '').toString();

    _selectedGenre = _nullIfEmpty(data['info_genre']);
    _selectedProprietaireLocataire = _nullIfEmpty(data['info_etat_civil']);
    _selectedRole = _nullIfEmpty(data['info_role_à_bord_du_bateau']);
    
    _selectedNiveauEducation = _normalizeStringOption(
      _niveauCtrl.text,
      _niveauEducationOptions,
    );

    _selectedCnss = _nullIfEmpty(data['info_cnss']);
    _selectedActivity = _nullIfEmpty(data['info_peche_activité']);
    _otherActivityController.text = (data['info_peche_activité_precision'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  static String? _nullIfEmpty(dynamic v) {
    final s = (v ?? '').toString().trim();
    return s.isEmpty ? null : s;
  }

  String? _normalizeStringOption(dynamic value, List<String> options) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return options.contains(raw) ? raw : null;
  }

  @override
  void dispose() {
    _codePecheurCtrl.dispose();
    _ageCtrl.dispose();
    _experienceCtrl.dispose();
    _niveauCtrl.dispose();
    _zoneCtrl.dispose();
    _otherActivityController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {Widget? suffixIcon, String? suffixText}) => InputDecoration(
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
        suffixText: suffixText,
        suffixStyle: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w600),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String key,
    bool numeric = false,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: false)
          : TextInputType.text,
      decoration: _dec(label, suffixIcon: suffixIcon, suffixText: suffixText),
      onChanged: (v) {
        data[key] = v;
        _service.scheduleFullDataSave(widget.formId, data);
      },
    );
  }

  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniteDePechePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goBack() {
    _service.updateFormData(widget.formId, data, stepCompleted: 1);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InformationsGeneralesPage(
          formId: widget.formId,
          data: data,
        ),
      ),
    );
  }

  void _goToLekHome() {
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
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
                        "Informations sur l'enquêté",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 2/9',
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
                          Form(
                            key: _formKey,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            child: Column(
                              children: [
                                _field(
                                  controller: _codePecheurCtrl,
                                  label: 'Nom ou code du pêcheur (facultatif)',
                                  key: 'info_code_du_pecheur',
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  controller: _ageCtrl,
                                  label: 'Age',
                                  key: 'info_age',
                                  numeric: true,
                                ),
                                const SizedBox(height: 12),
                                _buildStringDropdown(
                                  label: 'Genre',
                                  options: const ['Homme', 'Femme', 'Autre'],
                                  value: _selectedGenre,
                                  onChanged: (v) {
                                    setState(() => _selectedGenre = v);
                                    data['info_genre'] = v ?? '';
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                // CHAMP EXPÉRIENCE MODIFIÉ (Nombre d'années)
                                _field(
                                  controller: _experienceCtrl,
                                  label: "Expérience (Nombre d'années)",
                                  key: 'info_experience',
                                  numeric: true,
                                  suffixText: 'ans',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "L'expérience est requise !";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildStringDropdown(
                                  label: 'Propriétaire / Locataire',
                                  options: const ['Propriétaire', 'Locataire'],
                                  value: _selectedProprietaireLocataire,
                                  onChanged: (v) {
                                    setState(() => _selectedProprietaireLocataire = v);
                                    data['info_etat_civil'] = v ?? '';
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildStringDropdown(
                                  label: 'Rôle',
                                  options: const ['Capitaine', 'Marin'],
                                  value: _selectedRole,
                                  onChanged: (v) {
                                    setState(() => _selectedRole = v);
                                    data['info_role_à_bord_du_bateau'] = v ?? '';
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildStringDropdown(
                                  label: "Niveau d'éducation",
                                  options: _niveauEducationOptions,
                                  value: _selectedNiveauEducation,
                                  onChanged: (v) {
                                    setState(() => _selectedNiveauEducation = v);
                                    if (v == null) {
                                      data.remove('info_niveauInstruction');
                                      _niveauCtrl.clear();
                                    } else {
                                      data['info_niveauInstruction'] = v;
                                      _niveauCtrl.text = v;
                                    }
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildStringDropdown(
                                  label: 'Affiliation CNSS',
                                  options: const ['Oui', 'Non'],
                                  value: _selectedCnss,
                                  onChanged: (v) {
                                    setState(() => _selectedCnss = v);
                                    data['info_cnss'] = v ?? '';
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedActivity,
                                  isExpanded: true,
                                  decoration: _dec('Pêche: activité principale'),
                                  items: const ['Oui', 'Non', 'Autre']
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
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedActivity = newValue;
                                    });
                                    if (newValue == 'Autre') {
                                      _otherActivityController.clear();
                                      data['info_peche_activité'] = 'Autre';
                                    } else {
                                      data['info_peche_activité'] = newValue ?? '';
                                      data['info_peche_activité_precision'] = '';
                                    }
                                    _service.scheduleFullDataSave(widget.formId, data);
                                  },
                                ),
                                if (_selectedActivity == 'Autre') ...[
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _otherActivityController,
                                    decoration: _dec('Veuillez préciser votre activité'),
                                    onChanged: (text) {
                                      data['info_peche_activité_precision'] = text;
                                      _service.scheduleFullDataSave(widget.formId, data);
                                    },
                                  ),
                                ],
                                const SizedBox(height: 12),
                                _field(
                                  controller: _zoneCtrl,
                                  label: 'Zone de pêche',
                                  key: 'info_zone_de_Peche',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'La zone de pêche est requise !';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _OutlineButton(
                                  text: 'Précédent',
                                  icon: Icons.arrow_back,
                                  onPressed: _goBack,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PrimaryGradientButton(
                                  text: 'Suivant',
                                  icon: Icons.arrow_forward,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      _goNext();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Veuillez remplir les champs obligatoires (Expérience / Zone).",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
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