import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<void> logEvent(String eventName) async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? deviceId;

  try {
    // On récupère l'identifiant unique du téléphone comme dans HomeScreen
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    }
  } catch (e) {
    deviceId = null;
  }

  await FirebaseFirestore.instance.collection('analytics').add({
    'event': eventName,
    'timestamp': FieldValue.serverTimestamp(),
    'userId': FirebaseAuth
        .instance
        .currentUser
        ?.uid, // On laisse null si pas connecté
    'deviceId': deviceId, // <--- C'EST CETTE LIGNE QUI VA TOUT ALIGNER
  });
}
