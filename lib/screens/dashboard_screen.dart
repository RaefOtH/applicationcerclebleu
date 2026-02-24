import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'dart:math' as math;

import '../models/app_user.dart';
import '../painters/wave_painter.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/csv_export_service.dart';
import '../services/user_service.dart';
import 'labo/lab_entry_choice_screen.dart';
import 'terrain/terrain_entry_choice_screen.dart';

class DashboardScreen extends StatefulWidget {
  final AppUser? user;
  final String dashboardTitle;
  const DashboardScreen({
    super.key,
    this.user,
    this.dashboardTitle = 'Dashboard',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final CsvExportService _csvExportService = CsvExportService();
  AppUser? _userProfile;
  bool _isExportingCsv = false;
  bool _loadingProfile = false;
  StreamSubscription<AppUser?>? _profileSub;
  late AnimationController _waveController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;

  final TextEditingController _searchController = TextEditingController();
  String selectedLocation = '';
  DateTime? selectedDate;
  List<Map<String, dynamic>> filteredSurveys = [];
  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();
  final List<Map<String, dynamic>> surveys = [
    {
      'id': 1,
      'location': 'Golfe de Tunis',
      'date': '08/02/2026',
      'count': 24,
      'status': 'En cours',
      'color': const Color(0xFF00D9D9),
    },
    {
      'id': 2,
      'location': 'Lac de Bizerte',
      'date': '07/02/2026',
      'count': 18,
      'status': 'Terminé',
      'color': const Color(0xFF1E3A8A),
    },
    {
      'id': 3,
      'location': 'Baie de Hammamet',
      'date': '05/02/2026',
      'count': 31,
      'status': 'Terminé',
      'color': const Color(0xFF1E3A8A),
    },
  ];
  final List<Map<String, String>> stats = [
    {'label': 'Enquêtes', 'value': '127', 'trend': '+12%'},
    {'label': 'Crabes', 'value': '2,834', 'trend': '+8%'},
    {'label': 'Zones', 'value': '15', 'trend': '+2'},
  ];
  @override
  void initState() {
    super.initState();

    _userProfile = widget.user;
    if (_userProfile == null) {
      _loadProfile();
    }
    _bindProfileStream();

    filteredSurveys = List<Map<String, dynamic>>.from(surveys);
    _sortByDateDesc(filteredSurveys);
    _currentDateTime = DateTime.now();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _waveController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _clockTimer?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  void _bindProfileStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    _profileSub?.cancel();
    _profileSub = _userService.watchUserProfile(currentUser.uid).listen((p) {
      if (!mounted || p == null) return;
      setState(() => _userProfile = p);
    });
  }

  Future<void> _loadProfile() async {
    if (_loadingProfile) return;
    setState(() => _loadingProfile = true);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final profile = await _userService.getUserProfile(currentUser.uid);
      if (mounted) {
        setState(() => _userProfile = profile);
      }
    }
    if (mounted) {
      setState(() => _loadingProfile = false);
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fonctionnalité à venir')));
  }

  String _formatDateTime(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final yyyy = value.year.toString();
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9D9).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF00D9D9),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Déconnexion',
                style: TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text('Voulez-vous vous déconnecter ?'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, true),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Se déconnecter',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  void _applyFilters() {
    final query = selectedLocation.trim().toLowerCase();

    setState(() {
      final filtered = surveys.where((survey) {
        final location = (survey['location'] as String).toLowerCase();
        final matchesQuery = query.isEmpty || location.contains(query);

        if (selectedDate == null) {
          return matchesQuery;
        }

        final surveyDate = _parseDate(survey['date'] as String);
        if (surveyDate == null) return false;

        final sameDate = _isSameDate(surveyDate, selectedDate!);
        return matchesQuery && sameDate;
      }).toList();

      _sortByDateDesc(filtered);
      filteredSurveys = filtered;
    });
  }

  void _sortByDateDesc(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final da = _parseDate(a['date'] as String);
      final db = _parseDate(b['date'] as String);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
  }

