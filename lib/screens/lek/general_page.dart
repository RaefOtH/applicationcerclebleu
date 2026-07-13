import 'package:flutter/material.dart';

import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'lek_home.dart';
import 'info_page.dart';

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
  static const List<String> _regionOptionsI = ['Nord', 'Est', 'Ouest', 'Sud'];
  static const List<String> _regionOptionsT = ['Nord', 'Est', 'Sud'];
  static const Map<String, List<String>> _portsByRegionI = {
    'Nord': [
      'Chioggia',
      'Trieste',
      'Grado',
      'Savone',
      'Camogli',
      'Autre (préciser)',
    ],
    'Est': [
      'Ancône',
      'San Benedetto del Tronto',
      'Rimini',
      'Cesenatico',
      'Manfredonia',
      'Autre (préciser)',
    ],
    'Ouest': [
      'Palerme',
      'Fiumicino',
      'Civitavecchia',
      'Pouzzoles / Pozzuoli',
      'Porto Santo Stefano',
      'Autre (préciser)',
    ],
    'Sud': [
      'Mazara del Vallo',
      'Sciacca',
      'Portopalo di Capo Passero',
      'Gallipoli',
      'Tarente',
      'Autre (préciser)',
    ],
  };
  static const Map<String, List<String>> _portsByRegionT = {
    'Nord': [
      'Bizerte',
      'Borj Cédria',
      'Cap.Zebib',
      'Ezzahra',
      'Ghar.El melh',
      'Hammam lif',
      'Hammamet',
      'Hawaria',
      'K. Andalous',
      'Kélibia',
      'La Goulette',
      'Lac Nord',
      'Mel. A.errahman',
      'Rades',
      'Raoued',
      'Sidi Bou Said',
      'Sidi Daoud',
      'Sidi Mechreg',
      'Soluman',
      'Tabarka',
      'Autre (préciser)',
    ],
    'Est': [
      'Bekalta',
      'Beni Khiar',
      'Chebba',
      'Essaloum',
      'Hergla',
      'Khnis',
      'Ksibet el Madiouni',
      'Mahdia',
      'Melloulech',
      'Monastir',
      'Port el Kantaoui',
      'Salakta',
      'Sayada',
      'Sidi Abdelhamid',
      'Sousse',
      'Teboulba',
      'Autre (préciser)',
    ],
    'Sud': [
      'Ajim',
      'Attaya',
      'Biban',
      'Boughrara',
      'El Akarit',
      'El Awabid',
      'Elgreen',
      'Elketf',
      'Ellouza',
      'Gabes',
      'Ghannouche',
      'Hassi Jallaba',
      'Houmtsouk',
      'Kratten',
      'Mahres',
      'Mellita',
      'Sfax',
      'Skhira',
      'Zarrat',
      'Zarzis',
      'Autre (préciser)',
    ],
  };


  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();

  final _numeroInterviewCtrl = TextEditingController();
  final _idEnqueteurCtrl = TextEditingController();
  //final _numeroEchantillonCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  //final _heureCtrl = TextEditingController();
  final _paysCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _portPecheCtrl = TextEditingController();
  final _portPecheAutreCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  final _typePecheCtrl = TextEditingController();
  //final _latitudeCtrl = TextEditingController();

  int? _qcFlag;
  String? _selectedPays;
  String? _selectedRegion;
  String? _selectedPortPeche;
  String? _numeroInterviewHint;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;

    _numeroInterviewCtrl.text = (data["gen_Numéro_de_l'interview"] ?? '').toString();
    _idEnqueteurCtrl.text = (data["gen_nom_de_l'enquêteur"] ?? '').toString();
    _dateCtrl.text = (data["gen_Date"] ?? '').toString();
    _paysCtrl.text = (data["gen_pays"] ?? '').toString();
    _regionCtrl.text = (data["gen_region"] ?? '').toString();
    _portPecheCtrl.text = (data["gen_portPeche"] ?? '').toString();
    _portPecheAutreCtrl.text = (data["gen_portPecheAutre"] ?? '').toString();
    _zoneCtrl.text = (data["gen_Zone"] ?? '').toString();
    _typePecheCtrl.text = (data["gen_Type_Pêche"] ?? '').toString();

    _selectedPays = _normalizeStringOption(data["gen_pays"], _paysOptions);
    _selectedPays=='Tunisie' ?
    _selectedRegion = _normalizeStringOption(
      data["gen_region"],
      _regionOptionsT,
    ) : _selectedRegion = _normalizeStringOption(
      data["gen_region"],
      _regionOptionsI,
    );
    

    final currentPortsI = _portsByRegionI[_selectedRegion] ?? const <String>[];
    final currentPortsT = _portsByRegionT[_selectedRegion] ?? const <String>[];

    final savedPort = (data["gen_portPeche"] ?? '').toString().trim();
    final savedPortAutre = (data["gen_portPecheAutre"] ?? '').toString().trim();
    
    if(_selectedPays=='Tunisie'){
      if (currentPortsT.contains(savedPort)) {
      _selectedPortPeche = savedPort;
    } else if (savedPort == 'Autre' ||
        savedPort == 'Autre (préciser)' ||
        (savedPort.isNotEmpty && currentPortsT.isNotEmpty)) {
      _selectedPortPeche = 'Autre (préciser)';
      if (_portPecheAutreCtrl.text.trim().isEmpty &&
          savedPortAutre.isNotEmpty) {
        _portPecheAutreCtrl.text = savedPortAutre;
      } else if (_portPecheAutreCtrl.text.trim().isEmpty &&
          savedPort.isNotEmpty) {
        _portPecheAutreCtrl.text = savedPort;
      }
    }
    }
    else{
      if (currentPortsI.contains(savedPort)) {
      _selectedPortPeche = savedPort;
    } else if (savedPort == 'Autre' ||
        savedPort == 'Autre (préciser)' ||
        (savedPort.isNotEmpty && currentPortsI.isNotEmpty)) {
      _selectedPortPeche = 'Autre (préciser)';
      if (_portPecheAutreCtrl.text.trim().isEmpty &&
          savedPortAutre.isNotEmpty) {
        _portPecheAutreCtrl.text = savedPortAutre;
      } else if (_portPecheAutreCtrl.text.trim().isEmpty &&
          savedPort.isNotEmpty) {
        _portPecheAutreCtrl.text = savedPort;
      }
    }
    }
    //_updateGeneratedObservationId();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _numeroInterviewCtrl.dispose();
    _idEnqueteurCtrl.dispose();
    _dateCtrl.dispose();
    _paysCtrl.dispose();
    _regionCtrl.dispose();
    _portPecheCtrl.dispose();
    _portPecheAutreCtrl.dispose();
    _zoneCtrl.dispose();
    _typePecheCtrl.dispose();
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


  List<String> _portsForSelectedRegion() {
    if(_selectedPays=='Tunisie'){
      return _portsByRegionT[_selectedRegion] ?? const <String>[];
    }
    else{
      return _portsByRegionI[_selectedRegion] ?? const <String>[];
    }
  }

  bool get _isAutrePortSelected => _selectedPortPeche == 'Autre (préciser)';


  bool _validateGeneratedObservationId() {
    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une région.')),
      );
      return false;
    }
    if (_selectedPortPeche == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un port de pêche.')),
      );
      return false;
    }
    if (_isAutrePortSelected && _portPecheAutreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez préciser le port de pêche.')),
      );
      return false;
    }
    //_updateGeneratedObservationId();
    if (_numeroInterviewCtrl.text.trim().isNotEmpty) {
      _service.scheduleFullDataSave(widget.formId, data);
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Complétez pays, région, port, date et le type de pêche.",
        ),
      ),
    );
    return false;
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
      data["gen_Date"] = txt;
      data["gen_DateObservation"] = txt;
      //_updateGeneratedObservationId();
      _service.scheduleFullDataSave(widget.formId, data);
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
    if (!_validateGeneratedObservationId()) return;
    if (!mounted) return;
    _service.updateFormData(widget.formId, data, stepCompleted: 1);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InfoPage(formId: widget.formId, data: data),
      ),
    );
  }

  void _goToLekHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LekHome(formId: widget.formId)),
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
      validator: (value) {
        if (value == null && label=='Région'){
          return 'Veuillez sélectionner une région !';
        }
        return null;
      },
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
                        'Informations générales',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Étape 1/9',
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
                          TextFormField(
                            controller: _numeroInterviewCtrl,
                            decoration: _dec(
                              "Numéro de l'interview",
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) {
                              data["Numéro de l'interview"] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                          const SizedBox(height: 12),TextFormField(
                            controller: _idEnqueteurCtrl,
                            decoration: _dec('Enquêteur (nom et prénom)'),
                            onChanged: (v) {
                              data["nom de l'enquêteur"] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
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

                      const SizedBox(height: 16),
                      _sectionCard(

                        children: [
                          _buildStringDropdown(
                            label: 'Pays',
                            options: _paysOptions,
                            value: _selectedPays,
                            onChanged: (v) {
                              setState(() {
                                _selectedPays = v;
                                // 1. Réinitialisation des états région et port
                                _selectedRegion = null;
                                _selectedPortPeche = null;
                              });

                              // 2. Nettoyage des contrôleurs de texte associés
                              _regionCtrl.clear();
                              _portPecheCtrl.clear();
                              _portPecheAutreCtrl.clear();
                              _zoneCtrl.clear();

                              // 3. Suppression des clés de la map locale "data"
                              data.remove('region');
                              data.remove('portPeche');
                              data.remove('portPecheAutre');
                              data.remove('Zone');

                              if (v != null) {
                                _paysCtrl.text = v;
                                data['pays'] = v;
                              } else {
                                _paysCtrl.clear();
                                data.remove('pays');
                              }

                              // Sauvegarde des données vidées
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          _buildStringDropdown(
                            label: 'Région',
                            options: _selectedPays == 'Tunisie' ? _regionOptionsT : _regionOptionsI,
                            value: _selectedRegion,
                            onChanged: (v) {
                              setState(() {
                                _selectedRegion = v;
                                _selectedPortPeche = null;
                              });
                              _regionCtrl.text = v ?? '';
                              _portPecheCtrl.clear();
                              _portPecheAutreCtrl.clear();
                              if (v == null) {
                                data.remove('region');
                              } else {
                                data['region'] = v;
                              }
                              data.remove('portPeche');
                              data.remove('portPecheAutre');
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),

                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(_selectedRegion), // Permet de forcer la reconstruction du dropdown Port quand la région change (ou s'annule)
                            initialValue: _selectedPortPeche,
                            isExpanded: true,
                            decoration: _dec('Port de Pêche'),
                            hint: Text(
                              _selectedRegion == null
                                  ? "Choisir d'abord la région"
                                  : 'Choisir...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            items: _portsForSelectedRegion()
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
                            onChanged: _selectedRegion == null
                                ? null
                                : (v) {
                                    setState(() => _selectedPortPeche = v);
                                    if (v == null) {
                                      data.remove('portPeche');
                                      data.remove('portPecheAutre');
                                      _portPecheCtrl.clear();
                                      _portPecheAutreCtrl.clear();
                                    } else if (v == 'Autre (préciser)') {
                                      _portPecheCtrl.text = 'Autre';
                                      data['portPeche'] = 'Autre';
                                      final autre = _portPecheAutreCtrl.text
                                          .trim();
                                      if (autre.isNotEmpty) {
                                        data['portPecheAutre'] = autre;
                                      } else {
                                        data.remove('portPecheAutre');
                                      }
                                    } else {
                                      _portPecheCtrl.text = v;
                                      data['portPeche'] = v;
                                      _portPecheAutreCtrl.clear();
                                      data.remove('portPecheAutre');
                                    }
                          
                                    _service.scheduleFullDataSave(
                                      widget.formId,
                                      data,
                                    );
                                  },
                          ),

                          if (_isAutrePortSelected) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _portPecheAutreCtrl,
                              decoration: _dec('Préciser le port'),
                              onChanged: (v) {
                                data['portPeche'] = 'Autre';
                                data['portPecheAutre'] = v;
                                _service.scheduleFullDataSave(
                                  widget.formId,
                                  data,
                                );
                              },
                            ),
                          ],

                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _zoneCtrl,
                            decoration: _dec('Zone (nom local)'),
                            onChanged: (v) {
                              data['Zone'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        children: [
                          TextFormField(
                            controller: _typePecheCtrl,
                            decoration: _dec('Type de pêche'),
                            
                            onChanged: (v) {
                              data['Type Pêche'] = v;
                              _service.scheduleFullDataSave(
                                widget.formId,
                                data,
                              );
                            },
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
                              onPressed: () async {
                                if (!_validateGeneratedObservationId()) return;
                                _service.updateFormData(
                                  widget.formId,
                                  data,
                                  stepCompleted: 1,
                                );
                                if (!context.mounted) return;
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
                    ],
                  ),
            ),
              ],
            ),
      ),
        ],),);
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