import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

String? _currentSessionId;
DateTime? _lastActivityAt;
final Random _sessionRandom = Random();
const Duration _sessionTimeout = Duration(minutes: 30);

Future<String?> _getDeviceId() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  try {
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    }
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
  } catch (_) {
    return null;
  }

  return null;
}

String _getSessionId() {
  final now = DateTime.now();
  final shouldCreateSession =
      _currentSessionId == null ||
      _lastActivityAt == null ||
      now.difference(_lastActivityAt!) > _sessionTimeout;

  if (shouldCreateSession) {
    _currentSessionId =
        '${now.millisecondsSinceEpoch}-${_sessionRandom.nextInt(1 << 32)}';
  }

  _lastActivityAt = now;
  return _currentSessionId!;
}

Future<Map<String, dynamic>> getAnalyticsContext() async {
  final deviceId = await _getDeviceId();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  return {
    'userId': userId,
    'deviceId': deviceId,
    'sessionId': _getSessionId(),
    'platform': Platform.isAndroid
        ? 'Android'
        : Platform.isIOS
        ? 'iOS'
        : Platform.operatingSystem,
  };
}

Future<void> logEvent(
  String eventName, {
  Map<String, dynamic> extra = const {},
}) async {
  final context = await getAnalyticsContext();

  await FirebaseFirestore.instance.collection('analytics').add({
    'event': eventName,
    'timestamp': FieldValue.serverTimestamp(),
    ...context,
    ...extra,
  });
}
