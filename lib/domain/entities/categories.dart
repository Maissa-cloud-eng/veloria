import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoryData {
  final String id;
  final String name; // Français (Clé technique)
  final String name_en; // Anglais
  final String name_ar; // Arabe
  final List<SubCategoryData> subCategories;
  final int order;
  final int iconCodePoint;
  final CategoryGuide? guide;

  CategoryData({
    required this.id,
    required this.name,
    required this.name_en,
    this.name_ar = '',
    required this.subCategories,
    required this.order,
    required this.iconCodePoint,
    this.guide,
  });

  factory CategoryData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Document data for category is null");

    final defaultCodePoint = Icons.category.codePoint;
    final codePoint =
        (data['iconCodePoint'] as num?)?.toInt() ?? defaultCodePoint;

    // --- PARSING DES SOUS-CATÉGORIES ---
    List<SubCategoryData> parsedSubCats = [];
    if (data['subCategories'] != null) {
      final list = data['subCategories'] as List;
      parsedSubCats = list.map((item) {
        if (item is Map) {
          return SubCategoryData.fromMap(Map<String, dynamic>.from(item));
        } else {
          return SubCategoryData(
            name: item.toString(),
            name_en: item.toString(),
            name_ar: item.toString(),
          );
        }
      }).toList();
    }

    // --- PARSING DU GUIDE ---
    CategoryGuide? parsedGuide;
    if (data['guide'] != null) {
      parsedGuide = CategoryGuide.fromMap(
        Map<String, dynamic>.from(data['guide']),
      );
    }

    return CategoryData(
      id: doc.id,
      name: data['name']?.toString() ?? doc.id,
      name_en:
          data['name_en']?.toString() ?? data['name']?.toString() ?? doc.id,
      name_ar:
          data['name_ar']?.toString() ?? data['name']?.toString() ?? doc.id,
      order: (data['order'] as num?)?.toInt() ?? 99,
      iconCodePoint: codePoint,
      subCategories: parsedSubCats,
      guide: parsedGuide,
    );
  }

  IconData get iconData => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
}

// --- STRUCTURE DU GUIDE BEAUTÉ ---
class CategoryGuide {
  final String intro;
  final String intro_en;
  final String facts;
  final String facts_en;
  final String intro_ar;
  final String facts_ar;
  final List<GuideStep> steps;
  final List<GuideStep> optional;

  CategoryGuide({
    required this.intro,
    required this.intro_en,
    required this.facts,
    required this.facts_en,
    this.intro_ar = '',
    this.facts_ar = '',
    required this.steps,
    required this.optional,
  });

  factory CategoryGuide.fromMap(Map<String, dynamic> map) {
    return CategoryGuide(
      intro: map['intro']?.toString() ?? '',
      intro_en: map['intro_en']?.toString() ?? '',
      facts: map['facts']?.toString() ?? '',
      facts_en: map['facts_en']?.toString() ?? '',
      intro_ar: map['intro_ar']?.toString() ?? '',
      facts_ar: map['facts_ar']?.toString() ?? '',
      steps: _parseAndSortSteps(map['steps']), // Utilise la fonction de tri
      optional: _parseAndSortSteps(map['optional']), // Idem pour optionnel
    );
  }

  // --- LOGIQUE DE TRI AUTOMATIQUE ---
  static List<GuideStep> _parseAndSortSteps(dynamic list) {
    if (list == null || list is! List) return [];

    // 1. On transforme les données Firestore en objets GuideStep
    final steps = list
        .map((e) => GuideStep.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    // 2. On trie la liste par le champ 'order' (du plus petit au plus grand)
    steps.sort((a, b) => a.order.compareTo(b.order));

    return steps;
  }
}

// --- DÉTAIL D'UNE ÉTAPE (TITRE + DESCRIPTION + ORDRE) ---
class GuideStep {
  final String title;
  final String title_en;
  final String desc;
  final String desc_en;
  final String title_ar;
  final String desc_ar;
  final int order; // Indispensable pour garder l'ordre dans Firestore

  GuideStep({
    required this.title,
    required this.title_en,
    required this.desc,
    required this.desc_en,
    this.title_ar = '',
    this.desc_ar = '',
    required this.order,
  });

  factory GuideStep.fromMap(Map<String, dynamic> map) {
    return GuideStep(
      title: map['title']?.toString() ?? '',
      title_en: map['title_en']?.toString() ?? '',
      desc: map['desc']?.toString() ?? '',
      desc_en: map['desc_en']?.toString() ?? '',
      title_ar: map['title_ar']?.toString() ?? '',
      desc_ar: map['desc_ar']?.toString() ?? '',
      // Si l'ordre n'est pas précisé dans Firebase, on le met à 99 pour le mettre à la fin
      order: (map['order'] as num?)?.toInt() ?? 99,
    );
  }
}

class SubCategoryData {
  final String name;
  final String name_en;
  final String name_ar;

  SubCategoryData({
    required this.name,
    required this.name_en,
    this.name_ar = '',
  });

  factory SubCategoryData.fromMap(Map<String, dynamic> map) {
    return SubCategoryData(
      name: map['name']?.toString() ?? '',
      name_en: map['name_en']?.toString() ?? map['name']?.toString() ?? '',
      name_ar: map['name_ar']?.toString() ?? map['name']?.toString() ?? '',
    );
  }
}
