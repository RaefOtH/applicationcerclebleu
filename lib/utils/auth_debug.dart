import 'package:flutter/foundation.dart';

const bool kAuthDebugLogs = true;

void authDebugLog(String message) {
  if (!kAuthDebugLogs) return;
  debugPrint(message);
}
