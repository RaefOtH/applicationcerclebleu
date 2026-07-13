import 'package:flutter/material.dart';

import '../common/attachments_screen.dart';

class LabAttachmentsScreen extends StatelessWidget {
  final String formId;

  const LabAttachmentsScreen({super.key, required this.formId});

  @override
  Widget build(BuildContext context) {
    return AttachmentsScreen(
      title: 'Pieces jointes laboratoire',
      formType: 'lab',
      formId: formId,
    );
  }
}
