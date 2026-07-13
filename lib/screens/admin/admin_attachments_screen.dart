import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attachment_item.dart';
import '../../services/attachment_download_service.dart';
import '../../services/attachment_service.dart';
import '../../services/firestore_db.dart';
import 'widgets/admin_role_guard.dart';

class AdminAttachmentsScreen extends StatefulWidget {
  const AdminAttachmentsScreen({super.key});

  @override
  State<AdminAttachmentsScreen> createState() => _AdminAttachmentsScreenState();
}

class _AdminAttachmentsScreenState extends State<AdminAttachmentsScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirestoreDb.db;
  final AttachmentDownloadService _downloadService = AttachmentDownloadService();
  final AttachmentService _attachmentService = AttachmentService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DateFormat _df = DateFormat('dd/MM/yyyy HH:mm');

  late final TabController _tabController;
  bool _showFilters = false;
  bool _loadingDownload = false;
  bool _bulkDownloading = false;
  int _bulkDone = 0;
  int _bulkTotal = 0;
  String? _playingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  DateTimeRange? _range;
  String _selectedResearcher = 'Tous';
  String _selectedSurvey = 'Tous';
  String _selectedPlace = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _audioPlayer.positionStream.listen((value) {
      if (!mounted) return;
      setState(() => _position = value);
    });
    _audioPlayer.durationStream.listen((value) {
      if (!mounted) return;
      setState(() => _duration = value ?? Duration.zero);
    });
    _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          _playingId = null;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    _attachmentService.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _range,
    );
    if (picked == null) return;
    setState(() => _range = picked);
  }

  bool _isInRange(DateTime dt) {
    if (_range == null) return true;
    final start = DateTime(
      _range!.start.year,
      _range!.start.month,
      _range!.start.day,
    );
    final end = DateTime(
      _range!.end.year,
      _range!.end.month,
      _range!.end.day,
      23,
      59,
      59,
    );
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  bool _matchesFilters(Map<String, dynamic> m, String wantedType) {
    var type = (m['type'] ?? '').toString().trim();
    if (type.isEmpty) {
      final ct = (m['contentType'] ?? '').toString().toLowerCase();
      if (ct.startsWith('image/')) {
        type = 'photo';
      } else if (ct.startsWith('audio/')) {
        type = 'audio';
      }
    }
    if (type != wantedType) return false;

    final researcher = (m['createdByName'] ?? m['ownerId'] ?? '')
        .toString()
        .trim();
    final survey = (m['formId'] ?? '').toString().trim();
    final place = (m['place'] ?? '').toString().trim();
    final createdAt = m['createdAt'];
    final createdDate = createdAt is Timestamp ? createdAt.toDate() : DateTime.now();

    if (_selectedResearcher != 'Tous' && researcher != _selectedResearcher) {
      return false;
    }
    if (_selectedSurvey != 'Tous' && survey != _selectedSurvey) {
      return false;
    }
    if (_selectedPlace != 'Tous' && place != _selectedPlace) {
      return false;
    }
    return _isInRange(createdDate);
  }

  Future<void> _download(Map<String, dynamic> data, String id) async {
    setState(() => _loadingDownload = true);
    try {
      final payload = Map<String, dynamic>.from(data)..['id'] = id;
      final location = await _downloadService.downloadAttachmentData(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fichier telecharge ($location)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur telechargement du fichier: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDownload = false);
    }
  }

  Future<void> _delete(Map<String, dynamic> data, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Supprimer cette piece jointe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loadingDownload = true);
    try {
      final map = Map<String, dynamic>.from(data);
      var type = (map['type'] ?? '').toString().trim();
      final contentType = (map['contentType'] ?? '').toString().toLowerCase();
      if (type.isEmpty) {
        if (contentType.startsWith('image/')) {
          type = 'photo';
        } else if (contentType.startsWith('audio/')) {
          type = 'audio';
        }
      }
      final att = AttachmentItem.fromMap(id, {
        ...map,
        'type': type,
      });
      await _attachmentService.deleteAttachment(
        formType: att.formType,
        formId: att.formId,
        att: att,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Piece jointe supprimee.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur suppression: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingDownload = false);
    }
  }

  Future<void> _downloadAllFiltered(String type) async {
    if (_bulkDownloading) return;
    setState(() {
      _bulkDownloading = true;
      _bulkDone = 0;
      _bulkTotal = 0;
    });
    try {
      final snap = await _db
          .collection('attachments_files')
          .orderBy('createdAt', descending: true)
          .get();
      final docs = snap.docs
          .where((d) => _matchesFilters(d.data(), type))
          .toList(growable: false);
      setState(() {
        _bulkTotal = docs.length;
        _bulkDone = 0;
      });
      if (docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun fichier a telecharger.')),
        );
        return;
      }

      for (var i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final payload = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;
        await _downloadService.downloadAttachmentData(payload);
        if (!mounted) return;
        setState(() => _bulkDone = i + 1);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telechargement termine: $_bulkDone fichier(s).')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur pendant telechargement global.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _bulkDownloading = false;
        });
      }
    }
  }

  void _openPhotoPreview(String fileName, Map<String, dynamic> data) {
    final url = (data['downloadUrl'] ?? data['url'] ?? '').toString().trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(fileName.isEmpty ? 'Apercu photo' : fileName),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          body: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: FutureBuilder<Widget>(
              future: () async {
                if (url.isNotEmpty) {
                  return Image.network(url, fit: BoxFit.contain);
                }
                final payload = Map<String, dynamic>.from(data);
                final bytes = await _downloadService.readPreviewBytes(payload);
                return Image.memory(
                  bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
                  fit: BoxFit.contain,
                );
              }(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator(color: Colors.white);
                }
                return InteractiveViewer(child: snap.data!);
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleAudio(Map<String, dynamic> data, String id) async {
    if (_playingId == id) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _playingId = null);
      return;
    }

    final url = (data['downloadUrl'] ?? data['url'] ?? '').toString().trim();
    await _audioPlayer.stop();
    if (url.isNotEmpty) {
      await _audioPlayer.setUrl(url);
    } else {
      final payload = Map<String, dynamic>.from(data)..['id'] = id;
      final localPath = await _downloadService.materializeTempFileData(payload);
      await _audioPlayer.setFilePath(localPath);
    }
    await _audioPlayer.play();
    if (!mounted) return;
    setState(() {
      _playingId = id;
      _position = Duration.zero;
    });
  }

  String _fmtDuration(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override//Dossier Photos &Audio
  Widget build(BuildContext context) {
    return AdminRoleGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dossier Photos & Audio'),
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: const Color(0xFF00D9D9),
            tabs: const [
              Tab(text: 'Photos'),
              Tab(text: 'Audio'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Filtres'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _range = null;
                        _selectedResearcher = 'Tous';
                        _selectedSurvey = 'Tous';
                        _selectedPlace = 'Tous';
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reinitialiser'),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              child: _showFilters
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _db.collection('attachments_files').snapshots(),
                          builder: (context, snap) {
                            final docs = snap.data?.docs ?? const [];
                            final researchers = <String>{'Tous'};
                            final surveys = <String>{'Tous'};
                            final places = <String>{'Tous'};
                            for (final d in docs) {
                              final m = d.data();
                              final researcher = (m['createdByName'] ??
                                      m['ownerId'] ??
                                      '')
                                  .toString()
                                  .trim();
                              if (researcher.isNotEmpty) researchers.add(researcher);
                              final survey = (m['formId'] ?? '').toString().trim();
                              if (survey.isNotEmpty) surveys.add(survey);
                              final place = (m['place'] ?? '').toString().trim();
                              if (place.isNotEmpty) places.add(place);
                            }
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedResearcher,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Chercheur',
                                          isDense: true,
                                        ),
                                        items: researchers
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (v) => setState(
                                          () => _selectedResearcher = v ?? 'Tous',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedSurvey,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Enquete (formId)',
                                          isDense: true,
                                        ),
                                        items: surveys
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (v) => setState(
                                          () => _selectedSurvey = v ?? 'Tous',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        initialValue: _selectedPlace,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Place',
                                          isDense: true,
                                        ),
                                        items: places
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(
                                                  e,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                        onChanged: (v) => setState(
                                          () => _selectedPlace = v ?? 'Tous',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickRange,
                                        icon: const Icon(Icons.date_range),
                                        label: Text(
                                          _range == null
                                              ? 'Filtrer par date'
                                              : '${DateFormat('dd/MM').format(_range!.start)} - ${DateFormat('dd/MM').format(_range!.end)}',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            if (_loadingDownload || _bulkDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    const LinearProgressIndicator(minHeight: 3),
                    if (_bulkDownloading && _bulkTotal > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('$_bulkDone / $_bulkTotal'),
                        ),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildList(type: 'photo'),
                  _buildList(type: 'audio'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required String type}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _bulkDownloading ? null : () => _downloadAllFiltered(type),
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('Telecharger tout'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _db
                .collection('attachments_files')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('Erreur chargement des pieces jointes.'),
                );
              }
              final docs = snapshot.data?.docs ?? const [];
              final filtered = docs
                  .where((d) => _matchesFilters(d.data(), type))
                  .toList(growable: false);

              if (filtered.isEmpty) {
                return Center(
                  child: Text(type == 'photo' ? 'Aucune photo' : 'Aucun audio'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, index2) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final m = doc.data();
                  final fileName = (m['fileName'] ?? '').toString().trim();
                  final contentType = (m['contentType'] ?? '').toString().trim();
                  var itemType = (m['type'] ?? '').toString().trim();
                  if (itemType.isEmpty) {
                    final ct = contentType.toLowerCase();
                    if (ct.startsWith('image/')) {
                      itemType = 'photo';
                    } else if (ct.startsWith('audio/')) {
                      itemType = 'audio';
                    }
                  }
                  final formType = (m['formType'] ?? '').toString().trim();
                  final formId = (m['formId'] ?? '').toString().trim();
                  final researcher = (m['createdByName'] ?? m['ownerId'] ?? '')
                      .toString()
                      .trim();
                  final place = (m['place'] ?? '').toString().trim();
                  final createdAt = m['createdAt'];
                  final createdDate = createdAt is Timestamp
                      ? createdAt.toDate()
                      : DateTime.now();
                  final size = (m['sizeBytes'] is num)
                      ? (m['sizeBytes'] as num).toInt()
                      : 0;
                  final url = (m['downloadUrl'] ?? '').toString().trim();

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              itemType == 'audio'
                                  ? Icons.mic_none_rounded
                                  : Icons.image_outlined,
                              color: const Color(0xFF1E3A8A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fileName.isEmpty ? doc.id : fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _loadingDownload
                                  ? null
                                  : () => _download(m, doc.id),
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            if (type == 'audio')
                              IconButton(
                                onPressed: _loadingDownload
                                    ? null
                                    : () => _toggleAudio(m, doc.id),
                                icon: Icon(
                                  _playingId == doc.id
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            IconButton(
                              onPressed: _loadingDownload
                                  ? null
                                  : () => _delete(m, doc.id),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_fmtBytes(size)} • ${_df.format(createdDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          'Chercheur: ${researcher.isEmpty ? '-' : researcher}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        Text(
                          'Enquete: $formType / $formId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        if (place.isNotEmpty)
                          Text(
                            'Place: $place',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                        if (type == 'photo') ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _openPhotoPreview(fileName, m),
                            child: FutureBuilder<Widget>(
                              future: () async {
                                if (url.isNotEmpty &&
                                    contentType.toLowerCase().startsWith('image/')) {
                                  return Image.network(
                                    url,
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                }
                                final payload = Map<String, dynamic>.from(m)
                                  ..['id'] = doc.id;
                                final bytes =
                                    await _downloadService.readPreviewBytes(payload);
                                return Image.memory(
                                  bytes is Uint8List
                                      ? bytes
                                      : Uint8List.fromList(bytes),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }(),
                              builder: (context, snap) {
                                if (!snap.hasData) {
                                  return Container(
                                    height: 120,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const CircularProgressIndicator(),
                                  );
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: snap.data!,
                                );
                              },
                            ),
                          ),
                        ],
                        if (type == 'audio') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.audiotrack_rounded,
                                size: 18,
                                color: Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Slider(
                                  value: _playingId == doc.id
                                      ? _position.inMilliseconds
                                            .clamp(
                                              0,
                                              _duration.inMilliseconds <= 0
                                                  ? 1
                                                  : _duration.inMilliseconds,
                                            )
                                            .toDouble()
                                      : 0,
                                  max: (_duration.inMilliseconds <= 0
                                          ? 1
                                          : _duration.inMilliseconds)
                                      .toDouble(),
                                  onChanged: _playingId == doc.id
                                      ? (value) => _audioPlayer.seek(
                                            Duration(
                                              milliseconds: value.round(),
                                            ),
                                          )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _playingId == doc.id
                                  ? '${_fmtDuration(_position)} / ${_fmtDuration(_duration)}'
                                  : 'Appuyer sur lecture pour ouvrir le vocal',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
