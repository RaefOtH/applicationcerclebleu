import 'package:applicationstagepfe/screens/lek/info_page.dart';
import 'package:flutter/material.dart';
import '../../painters/wave_painter.dart';
import '../../services/lek_form_service.dart';
import 'dynamique_du_crabe_page.dart';


// 1. DÉCLARATION DE LA CLASSE D'OBJET EN DEHORS DE LA CLASSE DE PAGE POUR ÉVITER LES ERREURS DE TYPE
class EnginDePeche {
  final String codeEngin;
  String nomLocal;
  double? partEnPourcent;
  String especeCibles;
  String especeAccessoires;
  List<bool> saisonUtilisation;
  int? nbHeurePecheEffective;

  EnginDePeche({
    required this.codeEngin,
    this.nomLocal = '',
    this.partEnPourcent,
    this.especeCibles = '',
    this.especeAccessoires = '',
    List<bool>? saisonUtilisation,
    this.nbHeurePecheEffective,
  }) : saisonUtilisation = saisonUtilisation ?? List.generate(12, (_) => false);

  Map<String, dynamic> toMap() {
    return {
      'codeEngin': codeEngin,
      'nomLocal': nomLocal,
      'partEnPourcent': partEnPourcent,
      'especeCibles': especeCibles,
      'especeAccessoires': especeAccessoires,
      'saisonUtilisation': saisonUtilisation,
      'nbHeurePecheEffective': nbHeurePecheEffective,
    };
  }
}

class UniteDePechePage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String formId;
  const UniteDePechePage({super.key, required this.data, required this.formId});

  @override
  State<UniteDePechePage> createState() => _UniteDePechePageState();
}

