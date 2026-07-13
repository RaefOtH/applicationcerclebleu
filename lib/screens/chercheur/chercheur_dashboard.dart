import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../painters/wave_painter.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../widgets/app_feedback.dart';
import '../labo/lab_entry_choice_screen.dart';
import '../terrain/terrain_entry_choice_screen.dart';

import '../lek/lek_entry_choice_screen.dart';

class ChercheurDashboard extends StatefulWidget {
  final AppUser? user;

  const ChercheurDashboard({super.key, this.user});

  @override
  State<ChercheurDashboard> createState() => _ChercheurDashboardState();
}

class _ChercheurDashboardState extends State<ChercheurDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StatsService _statsService = StatsService();
  late AnimationController _waveController;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  StatsRange _range = StatsRange.all;
  DateTimeRange? _customRange;
  String _selectedPlace = 'Tous';
  String _selectedLab = 'Tous';
  bool _showStatsFilters = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange,
    );
    if (picked == null) return;
    setState(() {
      _range = StatsRange.custom;
      _customRange = picked;
    });
  }

  void _openAiChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AiChatSheet(),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showModernLogoutDialog(context);
    if (ok != true) return;
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  String _formattedDateTime() {
    const weekdays = <String>[
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    final day = weekdays[_now.weekday - 1];
    final dd = _now.day.toString().padLeft(2, '0');
    final mm = _now.month.toString().padLeft(2, '0');
    final yyyy = _now.year.toString();
    final hh = _now.hour.toString().padLeft(2, '0');
    final min = _now.minute.toString().padLeft(2, '0');
    return '$day $dd/$mm/$yyyy - $hh:$min';
  }

  String _rangeLabel(StatsRange value) {
    switch (value) {
      case StatsRange.today:
        return "Aujourd'hui";
      case StatsRange.days7:
        return '7 jours';
      case StatsRange.days30:
        return '30 jours';
      case StatsRange.all:
        return 'Tout';
      case StatsRange.custom:
        return 'Personnalisé';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final fullName = (widget.user?.fullName ?? '').trim().isEmpty
        ? 'Chercheur'
        : widget.user!.fullName.trim();
    final email = (widget.user?.email ?? '').trim();

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            height: 230,
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
                builder: (context, child) => CustomPaint(
                  painter: WavePainter(
                    animation: _waveController.value,
                    color: const Color(0xFF00D9D9).withValues(alpha: 0.12),
                    waveHeight: 20,
                  ),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _confirmLogout,
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            _formattedDateTime(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.profile,
                            arguments: {
                              'fullName': fullName,
                              'role': 'chercheur',
                              'email': email,
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Cercle Bleu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bonjour, $fullName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: uid == null
                        ? const Center(child: Text('Utilisateur non connecté'))
                        : FutureBuilder<DashboardStatsResult>(
                            future: _statsService.fetchDashboardStats(
                              isAdmin: false,
                              uid: uid,
                              filters: StatsFilters(
                                range: _range,
                                customRange: _customRange,
                                selectedPlace: _selectedPlace,
                                selectedLab: _selectedLab,
                              ),
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(
                                    'Erreur stats: ${snapshot.error}',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              final stats = snapshot.data;
                              final places = [
                                'Tous',
                                ...(stats?.placeOptions ?? const <String>[]),
                              ];
                              final labs = [
                                'Tous',
                                ...(stats?.labOptions ?? const <String>[]),
                              ];
                              if (!places.contains(_selectedPlace)) {
                                _selectedPlace = 'Tous';
                              }
                              if (!labs.contains(_selectedLab)) {
                                _selectedLab = 'Tous';
                              }

                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF00D9D9,
                                              ).withValues(alpha: 0.08),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/image/logo.png',
                                          height: 122,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const _CreateSection(),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () => setState(
                                            () => _showStatsFilters =
                                                !_showStatsFilters,
                                          ),
                                          icon: Icon(
                                            _showStatsFilters
                                                ? Icons.tune_rounded
                                                : Icons.filter_list_rounded,
                                          ),
                                          label: const Text('Filtres'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF1E3A8A,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton.icon(
                                          onPressed: _openAiChat,
                                          icon: const Icon(
                                            Icons.smart_toy_outlined,
                                          ),
                                          label: const Text('Ai chat'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF00A6A6,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    AnimatedSize(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: _showStatsFilters
                                          ? _FilterCard(
                                              range: _range,
                                              rangeLabel: _rangeLabel,
                                              onRangeChanged: (r) =>
                                                  setState(() => _range = r),
                                              onPickCustomRange:
                                                  _pickCustomRange,
                                              selectedPlace: _selectedPlace,
                                              placeOptions: places,
                                              onPlaceChanged: (v) => setState(
                                                () => _selectedPlace =
                                                    v ?? 'Tous',
                                              ),
                                              selectedLab: _selectedLab,
                                              labOptions: labs,
                                              onLabChanged: (v) => setState(
                                                () =>
                                                    _selectedLab = v ?? 'Tous',
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(height: 14),
                                    if (stats == null ||
                                        (stats.totalTerrain == 0 &&
                                            stats.totalLabo == 0 &&
                                        stats.totalLek == 0))
                                      _EmptyCard(
                                        text:
                                            'Aucune donnée trouvée pour les filtres sélectionnés.',
                                      )
                                    else ...[
                                      _SummaryCard(
                                        totalTerrain: stats.totalTerrain,
                                        totalLabo: stats.totalLabo,
                                        totalLek: stats.totalLek,
                                      ),
                                      const SizedBox(height: 10),
                                      _StatsCard(
                                        title: 'Ports uniques',
                                        value: stats.totalPortsUniques
                                            .toString(),
                                        subtitle: 'Ports de pêche uniques',
                                      ),
                                      const SizedBox(height: 10),
                                      _StatsCard(
                                        title: 'Crabes capturés',
                                        value: stats.totalCrabes.toString(),
                                        subtitle:
                                            'Total cap_abondance (terrain)',
                                      ),
                                      const SizedBox(height: 10),
                                      if (stats.topPorts.isNotEmpty)
                                        _TopListCard(
                                          title: 'Top 5 Ports',
                                          entries: stats.topPorts,
                                        ),
                                      if (stats.topPorts.isNotEmpty)
                                        const SizedBox(height: 10),
                                      if (stats.topEspeces.isNotEmpty)
                                        _TopListCard(
                                          title: 'Top 5 Espèces',
                                          entries: stats.topEspeces,
                                        ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
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

class _FilterCard extends StatelessWidget {
  final StatsRange range;
  final String Function(StatsRange) rangeLabel;
  final ValueChanged<StatsRange> onRangeChanged;
  final VoidCallback onPickCustomRange;
  final String selectedPlace;
  final List<String> placeOptions;
  final ValueChanged<String?> onPlaceChanged;
  final String selectedLab;
  final List<String> labOptions;
  final ValueChanged<String?> onLabChanged;

  const _FilterCard({
    required this.range,
    required this.rangeLabel,
    required this.onRangeChanged,
    required this.onPickCustomRange,
    required this.selectedPlace,
    required this.placeOptions,
    required this.onPlaceChanged,
    required this.selectedLab,
    required this.labOptions,
    required this.onLabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtres',
            style: TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StatsRange.values
                .map((r) {
                  return ChoiceChip(
                    label: Text(rangeLabel(r)),
                    selected: r == range,
                    onSelected: (_) => onRangeChanged(r),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPickCustomRange,
            icon: const Icon(Icons.date_range),
            label: const Text('Choisir période personnalisée'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedPlace,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Port / Zone',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: placeOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(growable: false),
            onChanged: onPlaceChanged,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedLab,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Laboratoire',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: labOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(growable: false),
            onChanged: onLabChanged,
          ),
        ],
      ),
    );
  }
}

//CreationSection*
class _CreateSection extends StatelessWidget {
  const _CreateSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Créer',
          style: TextStyle(
            color: Color(0xFF1E3A8A),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _CreateButton(
          label: 'Enquête : Données Terrain',
          icon: Icons.assignment_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TerrainEntryChoiceScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _CreateButton(
          label: 'Données Laboratoire',
          icon: Icons.science_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LabEntryChoiceScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _CreateButton(
          label: 'Questionnaire LEK',
          icon: Icons.assignment_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LekEntryChoiceScreen()),
          ),
        ),
      ],
    );
  }
}

class _CreateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CreateButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9D9), Color(0xFF1E3A8A)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
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

class _SummaryCard extends StatelessWidget {
  final int totalTerrain;
  final int totalLabo;
  final int totalLek;


  const _SummaryCard({required this.totalTerrain, required this.totalLabo, required this.totalLek});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résumé global',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallMetric(
                  label: 'Terrain',
                  value: totalTerrain.toString(),
                  icon: Icons.map_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallMetric(
                  label: 'Lab',
                  value: totalLabo.toString(),
                  icon: Icons.science_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallMetric(
                  label: 'LEK',
                  value: totalLek.toString(),
                  icon: Icons.bar_chart,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SmallMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
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

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3A8A),
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopListCard extends StatelessWidget {
  final String title;
  final List<StatsEntry> entries;

  const _TopListCard({required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3A8A),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.value.toString(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }
}

// ============================================================
// Assistant "Ai chat" — chatbot local, entièrement embarqué dans
// l'application : aucun appel réseau, aucune clé API, aucun
// service payant ni abonnement. Les réponses sont générées par
// un moteur de règles/mots-clés limité aux données Terrain,
// Laboratoire et au questionnaire LEK.
// ============================================================

enum _ChatSender { user, bot }

class _ChatMessage {
  final String text;
  final _ChatSender sender;

  const _ChatMessage(this.text, this.sender);
}

/// Génère une réponse locale (sans frais, sans abonnement, sans appel
/// réseau) en se basant sur des mots-clés liés aux données Terrain,
/// Laboratoire et au questionnaire LEK. Toute question hors de ce
/// périmètre reçoit une réponse de recadrage.
String _generateAiChatReply(String question) {
  final q = question.toLowerCase().trim();

  bool has(List<String> words) => words.any((w) => q.contains(w));

  if (q.isEmpty) {
    return "Posez-moi une question sur les données terrain, les données laboratoire ou le questionnaire LEK.";
  }

  if (has(['bonjour', 'salut', 'bonsoir', 'hello', 'coucou'])) {
    return "Bonjour ! Je suis l'assistant Cercle Bleu. Je peux vous renseigner sur les données terrain, les données laboratoire et le questionnaire LEK. Que souhaitez-vous savoir ?";
  }

  if (has(['merci'])) {
    return "Avec plaisir ! N'hésitez pas si vous avez d'autres questions sur les données terrain, laboratoire ou le questionnaire LEK.";
  }

  if (has(['terrain'])) {
    return "Les données Terrain regroupent les enquêtes de capture réalisées sur le terrain : port de pêche, zone, espèce observée et abondance des crabes capturés (champ cap_abondance). Vous pouvez les filtrer par période et par port/zone via le bouton 'Filtres', et les saisir via le bouton 'Enquête : Données Terrain'.";
  }

  if (has(['labo', 'laboratoire'])) {
    return "Les données Laboratoire correspondent aux analyses réalisées en laboratoire sur les échantillons collectés sur le terrain. Vous pouvez filtrer les statistiques par laboratoire, et saisir de nouvelles données via le bouton 'Données Laboratoire'.";
  }

  if (has(['lek', 'questionnaire'])) {
    return "Le questionnaire LEK (Local Ecological Knowledge, connaissance écologique locale) recueille le savoir et les observations des pêcheurs et acteurs locaux sur l'espèce étudiée. Ces réponses complètent les données terrain et laboratoire. Vous pouvez en créer un via le bouton 'Questionnaire LEK'.";
  }

  if (has(['crabe', 'crabes', 'espèce', 'especes', 'espece'])) {
    return "Le total de crabes capturés correspond à la somme du champ cap_abondance des enquêtes terrain. Le 'Top 5 Espèces' indique les espèces les plus fréquemment recensées, selon les filtres actifs.";
  }

  if (has(['port', 'ports', 'zone'])) {
    return "Les 'ports uniques' correspondent aux ports de pêche distincts enregistrés dans les enquêtes terrain. Le 'Top 5 Ports' montre les ports les plus actifs selon les filtres sélectionnés.";
  }

  if (has(['filtre', 'filtres', 'période', 'periode', 'date'])) {
    return "Le bouton 'Filtres' permet d'affiner les statistiques affichées par période (aujourd'hui, 7 jours, 30 jours, tout, ou une période personnalisée), par port/zone et par laboratoire.";
  }

  if (has(['résumé', 'resume', 'total', 'statistique', 'statistiques'])) {
    return "Le 'Résumé global' affiche le nombre total d'enquêtes terrain, de données laboratoire et de réponses au questionnaire LEK, en fonction des filtres actifs.";
  }

  return "Je peux uniquement répondre aux questions concernant les données terrain, les données laboratoire et le questionnaire LEK de Cercle Bleu. Pouvez-vous reformuler votre question à ce sujet ?";
}

class _AiChatSheet extends StatefulWidget {
  const _AiChatSheet();

  @override
  State<_AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<_AiChatSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      "Bonjour, je suis l'assistant Cercle Bleu 🦀\n"
      "Je réponds uniquement aux questions sur les données terrain, "
      "les données laboratoire et le questionnaire LEK.",
      _ChatSender.bot,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text, _ChatSender.user));
      _messages.add(_ChatMessage(_generateAiChatReply(text), _ChatSender.bot));
    });
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollSheetController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assistant Cercle Bleu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Terrain · Laboratoire · Questionnaire LEK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollSheetController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final m = _messages[index];
                    final isUser = m.sender == _ChatSender.user;
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFF1E3A8A)
                              : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isUser ? 16 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 16),
                          ),
                          border: isUser
                              ? null
                              : Border.all(
                                  color: const Color(
                                    0xFF1E3A8A,
                                  ).withValues(alpha: 0.08),
                                ),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: isUser ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              hintText:
                                  'Question sur le terrain, le labo, le LEK…',
                              hintStyle: TextStyle(fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF00A6A6),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _send,
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
/*
Données Terrain

« C'est quoi les données terrain ? »
« Comment ajouter une enquête terrain ? »

Données Laboratoire

« Que contiennent les données laboratoire ? »
« Comment saisir des données labo ? »

Questionnaire LEK

« C'est quoi le questionnaire LEK ? »
« À quoi sert le LEK ? »

Crabes / espèces

« Comment est calculé le total de crabes capturés ? »
« Que montre le Top 5 Espèces ? »

Ports / zones

« Qu'est-ce que "ports uniques" ? »
« Comment est calculé le Top 5 Ports ? »

Filtres

« Comment filtrer par période ? »
« À quoi sert le bouton Filtres ? »

Résumé global

« Que montre le résumé global ? »

Salutations / remerciements

« Bonjour », « Merci »*/