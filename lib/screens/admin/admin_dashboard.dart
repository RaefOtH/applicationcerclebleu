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
import 'admin_pdf_template_screen.dart';
import 'admin_researchers_screen.dart';
import 'admin_surveys_screen.dart';
import 'widgets/admin_role_guard.dart';

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
                      color: const Color(0xFF00D9D9).withOpacity(0.12),
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
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.28),
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
                      color: Colors.white.withOpacity(0.9),
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
                          if (!places.contains(_selectedPlace))
                            _selectedPlace = 'Tous';
                          if (!labs.contains(_selectedLab))
                            _selectedLab = 'Tous';

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
                                          ).withOpacity(0.08),
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
                                      'Voir et filtrer toutes les saisies Terrain et Labo',
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
                                        stats.totalLabo == 0))
                                  _EmptyCard(
                                    text:
                                        'Aucune donnée trouvée pour les filtres sélectionnés.',
                                  )
                                else ...[
                                  _SummaryCard(
                                    totalTerrain: stats.totalTerrain,
                                    totalLabo: stats.totalLabo,
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
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
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
            value: selectedOwnerId,
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
            value: selectedPlace,
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
            value: selectedLab,
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
            color: const Color(0xFF00D9D9).withOpacity(0.22),
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
          border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00D9D9).withOpacity(0.15),
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

  const _SummaryCard({required this.totalTerrain, required this.totalLabo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
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
                  label: 'Laboratoire',
                  value: totalLabo.toString(),
                  icon: Icons.science_outlined,
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
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
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
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.08)),
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