class _UniteDePechePageState extends State<UniteDePechePage>
    with SingleTickerProviderStateMixin {
  late final Map<String, dynamic> data;
  final LekFormService _service = LekFormService();
  final _formKey = GlobalKey<FormState>();

  // Controllers: a) Barque
  final _matriculeCtrl = TextEditingController();
  final _longueurBarqueCtrl = TextEditingController();
  final _puissanceCtrl = TextEditingController();
  final _typeCoqueCtrl = TextEditingController();
  final _anneeAchatCtrl = TextEditingController();

  // Controllers: b) Activité
  final _dureeMareeCtrl = TextEditingController();
  final Map<String, TextEditingController> _sortiesControllers = {
    'Janvier': TextEditingController(),
    'Février': TextEditingController(),
    'Mars': TextEditingController(),
    'Avril': TextEditingController(),
    'Mai': TextEditingController(),
    'Juin': TextEditingController(),
    'Juillet': TextEditingController(),
    'Août': TextEditingController(),
    'Septembre': TextEditingController(),
    'Octobre': TextEditingController(),
    'Novembre': TextEditingController(),
    'Décembre': TextEditingController(),
  };
  double _moyenneSorties = 0.0;

  // Controllers: c) Caractéristiques de l'engin
  final _filetsDroitsLongCtrl = TextEditingController();
  final _filetsDroitsHautCtrl = TextEditingController();
  final _filetsDroitsMailleCentCtrl = TextEditingController();
  final _filetsDroitsMailleExtCtrl = TextEditingController();
  final _filetsDroitsNbPiecesCtrl = TextEditingController();
  final _filetsDroitsNbArmementsCtrl = TextEditingController();

  final _filetsTournantsLongCtrl = TextEditingController();
  final _filetsTournantsHautCtrl = TextEditingController();
  final _filetsTournantsMailleAileCtrl = TextEditingController();
  final _filetsTournantsMaillePocheCtrl = TextEditingController();

  final _piegesDiametreCtrl = TextEditingController();
  final _piegesNbreCtrl = TextEditingController();

  final _nassesDiametreCtrl = TextEditingController();
  final _nassesHauteurCtrl = TextEditingController();
  final _nassesOuvertureCtrl = TextEditingController();
  final _nassesMailleCtrl = TextEditingController();
  final _nassesNbreCtrl = TextEditingController();

  final _chalutLongRalingueCtrl = TextEditingController();
  final _chalutOuvVertCtrl = TextEditingController();
  final _chalutOuvHorizCtrl = TextEditingController();
  final _chalutMailleCulCtrl = TextEditingController();
  final _chalutTypeCtrl = TextEditingController();

  final List<String> _moisLettres = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  late final List<EnginDePeche> _listeEngins;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    data = widget.data;
 
    // Chargement Barque
    _matriculeCtrl.text = (data['unité_barque_matricule'] ?? '').toString();
    _longueurBarqueCtrl.text = (data['unité_barque_longueur'] ?? '').toString();
    _puissanceCtrl.text = (data['unité_barque_puissance'] ?? '').toString();
    _typeCoqueCtrl.text = (data['unité_barque_type_coque'] ?? '').toString();
    _anneeAchatCtrl.text = (data['unité_barque_annee_achat'] ?? '').toString();

    // Chargement Activité
    _dureeMareeCtrl.text = (data['unité_activite_duree_maree'] ?? '').toString();

    if (data['unité_sorties_2025'] != null) {
      final Map<dynamic, dynamic> savedSorties = data['unité_sorties_2025'];
      savedSorties.forEach((mois, valeur) {
        if (_sortiesControllers.containsKey(mois)) {
          _sortiesControllers[mois]!.text = valeur.toString();
        }
      });
    }
    _calculerMoyenneSorties();

    // Initialisation Liste Engins
    _listeEngins = [
      EnginDePeche(codeEngin: 'Senne tournante coulissante: PS'),
      EnginDePeche(codeEngin: 'Chaluts : CH (Crevettier, Mediterranien, GOV, pélagique)'),
      EnginDePeche(codeEngin: 'Filets tournants : FT'),
      EnginDePeche(codeEngin: 'Trémails et maillants combinés: TMC'),
      EnginDePeche(codeEngin: 'Filets maillants dérivants: MD'),
      EnginDePeche(codeEngin: 'Filets maillants encerclants: MEC'),
      EnginDePeche(codeEngin: 'Trémails: TR (poisson, Crevettes, Seiche)'),
      EnginDePeche(codeEngin: 'Filets monofilament: MoFi'),
      EnginDePeche(codeEngin: 'Nasses (casiers): NC'),
      EnginDePeche(codeEngin: 'Pièges (gargoulettes, Verveux...): P'),
      EnginDePeche(codeEngin: 'autre'),
    ];

    if (data['engins_peche'] != null) {
      final List<dynamic> savedEngins = data['engins_peche'];
      for (int i = 0; i < _listeEngins.length && i < savedEngins.length; i++) {
        final saved = savedEngins[i] as Map<String, dynamic>;
        _listeEngins[i].nomLocal = saved['unité_nom_Local'] ?? '';
        _listeEngins[i].partEnPourcent = (saved['unité_part_En_Pourcent'] as num?)?.toDouble();
        _listeEngins[i].especeCibles = saved['unité_espece_Cibles'] ?? '';
        _listeEngins[i].especeAccessoires = saved['unité_espece_Accessoires'] ?? '';
        if (saved['unité_saison_Utilisation'] != null) {
          _listeEngins[i].saisonUtilisation = List<bool>.from(saved['unité_saison_Utilisation']);
        }
        _listeEngins[i].nbHeurePecheEffective = saved['unité_nbHeure_Peche_Effective'] as int?;
      }
    }

    // Chargement Caractéristiques Engins
    _filetsDroitsLongCtrl.text = (data['unité_fd_longueur'] ?? '').toString();
    _filetsDroitsHautCtrl.text = (data['unité_fd_hauteur'] ?? '').toString();
    _filetsDroitsMailleCentCtrl.text = (data['unité_fd_maille_centrale'] ?? '').toString();
    _filetsDroitsMailleExtCtrl.text = (data['unité_fd_maille_exterieure'] ?? '').toString();
    _filetsDroitsNbPiecesCtrl.text = (data['unité_fd_nb_pieces'] ?? '').toString();
    _filetsDroitsNbArmementsCtrl.text = (data['unité_fd_nb_armements'] ?? '').toString();

    _filetsTournantsLongCtrl.text = (data['unité_ft_longueur'] ?? '').toString();
    _filetsTournantsHautCtrl.text = (data['unité_ft_hauteur'] ?? '').toString();
    _filetsTournantsMailleAileCtrl.text = (data['unité_ft_maille_aile'] ?? '').toString();
    _filetsTournantsMaillePocheCtrl.text = (data['unité_ft_maille_poche'] ?? '').toString();

    _piegesDiametreCtrl.text = (data['unité_pieges_diametre'] ?? '').toString();
    _piegesNbreCtrl.text = (data['unité_pieges_nbre'] ?? '').toString();

    _nassesDiametreCtrl.text = (data['unité_nasses_diametre'] ?? '').toString();
    _nassesHauteurCtrl.text = (data['unité_nasses_hauteur'] ?? '').toString();
    _nassesOuvertureCtrl.text = (data['unité_nasses_ouverture'] ?? '').toString();
    _nassesMailleCtrl.text = (data['unité_nasses_maille'] ?? '').toString();
    _nassesNbreCtrl.text = (data['unité_nasses_nbre'] ?? '').toString();

    _chalutLongRalingueCtrl.text = (data['unité_chalut_longueur_ralingue'] ?? '').toString();
    _chalutOuvVertCtrl.text = (data['unité_chalut_ouverture_verticale'] ?? '').toString();
    _chalutOuvHorizCtrl.text = (data['unité_chalut_ouverture_horizontale'] ?? '').toString();
    _chalutMailleCulCtrl.text = (data['unité_chalut_maille_cul'] ?? '').toString();
    _chalutTypeCtrl.text = (data['unité_chalut_type'] ?? '').toString();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _matriculeCtrl.dispose();
    _longueurBarqueCtrl.dispose();
    _puissanceCtrl.dispose();
    _typeCoqueCtrl.dispose();
    _anneeAchatCtrl.dispose();
    _dureeMareeCtrl.dispose();
    for (var ctrl in _sortiesControllers.values) {
      ctrl.dispose();
    }
    _filetsDroitsLongCtrl.dispose();
    _filetsDroitsHautCtrl.dispose();
    _filetsDroitsMailleCentCtrl.dispose();
    _filetsDroitsMailleExtCtrl.dispose();
    _filetsDroitsNbPiecesCtrl.dispose();
    _filetsDroitsNbArmementsCtrl.dispose();
    _filetsTournantsLongCtrl.dispose();
    _filetsTournantsHautCtrl.dispose();
    _filetsTournantsMailleAileCtrl.dispose();
    _filetsTournantsMaillePocheCtrl.dispose();
    _piegesDiametreCtrl.dispose();
    _piegesNbreCtrl.dispose();
    _nassesDiametreCtrl.dispose();
    _nassesHauteurCtrl.dispose();
    _nassesOuvertureCtrl.dispose();
    _nassesMailleCtrl.dispose();
    _nassesNbreCtrl.dispose();
    _chalutLongRalingueCtrl.dispose();
    _chalutOuvVertCtrl.dispose();
    _chalutOuvHorizCtrl.dispose();
    _chalutMailleCulCtrl.dispose();
    _chalutTypeCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _calculerMoyenneSorties() {
    int totalJours = 0;
    int moisRenseignes = 0;

    _sortiesControllers.forEach((mois, ctrl) {
      final valeur = int.tryParse(ctrl.text);
      if (valeur != null) {
        totalJours += valeur;
        moisRenseignes++;
      }
    });

    setState(() {
      _moyenneSorties = moisRenseignes > 0 ? totalJours / moisRenseignes : 0.0;
      data['moyenne_sorties_2025'] = _moyenneSorties;
    });
  }

  void _sauvegarderSorties() {
    final Map<String, int> sortiesMap = {};
    _sortiesControllers.forEach((mois, ctrl) {
      sortiesMap[mois] = int.tryParse(ctrl.text) ?? 0;
    });
    data['sorties_2025'] = sortiesMap;
    _service.scheduleFullDataSave(widget.formId, data);
  }

  void _sauvegarderTableau() {
    data['engins_peche'] = _listeEngins.map((engin) => engin.toMap()).toList();
    _service.scheduleFullDataSave(widget.formId, data);
  }

  Future<void> _pickAnneeAchat() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _anneeAchatCtrl.text = picked.year.toString());
      data['barque_annee_achat'] = picked.year.toString();
      _service.scheduleFullDataSave(widget.formId, data);
    }
  }

  InputDecoration _dec(String label, {String? suffix}) => InputDecoration(
    labelText: label,
    suffixText: suffix,
    hintText: 'Saisir...',
    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF8FBFF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00D9D9), width: 2)),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String key,
    bool numeric = false,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      decoration: _dec(label, suffix: suffix),
      onChanged: (v) {
        data[key] = v;
        _service.scheduleFullDataSave(widget.formId, data);
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(color: Color(0xFF00D9D9), thickness: 1.5, endIndent: 200),
        ],
      ),
    );
  }

  Widget _subSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF2D4BA8), fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }

  void _goNext() {
    _sauvegarderTableau();
    _sauvegarderSorties();
    _service.updateFormData(widget.formId, data, stepCompleted: 2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données enregistrées avec succès !')),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamiqueDuCrabePage(formId: widget.formId, data: data),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 200,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8)]),
              ),
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withValues(alpha: 0.12),
                      waveHeight: 15,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Text(
                        "Unité de Pêche",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const Text('Étape 3/9', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08), width: 1.5),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              
                              // ================= a) BARQUE =================
                              _sectionTitle("a) Barque"),
                              _field(controller: _matriculeCtrl, label: 'Matricule', key: 'barque_matricule'),
                              const SizedBox(height: 10),
                              _field(controller: _longueurBarqueCtrl, label: 'Longueur', key: 'barque_longueur', numeric: true, suffix: 'm'),
                              const SizedBox(height: 10),
                              _field(controller: _puissanceCtrl, label: 'Puissance', key: 'barque_puissance', numeric: true, suffix: 'chx'),
                              const SizedBox(height: 10),
                              _field(controller: _typeCoqueCtrl, label: 'Type de coque barque', key: 'barque_type_coque'),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _anneeAchatCtrl,
                                readOnly: true,
                                onTap: _pickAnneeAchat,
                                decoration: _dec("Année d'achat (coque)").copyWith(
                                  suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF1E3A8A)),
                                ),
                              ),

                              // ================= b) ACTIVITÉ =================
                              _sectionTitle("b) Activité"),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 380,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      border: TableBorder.all(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                                      headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                                      columns: const [
                                        DataColumn(label: Text('Code engin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Nom local', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Part %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Espèce cibles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Espèce access.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text("Saison d'utilisation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                        DataColumn(label: Text('Nb h pêche eff.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                      ],
                                      rows: _listeEngins.map((engin) {
                                        return DataRow(cells: [
                                          DataCell(SizedBox(width: 150, child: Text(engin.codeEngin, style: const TextStyle(fontSize: 11)))),
                                          DataCell(SizedBox(
                                            width: 90,
                                            child: TextFormField(
                                              initialValue: engin.nomLocal,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
                                              onChanged: (val) { engin.nomLocal = val; _sauvegarderTableau(); },
                                            ),
                                          )),
                                          DataCell(SizedBox(
                                            width: 50,
                                            child: TextFormField(
                                              initialValue: engin.partEnPourcent?.toString() ?? '',
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
                                              onChanged: (val) { engin.partEnPourcent = double.tryParse(val); _sauvegarderTableau(); },
                                            ),
                                          )),
                                          DataCell(SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: engin.especeCibles,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
                                              onChanged: (val) { engin.especeCibles = val; _sauvegarderTableau(); },
                                            ),
                                          )),
                                          DataCell(SizedBox(
                                            width: 100,
                                            child: TextFormField(
                                              initialValue: engin.especeAccessoires,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
                                              onChanged: (val) { engin.especeAccessoires = val; _sauvegarderTableau(); },
                                            ),
                                          )),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: List.generate(12, (index) {
                                                bool isSelected = engin.saisonUtilisation[index];
                                                return GestureDetector(
                                                  onTap: () {
                                                    setState(() { engin.saisonUtilisation[index] = !isSelected; });
                                                    _sauvegarderTableau();
                                                  },
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                                    padding: const EdgeInsets.all(3),
                                                    decoration: BoxDecoration(
                                                      color: isSelected ? const Color(0xFF00D9D9) : Colors.transparent,
                                                      borderRadius: BorderRadius.circular(3),
                                                      border: Border.all(color: isSelected ? const Color(0xFF00D9D9) : Colors.grey.shade400),
                                                    ),
                                                    child: Text(
                                                      _moisLettres[index],
                                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                          DataCell(SizedBox(
                                            width: 65,
                                            child: TextFormField(
                                              initialValue: engin.nbHeurePecheEffective?.toString() ?? '',
                                              keyboardType: TextInputType.number,
                                              style: const TextStyle(fontSize: 12),
                                              decoration: const InputDecoration(border: InputBorder.none, hintText: '-'),
                                              onChanged: (val) { engin.nbHeurePecheEffective = int.tryParse(val); _sauvegarderTableau(); },
                                            ),
                                          )),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              _field(controller: _dureeMareeCtrl, label: "Durée moyenne d'une Marée", key: 'activite_duree_maree', numeric: true, suffix: "en nbre d'heures"),
                              
                              // ================= SORTIES EN MER EN 2025 =================
                              const SizedBox(height: 15),
                              _subSectionTitle("Nombre de sorties en mer en 2025"),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                ),
                                child: Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 2.2,
                                      ),
                                      itemCount: _sortiesControllers.length,
                                      itemBuilder: (context, index) {
                                        String mois = _sortiesControllers.keys.elementAt(index);
                                        return TextFormField(
                                          controller: _sortiesControllers[mois],
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(fontSize: 13),
                                          decoration: _dec(mois),
                                          onChanged: (v) {
                                            _calculerMoyenneSorties();
                                            _sauvegarderSorties();
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.shade300),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Moy nb jours (Moyenne):",
                                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                          ),
                                          Text(
                                            "${_moyenneSorties.toStringAsFixed(2)} jours",
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.deepOrange),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ================= c) CARACTÉRISTIQUES DES ENGINS =================
                              _sectionTitle("c) Caractéristique de l'engin"),
                              
                              _subSectionTitle("c-1) Filets"),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("c-1.1 Filets droits (maillant, trémails, ...)", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black12)),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsLongCtrl, label: 'Longueur', key: 'fd_longueur', numeric: true, suffix: 'm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsHautCtrl, label: 'Hauteur', key: 'fd_hauteur', numeric: true, suffix: 'm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsMailleCentCtrl, label: 'Maille/Maille centrale', key: 'fd_maille_centrale', numeric: true, suffix: 'mm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsMailleExtCtrl, label: 'Maille extérieure', key: 'fd_maille_exterieure', numeric: true, suffix: 'mm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsNbPiecesCtrl, label: 'Nbre de pièces par armement', key: 'fd_nb_pieces', numeric: true),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsDroitsNbArmementsCtrl, label: 'Nbre armements', key: 'fd_nb_armements', numeric: true),
                                    
                                    const SizedBox(height: 14),
                                    const Text("c-1.2 Filets Tournants", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black12)),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsTournantsLongCtrl, label: 'Longueur', key: 'ft_longueur', numeric: true, suffix: 'm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsTournantsHautCtrl, label: 'Hauteur (chute)', key: 'ft_hauteur', numeric: true, suffix: 'm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsTournantsMailleAileCtrl, label: 'Maille aile', key: 'ft_maille_aile', numeric: true, suffix: 'mm'),
                                    const SizedBox(height: 6),
                                    _field(controller: _filetsTournantsMaillePocheCtrl, label: 'Maille poche', key: 'ft_maille_poche', numeric: true, suffix: 'mm'),
                                  ],
                                ),
                              ),

                              _subSectionTitle("c-2) Pièges (gargoulette, pierre...)"),
                              _field(controller: _piegesDiametreCtrl, label: 'Diamètre', key: 'pieges_diametre', numeric: true, suffix: 'cm'),
                              const SizedBox(height: 6),
                              _field(controller: _piegesNbreCtrl, label: 'Nbre', key: 'pieges_nbre', numeric: true),

                              _subSectionTitle("c-3) Nasses"),
                              _field(controller: _nassesDiametreCtrl, label: 'Diamètre', key: 'nasses_diametre', numeric: true, suffix: 'cm'),
                              const SizedBox(height: 6),
                              _field(controller: _nassesHauteurCtrl, label: 'Hauteur', key: 'nasses_hauteur', numeric: true, suffix: 'cm'),
                              const SizedBox(height: 6),
                              _field(controller: _nassesOuvertureCtrl, label: 'Ouverture', key: 'nasses_ouverture', numeric: true, suffix: 'cm'),
                              const SizedBox(height: 6),
                              _field(controller: _nassesMailleCtrl, label: 'Maille', key: 'nasses_maille', numeric: true, suffix: 'mm'),
                              const SizedBox(height: 6),
                              _field(controller: _nassesNbreCtrl, label: 'Nbre', key: 'nasses_nbre', numeric: true),

                              _subSectionTitle("c-4) Chalut"),
                              _field(controller: _chalutLongRalingueCtrl, label: 'Longueur ralingue inférieure', key: 'chalut_longueur_ralingue', numeric: true, suffix: 'm'),
                              const SizedBox(height: 6),
                              _field(controller: _chalutOuvVertCtrl, label: 'Ouverture Verticale', key: 'chalut_ouverture_verticale', numeric: true, suffix: 'm'),
                              const SizedBox(height: 6),
                              _field(controller: _chalutOuvHorizCtrl, label: 'Ouverture horizontale', key: 'chalut_ouverture_horizontale', numeric: true, suffix: 'm'),
                              const SizedBox(height: 6),
                              _field(controller: _chalutMailleCulCtrl, label: 'Maille de cul de chalut', key: 'chalut_maille_cul', numeric: true, suffix: 'mm'),
                              const SizedBox(height: 6),
                              _field(controller: _chalutTypeCtrl, label: 'Type de chalut', key: 'chalut_type'),

                              const SizedBox(height: 30),

                              // Boutons
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
                                        builder: (_) => InfoPage(formId: widget.formId, data:data),
                                      ),
                                   );}
                                   ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)]),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: _PrimaryGradientButton(
                              text: 'Suivant',
                              icon: Icons.arrow_forward,
                              onPressed: _goNext)))
                                    
                                  
                                ],
                              ),
                            ],
                          ),
                        ),
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