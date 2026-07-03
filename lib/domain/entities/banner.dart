import 'package:flutter/material.dart';

class BannerModel {
  final String type;
  final List<String> texts;
  final List<String>? imageAssets;
  // REMPLACEMENT : On stocke les codes points (entiers) au lieu des objets IconData
  final List<int>? iconCodePoints;
  final String? buttonText;

  final String? actionType;
  final String? actionId;
  final VoidCallback? onTap;

  BannerModel({
    required this.type,
    required this.texts,
    this.imageAssets,
    this.iconCodePoints, // Mis à jour ici
    this.buttonText,
    this.actionType,
    this.actionId,
    this.onTap,
  });

  factory BannerModel.fromFirestore(Map<String, dynamic> doc) {
    return BannerModel(
      type: doc['type'] ?? '',
      texts: List<String>.from(doc['texts'] ?? []),
      imageAssets: doc['imageAssets'] != null
          ? List<String>.from(doc['imageAssets'])
          : null,
      // MAPPING : On récupère la liste d'entiers depuis Firestore
      iconCodePoints: doc['iconCodePoints'] != null
          ? List<int>.from(doc['iconCodePoints'])
          : null,
      buttonText: doc['buttonText'],
      actionType: doc['actionType'],
      actionId: doc['actionId'],
    );
  }

  // MÉTHODE UTILITAIRE : Pour transformer les codes en icônes réelles dans ton widget
  List<IconData> get icons {
    if (iconCodePoints == null) return [];
    return iconCodePoints!
        .map((code) => IconData(code, fontFamily: 'MaterialIcons'))
        .toList();
  }
}