  DateTime? _parseDate(String value) {
    final parts = value.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      selectedDate = picked;
      _applyFilters();
    }
  }

  Future<void> _showExportMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildExportItem(
                  icon: Icons.map_outlined,
                  label: 'Exporter Terrain',
                  onTap: () => _runExport('terrain'),
                ),
                _buildExportItem(
                  icon: Icons.science_outlined,
                  label: 'Exporter Laboratoire',
                  onTap: () => _runExport('lab'),
                ),
                _buildExportItem(
                  icon: Icons.dataset_outlined,
                  label: 'Exporter Tout',
                  onTap: () => _runExport('all'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: const Color(0xFFF8FBFF),
        leading: Icon(icon, color: const Color(0xFF1E3A8A)),
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E3A8A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _runExport(String type) async {
    Navigator.pop(context);
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecte.')),
      );
      return;
    }
    final role = (_userProfile?.role ?? '').trim().toLowerCase();
    final isAdmin = role == 'admin';

    setState(() => _isExportingCsv = true);
    try {
      final file = switch (type) {
        'terrain' => await _csvExportService.exportTerrainCsv(
          isAdmin: isAdmin,
          uid: current.uid,
        ),
        'lab' => await _csvExportService.exportLabCsv(
          isAdmin: isAdmin,
          uid: current.uid,
        ),
        _ => await _csvExportService.exportAllCsv(
          isAdmin: isAdmin,
          uid: current.uid,
        ),
      };
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV genere: ${file.path}')));
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Export CSV Cercle Bleu');
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message.toString())));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur pendant export CSV.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExportingCsv = false);
      }
    }
  }

  void _resetFilters() {
    setState(() {
      selectedDate = null;
      selectedLocation = '';
      _searchController.clear();
      filteredSurveys = List<Map<String, dynamic>>.from(surveys);
      _sortByDateDesc(filteredSurveys);
    });
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _safeText(_userProfile?.fullName, 'Utilisateur');
    final role = _safeText(_userProfile?.role, 'non défini');
    final email = _safeNullableText(_userProfile?.email);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildAnimatedHeader(fullName, role, email),
              ),
              SliverToBoxAdapter(child: _buildStatsSection()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Enquêtes récentes',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: _resetFilters,
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildSurveyCard(filteredSurveys[index], index),
                    childCount: filteredSurveys.length,
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 30,
            child: _buildFloatingActionButton(),
          ),
        ],
      ),
    );
  }

  String _safeText(String? value, String fallback) {
    final t = value?.trim() ?? '';
    if (t.isEmpty || t.toLowerCase() == 'null') return fallback;
    return t;
  }

  String? _safeNullableText(String? value) {
    final t = value?.trim() ?? '';
    if (t.isEmpty || t.toLowerCase() == 'null') return null;
    return t;
  }

  Widget _buildAnimatedHeader(String fullName, String role, String? email) {
    return Stack(
      children: [
        Container(
          height: 280,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8), Color(0xFF1E3A8A)],
            ),
          ),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withOpacity(0.15),
                      waveHeight: 20,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(
                      animation: _waveController.value,
                      color: const Color(0xFF00D9D9).withOpacity(0.1),
                      waveHeight: 30,
                      offset: 100,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
              ..._buildFloatingBubbles(),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _confirmLogout,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: _isExportingCsv ? null : _showExportMenu,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: _isExportingCsv
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.file_download_outlined,
                              color: Colors.white,
                            ),
                      tooltip: 'Exporter CSV',
                    ),
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatDateTime(_currentDateTime),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
                            'role': role,
                            'email': email,
                          },
                        );
                      },
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cercle Bleu',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Bonjour, $fullName',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.dashboardTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 1000),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Opacity(opacity: value, child: child),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        selectedLocation = value;
                        _applyFilters();
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher une enquête...',
                        hintStyle: TextStyle(
                          color: const Color(0xFF1E3A8A).withOpacity(0.5),
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: const Color(0xFF1E3A8A).withOpacity(0.6),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9D9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: List.generate(stats.length, (index) {
          return Expanded(
            child: TweenAnimationBuilder(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, double value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(opacity: safeOpacity, child: child),
                );
              },
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == stats.length - 1 ? 0 : 6,
                ),
                child: _buildStatCard(stats[index]),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStatCard(Map<String, String> stat) {
    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            0,
            math.sin(_floatingController.value * 2 * math.pi) * 3,
          ),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
        child: Column(
          children: [
            Text(
              stat['value']!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
                height: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stat['label']!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9D9).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                stat['trend']!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF00D9D9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showComingSoon,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: survey['color'].withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            survey['color'].withOpacity(0.1),
                            survey['color'].withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF00D9D9,
                                          ).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.location_on_rounded,
                                          color: Color(0xFF00D9D9),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          survey['location'],
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E3A8A),
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        survey['date'],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: survey['status'] == 'En cours'
                                    ? const Color(0xFF00D9D9).withOpacity(0.15)
                                    : const Color(0xFF1E3A8A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                survey['status'],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: survey['status'] == 'En cours'
                                      ? const Color(0xFF00D9D9)
                                      : const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(
                                  0xFF1E3A8A,
                                ).withOpacity(0.08),
                                width: 1.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${survey['count']}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1E3A8A),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'crabes capturés',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF00D9D9,
                                  ).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Color(0xFF00D9D9),
                                  size: 20,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () {
              _showCreateMenu();
            },
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D9D9).withOpacity(0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nouvelle saisie',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                _buildModalButton(
                  icon: Icons.assignment_rounded,
                  label: 'Enquête : Données Terrain',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D9D9), Color(0xFF00B8B8)],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const TerrainEntryChoiceScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildModalButton(
                  icon: Icons.science_rounded,
                  label: 'Données laboratoire',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8)],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => const LabEntryChoiceScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: BorderSide(color: Colors.grey.shade300, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9D9).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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

  List<Widget> _buildFloatingBubbles() {
    return List.generate(5, (index) {
      return AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          final offset =
              math.sin((_floatingController.value * 2 * math.pi) + index) * 15;
          return Positioned(
            left: 30.0 + (index * 80.0),
            top: 100 + offset,
            child: Container(
              width: 40 + (index * 10.0),
              height: 40 + (index * 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
