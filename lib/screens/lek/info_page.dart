import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'unite_de_peche_page.dart';
import 'general_page.dart';
import 'lek_home.dart';

class InfoPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const InfoPage({super.key, required this.data, required this.formId});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage>
    with SingleTickerProviderStateMixin {

  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();

  final _CodePecheurCtrl = TextEditingController();
  final _AgeCtrl = TextEditingController();
  final _GenreCtrl = TextEditingController();
  final _ExperienceCtrl = TextEditingController();
  final _EtatCtrl = TextEditingController();
  final _RoleCtrl = TextEditingController();
  final _NiveauCtrl = TextEditingController();
  final _Cnsstrl = TextEditingController();
  final _PecheActCtrl = TextEditingController();
  final _ZoneCtrl = TextEditingController();
  final Map<String, TextEditingController> _dynamicCtrls = {};

  late AnimationController _waveController;
  String? _selectedExperience;
  String? _selectedZone;
  String? _selectedActivity;
final TextEditingController _otherActivityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _CodePecheurCtrl.text = (data['info_code_du_pecheur'] ?? '').toString();
    _AgeCtrl.text = (data['info_age'] ?? '').toString();
    _GenreCtrl.text = (data['info_genre'] ?? '').toString();
    _ExperienceCtrl.text = (data['info_experience'] ?? '').toString();
    _EtatCtrl.text = (data['info_etat_civil'] ?? '').toString();
    _RoleCtrl.text = (data['info_role_à_bord_du_bateau'] ?? '').toString();
    _NiveauCtrl.text = (data['info_niveauInstruction'] ?? '').toString();
    _Cnsstrl.text = (data['info_cnss'] ?? '').toString();
    _PecheActCtrl.text = (data['info_peche_activité'] ?? '').toString();
    _ZoneCtrl.text = (data['info_zone_de_Peche'] ?? '').toString();

    //_selectedEnginOption = _findEnginOption(savedLabel, savedCode);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _CodePecheurCtrl.dispose();
    _AgeCtrl.dispose();
    _GenreCtrl.dispose();
    _ExperienceCtrl.dispose();
    _EtatCtrl.dispose();
    _RoleCtrl.dispose();
    _NiveauCtrl.dispose();
    _Cnsstrl.dispose();
    _PecheActCtrl.dispose();
    _ZoneCtrl.dispose();
    for (final ctrl in _dynamicCtrls.values) {
      ctrl.dispose();
    }
    _waveController.dispose();
    _otherActivityController.dispose();
    super.dispose();
  }
/* 
  _EnginOption? _findEnginOption(String label, String code) {
    for (final option in _enginOptions) {
      if (label.isNotEmpty && option.label == label) return option;
      if (code.isNotEmpty && option.code == code) return option;
    }
    return null;
  }*/

  String? _safeOption(dynamic raw) {
    if (raw.toString().isEmpty) {return null;}
    else {return raw.toString();}
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
/*
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
  }*/

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      DateTime start = picked.isBefore(now) ? picked : now;
      DateTime end = picked.isBefore(now) ? now : picked;
      int years = end.year - start.year;
      int months = end.month - start.month;
      int days = end.day - start.day;

      if (days < 0) {
      months--;
      // Trouver le dernier jour du mois précédent
      DateTime previousMonth = DateTime(end.year, end.month, 0);
      days += previousMonth.day;
    }

    // Ajustement des mois négatifs
    if (months < 0) {
      years--;
      months += 12;
    }

      String yearsText = "$years ${years > 1 ? 'ans' : 'an'}";
      String monthsText = "$months mois";
      String daysText = "$days ${days > 1 ? 'jours' : 'jour'}";

      final txt = "$yearsText, $monthsText et $daysText";
      setState(() => _ExperienceCtrl.text = txt);
      data['info_experience'] = txt;
      data['gen_DateObservation'] = txt;
      //_updateGeneratedObservationId();
      _service.scheduleFullDataSave(widget.formId, data);
    }
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
      validator: (value) {
        if ((value == null || value.isEmpty) && label=='Zone de pêche') {
          return 'Le champ Expérience et Zone ne peuvent pas être vides !';
        }
        return null;
      },
      onChanged: (v) {
        data[key] = v;
        _service.scheduleFullDataSave(widget.formId, data);
      },
    );
  }
