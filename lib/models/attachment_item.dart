import 'package:cloud_firestore/cloud_firestore.dart';

class AttachmentItem {
  final String id;
  final String type;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String contentType;
  final int size;
  final String createdBy;
  final String createdByName;
  final String formId;
  final String formType;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final int? width;
  final int? height;
  final int? durationMs;

  const AttachmentItem({
    required this.id,
    required this.type,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.contentType,
    required this.size,
    required this.createdBy,
    required this.createdByName,
    required this.formId,
    required this.formType,
    this.createdAt,
    this.updatedAt,
    this.width,
    this.height,
    this.durationMs,
  });

  factory AttachmentItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? <String, dynamic>{};
    return AttachmentItem.fromMap(doc.id, map);
  }

  factory AttachmentItem.fromMap(String id, Map<String, dynamic> map) {
    int? parseInt(dynamic raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw.toString());
    }

    return AttachmentItem(
      id: id,
      type: (map['type'] ?? '').toString(),
      fileName: (map['fileName'] ?? '').toString(),
      storagePath: (map['storagePath'] ?? '').toString(),
      downloadUrl: (map['downloadUrl'] ?? '').toString(),
      contentType: (map['contentType'] ?? '').toString(),
      size: parseInt(map['size']) ?? parseInt(map['sizeBytes']) ?? 0,
      createdBy: (map['createdBy'] ?? map['ownerId'] ?? '').toString(),
      createdByName: (map['createdByName'] ?? '').toString(),
      formId: (map['formId'] ?? '').toString(),
      formType: (map['formType'] ?? '').toString(),
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? map['updatedAt'] as Timestamp
          : null,
      width: parseInt(map['width']),
      height: parseInt(map['height']),
      durationMs: parseInt(map['durationMs']),
    );
  }
}
