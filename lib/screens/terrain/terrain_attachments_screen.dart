import 'package:flutter/material.dart';

import '../common/attachments_screen.dart';

class TerrainAttachmentsScreen extends StatelessWidget {
  final String formId;

  const TerrainAttachmentsScreen({super.key, required this.formId});

  @override
  Widget build(BuildContext context) {
    return AttachmentsScreen(
      title: 'Pieces jointes terrain',
      formType: 'terrain',
      formId: formId,
    );
  }
}
