import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../painters/wave_painter.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../widgets/app_feedback.dart';
import '../labo/lab_entry_choice_screen.dart';
import '../terrain/terrain_entry_choice_screen.dart';
import 'admin_attachments_screen.dart';
import 'admin_pdf_template_screen.dart';
import 'admin_researchers_screen.dart';
import 'admin_surveys_screen.dart';
import 'widgets/admin_role_guard.dart';

import '../lek/lek_entry_choice_screen.dart';

class AdminDashboard extends StatefulWidget {
  final AppUser? user;

  const AdminDashboard({super.key, this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final StatsService _statsService = StatsService();
  late AnimationController _waveController;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  StatsRange _range = StatsRange.all;
  DateTimeRange? _customRange;
  String _selectedOwnerId = 'Tous';
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

  Future<void> _confirmLogout() async {
    final ok = await showModernLogoutDialog(context);
    if (ok != true) return;
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
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

  void _openSmartReportChat(BuildContext context, DashboardStatsResult? stats) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SmartReportChatBot(stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = (widget.user?.fullName ?? '').trim();
    final email = (widget.user?.email ?? '').trim();

    return AdminRoleGuard(
      child: Scaffold(
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
                                'role': 'admin',
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
                    'Dashboard Admin',
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
                      child: FutureBuilder<DashboardStatsResult>(
                        future: _statsService.fetchDashboardStats(
                          isAdmin: true,
                          uid: null,
                          filters: StatsFilters(
                            range: _range,
                            customRange: _customRange,
                            selectedOwnerId: _selectedOwnerId == 'Tous'
                                ? null
                                : _selectedOwnerId,
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
                          final owners = <OwnerEntry>[
                            const OwnerEntry(
                              id: 'Tous',
                              name: 'Tous les chercheurs',
                            ),
                            ...(stats?.ownerOptions ?? const <OwnerEntry>[]),
                          ];
                          final places = [
                            'Tous',
                            ...(stats?.placeOptions ?? const <String>[]),
                          ];
                          final labs = [
                            'Tous',
                            ...(stats?.labOptions ?? const <String>[]),
                          ];
                          if (!owners.any((e) => e.id == _selectedOwnerId)) {
                            _selectedOwnerId = 'Tous';
                          }
                          if (!places.contains(_selectedPlace)) {
                            _selectedPlace = 'Tous';
                          }
                          if (!labs.contains(_selectedLab)) {
                            _selectedLab = 'Tous';
                          }

                          return SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                                      borderRadius: BorderRadius.circular(20),
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
                                _ActionCard(
                                  icon: Icons.inventory_2_rounded,
                                  title: 'Gestion des enquêtes',
                                  subtitle:
                                      'Voir et filtrer toutes les saisies Terrain, Labo et LEK',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminSurveysScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ActionCard(
                                  icon: Icons.groups_rounded,
                                  title: 'Gestion des chercheurs',
                                  subtitle:
                                      'Consulter profils, activités et détails chercheurs',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminResearchersScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ActionCard(
                                  icon: Icons.picture_as_pdf_rounded,
                                  title: 'Template PDF',
                                  subtitle:
                                      'Voir le template PDF de l application et le modifier',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminPdfTemplateScreen(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ActionCard(
                                  icon: Icons.folder_shared_rounded,
                                  title: 'Dossier Photos et Audio',
                                  subtitle:
                                      'Filtrer et telecharger les pieces jointes',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const AdminAttachmentsScreen(),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton.icon(
                                      onPressed: () => _openSmartReportChat(
                                        context,
                                        stats,
                                      ),
                                      icon: const Icon(
                                        Icons.auto_awesome_rounded,
                                      ),
                                      label: const Text('Smart report'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF00D9D9,
                                        ),
                                        foregroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        textStyle: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 180),
                                  child: _showStatsFilters
                                      ? _AdminFilterCard(
                                          range: _range,
                                          rangeLabel: _rangeLabel,
                                          onRangeChanged: (r) =>
                                              setState(() => _range = r),
                                          onPickCustomRange: _pickCustomRange,
                                          owners: owners,
                                          selectedOwnerId: _selectedOwnerId,
                                          onOwnerChanged: (v) => setState(
                                            () =>
                                                _selectedOwnerId = v ?? 'Tous',
                                          ),
                                          selectedPlace: _selectedPlace,
                                          placeOptions: places,
                                          onPlaceChanged: (v) => setState(
                                            () => _selectedPlace = v ?? 'Tous',
                                          ),
                                          selectedLab: _selectedLab,
                                          labOptions: labs,
                                          onLabChanged: (v) => setState(
                                            () => _selectedLab = v ?? 'Tous',
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
                                    value: stats.totalPortsUniques.toString(),
                                    subtitle: 'Ports de pêche uniques',
                                  ),
                                  const SizedBox(height: 10),
                                  _StatsCard(
                                    title: 'Crabes capturés',
                                    value: stats.totalCrabes.toString(),
                                    subtitle: 'Total cap_abondance (terrain)',
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
      ),
    );
  }
}

class _AdminFilterCard extends StatelessWidget {
  final StatsRange range;
  final String Function(StatsRange) rangeLabel;
  final ValueChanged<StatsRange> onRangeChanged;
  final VoidCallback onPickCustomRange;
  final List<OwnerEntry> owners;
  final String selectedOwnerId;
  final ValueChanged<String?> onOwnerChanged;
  final String selectedPlace;
  final List<String> placeOptions;
  final ValueChanged<String?> onPlaceChanged;
  final String selectedLab;
  final List<String> labOptions;
  final ValueChanged<String?> onLabChanged;

  const _AdminFilterCard({
    required this.range,
    required this.rangeLabel,
    required this.onRangeChanged,
    required this.onPickCustomRange,
    required this.owners,
    required this.selectedOwnerId,
    required this.onOwnerChanged,
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
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        ),
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
            initialValue: selectedOwnerId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Chercheur',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            items: owners
                .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                .toList(growable: false),
            onChanged: onOwnerChanged,
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D9D9).withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: const Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF1E3A8A)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalTerrain;
  final int totalLabo;
  final int totalLek;

  const _SummaryCard({
    required this.totalTerrain,
    required this.totalLabo,
    required this.totalLek,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        ),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        ),
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
        border: Border.all(
          color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
        ),
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

/// Fenêtre de Chat intelligente et gratuite pour la génération de rapports personnalisés.
class _SmartReportChatBot extends StatefulWidget {
  final DashboardStatsResult? stats;

  const _SmartReportChatBot({this.stats});

  @override
  State<_SmartReportChatBot> createState() => _SmartReportChatBotState();
}

class _SmartReportChatBotState extends State<_SmartReportChatBot> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'isUser': false,
      'text':
          "Bonjour ! Je suis votre assistant Smart Report Cercle Bleu. 🦀\n"
          "Je peux analyser instantanément vos données d'enquêtes actuelles (Terrain, Labo, LEK et Chercheurs) pour rédiger un rapport personnalisé sans frais.\n\n"
          "Que souhaitez-vous synthétiser aujourd'hui ?",
    });
  }

  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;
    _messageController.clear();

    setState(() {
      _messages.add({'isUser': true, 'text': text});
      _isTyping = true;
    });

    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final reply = _generateIntelligenceReport(text.toLowerCase());
      setState(() {
        _messages.add({'isUser': false, 'text': reply});
        _isTyping = false;
      });
    });
  }

  String _generateIntelligenceReport(String input) {
    final s = widget.stats;
    if (s == null) {
      return "Aucune donnée statistique n'est chargée actuellement. Veuillez actualiser le dashboard.";
    }

    final totalEnquetes = s.totalTerrain + s.totalLabo + s.totalLek;

    if (input.contains('global') || input.contains('synthèse') || input.contains('tout')) {
      return "📊 **RAPPORT ANALYTIQUE GLOBAL - CERCLE BLEU**\n\n"
          "• **Volume total d'activités** : $totalEnquetes formulaires enregistrés.\n"
          "• **Répartition des Enquêtes** :\n"
          "  - Données Terrain : ${s.totalTerrain} saisies\n"
          "  - Données Labo : ${s.totalLabo} analyses\n"
          "  - Questionnaires LEK : ${s.totalLek} sessions\n\n"
          "• **Indicateurs clés** : Un ensemble de ${s.totalPortsUniques} ports uniques ont été échantillonnés, totalisant un prélèvement ou observation de ${s.totalCrabes} crabes.\n\n"
          "💡 *Analyse objective* : Le focus d'effort actuel est majoritairement orienté vers le volet ${s.totalTerrain >= s.totalLabo ? 'Terrain' : 'Laboratoire'}.";
    } else if (input.contains('terrain') || input.contains('port') || input.contains('crabe')) {
      String portsStr = s.topPorts.map((e) => "- ${e.label} (${e.value})").join("\n");
      return "🗺️ **RAPPORT FOCUS : DONNÉES TERRAIN & PORTS**\n\n"
          "• **Saisies géographiques** : ${s.totalTerrain} formulaires complétés sur le terrain.\n"
          "• **Diversité spatiale** : Échantillonnage étalé sur ${s.totalPortsUniques} ports de pêche.\n"
          "• **Volume de captures** : ${s.totalCrabes} spécimens enregistrés au total.\n\n"
          "📌 **Top Ports actifs** :\n${portsStr.isNotEmpty ? portsStr : 'Aucune donnée portuaire détaillée.'}";
    } else if (input.contains('labo') || input.contains('laboratoire') || input.contains('espèce')) {
      String espStr = s.topEspeces.map((e) => "- ${e.label} (${e.value})").join("\n");
      return "🔬 **RAPPORT FOCUS : DONNÉES LABORATOIRE**\n\n"
          "• **Analyses biologiques** : ${s.totalLabo} échantillons traités en laboratoire.\n\n"
          "📌 **Distribution des principales Espèces analysées** :\n${espStr.isNotEmpty ? espStr : 'Aucune espèce listée.'}\n\n"
          "💡 *Recommandation* : Croiser ces résultats morphométriques avec le calendrier des marées du LEK pour valider les pics de ponte.";
    } else if (input.contains('lek') || input.contains('questionnaire')) {
      return "💬 **RAPPORT FOCUS : TRADITIONS & CONNAISSANCES (LEK)**\n\n"
          "• **Enquêtes de connaissances écologiques locales (LEK)** : ${s.totalLek} questionnaires soumis auprès des communautés de pêcheurs.\n\n"
          "💡 *Analyse qualitative* : Ces données permettent de corréler l'historique de l'invasion du crabe bleu avec les variations quantitatives observées sur le terrain (${s.totalTerrain} observations récurrentes).";
    } else if (input.contains('chercheur')) {
      return "👥 **RAPPORT DES ACTIVITÉS CHERCHEURS**\n\n"
          "• Les options de filtrage incluent un panel de ${(s.ownerOptions).length} chercheurs actifs enregistrés sur cette période.\n"
          "• La couverture d'analyse montre une répartition dynamique sur les ${s.totalPortsUniques} ports référencés.\n\n"
          "Pour auditer un chercheur spécifique, sélectionnez son nom dans les filtres de la page principale pour recalculer le rapport d'activité.";
    } else {
      return "Je comprends votre intérêt pour nos données. Voici ce que je peux générer précisément avec les filtres actuels :\n"
          "- Tapez **'global'** pour un rapport de synthèse général.\n"
          "- Tapez **'terrain'** pour analyser les ports et les crabes capturés.\n"
          "- Tapez **'labo'** pour voir la distribution des espèces en laboratoire.\n"
          "- Tapez **'lek'** pour le suivi des questionnaires pêcheurs.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF1E3A8A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00D9D9)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Report Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Rapports d\'enquêtes instantanés • Gratuit',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1E3A8A) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isUser ? Colors.white : const Color(0xFF1E3A8A),
                        fontSize: 14.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF00D9D9),
                    ),
                  ),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildQuickChip("📋 Rapport Global"),
                _buildQuickChip("🗺️ Focus Terrain & Ports"),
                _buildQuickChip("🔬 Analyses Labo"),
                _buildQuickChip("💬 Synthèse LEK"),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              14,
              8,
              14,
              MediaQuery.of(context).viewInsets.bottom + 14,
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: _handleSendMessage,
                    decoration: InputDecoration(
                      hintText: "Demander un rapport personnalisé...",
                      hintStyle: const TextStyle(fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleSendMessage(_messageController.text),
                  icon: const Icon(
                    Icons.send_rounded,
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

  Widget _buildQuickChip(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF00D9D9).withValues(alpha: 0.15),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => _handleSendMessage(label),
      ),
    );
  }
}