/*
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
*/
  void _goNext() {
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniteDePechePage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToLekHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LekHome(formId: widget.formId)),
      (route) => route.isFirst,
    );
  }
  final _formKey = GlobalKey<FormState>();
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
                        "Informations sur l'enquête",
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
                        child: Column(children: [                          
                          /*
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
                          ],*/
                          _field(
                            controller: _CodePecheurCtrl,
                            label: 'Nom ou code du pêcheur (facultatif)',
                            key: 'Nom ou code du pêcheur (facultatif)',
                          ),

                          const SizedBox(height: 12),

                          _field(
                            controller: _AgeCtrl,
                            label: 'Age',
                            key: 'Age',
                            numeric: true,
                          ),

                          const SizedBox(height: 12),

                          _buildStringDropdown(
                            label: 'Genre',
                            options: ['Homme','Femme', 'Autre'],
                            value: null,
                            onChanged: (v) {
                              data['info_genre'] = v;
                             _service.scheduleFullDataSave(widget.formId, data);
                             },
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _ExperienceCtrl,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: _dec(
                              'Expérience (Depuis Quand?)',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: _pickDate,
                              ),
                            ),
                            validator: (value) {
                              if ((value == null || value.isEmpty)){
                              return 'Le champ Expérience et Zone ne peuvent pas être vides !';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildStringDropdown(
                            label: 'Propriétaire/ Locataire',
                            options: ['Propriétaire','Locataire'],
                            value: null,
                            onChanged: (v) {
                              data['info_etat_civil']=v;
                             _service.scheduleFullDataSave(widget.formId, data);
                             },
                          ),

                          const SizedBox(height: 12),

                          _buildStringDropdown(
                            label: 'Rôle',
                            options: ['Capitaine','Marin'],
                            value: null,
                            onChanged: (v) {
                              data['info_role_à_bord_du_bateau'] = v;
                             _service.scheduleFullDataSave(widget.formId, data);
                             },
                          ),

                          const SizedBox(height: 12),

                          _field(
                            controller: _NiveauCtrl,
                            label: 'Niveau éducation',
                            key: 'Niveau éducation',
                          ),

                          const SizedBox(height: 12),

                          _buildStringDropdown(
                            label: 'Affiliation CNSS',
                            options: ['Oui','Non'],
                            value: null,
                            onChanged: (v) {
                              data['info_cnss'] = v;
                             _service.scheduleFullDataSave(widget.formId, data);
                             },
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            initialValue: null,
                            isExpanded: true,
                            decoration: _dec('Pêche: activité principale'),
                            
                            items: ['Oui', 'Non', 'Autre']
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
                            }
                            else {
                              data['info_peche_activité'] = newValue;
                              data['info_peche_activité_precision'] = '';
                              _service.scheduleFullDataSave(widget.formId, data);
                            }},
                          ),

                          if (_selectedActivity == 'Autre') ...[
                            const SizedBox(height: 12), // Un petit espace visuel entre les deux champs
                            TextFormField(
                              controller: _otherActivityController,
                              decoration: _dec('Veuillez préciser votre activité'), // Utilise votre méthode _dec
                              onChanged: (text) {
                                data['info_peche_activité_precision'] = text;
                                _service.scheduleFullDataSave(widget.formId, data);
                              },
                            ),
                          ],

                          const SizedBox(height: 12),

                          _field(
                            controller: _ZoneCtrl,
                            label: 'Zone de pêche',
                            key: 'info_zone_de_Peche',
                          ),

                          /*TextFormField(
                            controller: _locationController,
                            readOnly: true, // Empêche l'utilisateur d'écrire n'importe quoi manuellement
                            decoration: InputDecoration(
                              labelText: 'Zone de pêche',
                              hintText: 'Cliquez sur l\'icône pour choisir',
                              border: const OutlineInputBorder(),
                              // Ajout d'un bouton map à la fin du champ textuel
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.map, color: Colors.blue),
                                onPressed: () => _selectLocation(context),
                              ),
                            ),
                          ),*/
                        ],
                      ),),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _OutlineButton(
                              text: 'Précédent',
                              icon: Icons.arrow_back,
                              onPressed: () {
                                _service.updateFormData(widget.formId, data, stepCompleted: 2);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InformationsGeneralesPage(formId: widget.formId, data:data),
                                    ),
                                  );}
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
                                }
                                else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                    content: Text("Veuillez choisir une date début Expérience/ Zone de pêche."),
                                    ),
                                  );}
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

  const _ConditionalFieldDef(this.key, this.label) : numeric = false;
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
