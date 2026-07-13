import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/attachment_item.dart';
import '../../services/attachment_download_service.dart';
import '../../services/attachment_service.dart';

class AttachmentsScreen extends StatefulWidget {
  final String title;
  final String formType;
  final String formId;

  const AttachmentsScreen({
    super.key,
    required this.title,
    required this.formType,
    required this.formId,
  });

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen>
    with SingleTickerProviderStateMixin {
  final AttachmentService _service = AttachmentService();
  final AttachmentDownloadService _downloadService = AttachmentDownloadService();
  final ImagePicker _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  late final TabController _tabController;
  bool _isUploading = false;
  bool _isRecording = false;
  String? _playingId;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

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
    _service.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  String _friendlyError(Object e) {
    if (e is FirebaseException) {
      final code = e.code.toLowerCase();
      if (code == 'permission-denied' || code == 'unauthorized') {
        return 'Acces refuse : vous n\'avez pas la permission.';
      }
      return 'Operation impossible. Reessayez.';
    }
    return 'Operation impossible. Reessayez.';
  }

  Future<ImageSource?> _choosePhotoSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPhoto() async {
    final source = await _choosePhotoSource();
    if (source == null) return;

    final ok = source == ImageSource.camera
        ? await _requestPermission(Permission.camera)
        : await _requestPermission(Permission.photos) ||
              await _requestPermission(Permission.storage);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission photo/camera refusee.')),
      );
      return;
    }

    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Utilisateur non connecte.');
      }
      final owner = await _service.currentOwnerInfo();
      await _service.uploadPhoto(
        formType: widget.formType,
        formId: widget.formId,
        file: File(picked.path),
        ownerId: owner['uid'] ?? user.uid,
        ownerName: owner['name'] ?? (user.displayName ?? 'Utilisateur'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo ajoutee ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur ajout photo: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleAudio() async {
    if (_isRecording) {
      setState(() => _isUploading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw StateError('Utilisateur non connecte.');
        }
        final owner = await _service.currentOwnerInfo();
        final audioFile = await _service.stopAudioRecordingFile();
        await _service.uploadAudio(
          formType: widget.formType,
          formId: widget.formId,
          file: audioFile,
          ownerId: owner['uid'] ?? user.uid,
          ownerName: owner['name'] ?? (user.displayName ?? 'Utilisateur'),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Audio ajoute ✅')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ajout audio: ${_friendlyError(e)}')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
            _isRecording = false;
          });
        }
      }
      return;
    }

    final ok = await _requestPermission(Permission.microphone);
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission microphone refusee.')),
      );
      return;
    }
    try {
      await _service.startAudioRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistrement en cours...')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de demarrer: ${_friendlyError(e)}')),
      );
    }
  }

  Future<void> _playOrPause(AttachmentItem att) async {
    if (_playingId == att.id) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _playingId = null);
      return;
    }

    await _audioPlayer.stop();
    if (att.downloadUrl.trim().isNotEmpty) {
      await _audioPlayer.setUrl(att.downloadUrl);
    } else {
      final localPath = await _service.materializeAttachmentTempFile(att);
      await _audioPlayer.setFilePath(localPath);
    }
    await _audioPlayer.play();
    if (!mounted) return;
    setState(() {
      _playingId = att.id;
      _position = Duration.zero;
    });
  }

  Future<void> _delete(AttachmentItem att) async {
    final canDelete = await _service.canDeleteAttachment(att);
    if (!mounted) return;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acces refuse : suppression non autorisee.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

    try {
      await _service.deleteAttachment(
        formType: widget.formType,
        formId: widget.formId,
        att: att,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Piece jointe supprimee.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible: ${_friendlyError(e)}')),
      );
    }
  }

  Future<void> _downloadAttachment(AttachmentItem att) async {
    setState(() => _isUploading = true);
    try {
      final location = await _downloadService.downloadAttachmentItem(att);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Telechargement termine ($location)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur telechargement: ${_friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _openPhoto(AttachmentItem att) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(att.fileName, overflow: TextOverflow.ellipsis),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          body: Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: FutureBuilder<Widget>(
              future: () async {
                if (att.downloadUrl.trim().isNotEmpty) {
                  return Image.network(att.downloadUrl, fit: BoxFit.contain);
                }
                final bytes = await _service.readAttachmentBytes(att);
                return Image.memory(bytes, fit: BoxFit.contain);
              }(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const CircularProgressIndicator();
                }
                return InteractiveViewer(child: snap.data!);
              },
            ),
          ),
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  DateTime _dateOrNow(AttachmentItem att) {
    return att.createdAt?.toDate() ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3A8A), Color(0xFF2D4BA8), Color(0xFFF5F9FF)],
            stops: [0.0, 0.35, 0.35],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset('assets/image/logo.png', height: 80),
              ),
              const SizedBox(height: 12),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: LinearProgressIndicator(minHeight: 4),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F9FF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF1E3A8A),
                          tabs: const [Tab(text: 'Photos'), Tab(text: 'Audio')],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildTabContent(
                              type: 'photo',
                              buttonLabel: '+ Ajouter photo',
                              buttonColor: const Color(0xFF1E3A8A),
                              onAdd: _isUploading ? null : _addPhoto,
                            ),
                            _buildTabContent(
                              type: 'audio',
                              buttonLabel: _isRecording
                                  ? 'Stop et envoyer'
                                  : '+ Ajouter audio',
                              buttonColor: const Color(0xFF00B8B8),
                              onAdd: _isUploading ? null : _toggleAudio,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required String type,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback? onAdd,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: Icon(
                  type == 'photo'
                      ? Icons.add_a_photo_outlined
                      : Icons.mic_none_rounded,
                  size: 18,
                ),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<AttachmentItem>>(
              stream: _service.watchAttachments(
                formType: widget.formType,
                formId: widget.formId,
                type: type,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Chargement impossible.'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(type == 'photo' ? 'Aucune photo' : 'Aucun audio'),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, index2) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final att = items[index];
                    return Container(
                      padding: const EdgeInsets.all(10),
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
                                type == 'photo'
                                    ? Icons.image_outlined
                                    : Icons.mic_none_rounded,
                                color: const Color(0xFF1E3A8A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  att.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _isUploading
                                    ? null
                                    : () => _downloadAttachment(att),
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _delete(att),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${_fmtBytes(att.size)} • ${_dateFormat.format(_dateOrNow(att))}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (type == 'photo')
                            FutureBuilder<Widget>(
                              future: () async {
                                if (att.downloadUrl.trim().isNotEmpty) {
                                  return Image.network(
                                    att.downloadUrl,
                                    height: 130,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                }
                                final bytes = await _service.readAttachmentBytes(
                                  att,
                                );
                                return Image.memory(
                                  bytes,
                                  height: 130,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                );
                              }(),
                              builder: (context, snap) {
                                if (!snap.hasData) {
                                  return const SizedBox(
                                    height: 130,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return GestureDetector(
                                  onTap: () => _openPhoto(att),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: snap.data!,
                                  ),
                                );
                              },
                            )
                          else
                            Column(
                              children: [
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _playOrPause(att),
                                      icon: Icon(
                                        _playingId == att.id
                                            ? Icons.pause_circle_outline
                                            : Icons.play_circle_outline,
                                      ),
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: _playingId == att.id
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
                                        onChanged: _playingId == att.id
                                            ? (v) => _audioPlayer.seek(
                                                Duration(
                                                  milliseconds: v.round(),
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
                                    '${_fmtDuration(_position)} / ${_fmtDuration(_duration)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
