import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String titleEn;
  final String titleAr;
  final String category;
  final String categoryEn;
  final String description;
  final String descriptionEn;
  final String descriptionAr;
  final String? subCategory;
  final String? subCategoryEn;
  final String? usageTips;
  final String? usageTipsEn;
  final String? usageTipsAr;
  final String? customBadge;
  final String? customBadgeEn;
  final String? customBadgeAr;
  final String? brand;
  final String price;
  final double costPrice;
  final String imageUrl;
  final String origin;
  final bool isPack;
  final bool isNewArrival;
  final bool isOutOfStock; // <--- AJOUTÉ ICI
  final Timestamp? createdAt;
  final String? contents;
  final String? unit;
  final String? composition;
  final List<FlavorOption>? flavorOptions;
  final List<String> tags;
  final int? score;

  Product({
    required this.id,
    required this.title,
    required this.titleEn,
    this.titleAr = "",
    this.brand,
    required this.price,
    this.costPrice = 0.0,
    required this.imageUrl,
    required this.category,
    required this.categoryEn,
    this.subCategory,
    this.subCategoryEn,
    this.origin = "Local",
    this.isPack = false,
    this.isNewArrival = false,
    this.isOutOfStock = false, // <--- AJOUTÉ ICI (Défaut : en stock)
    this.createdAt,
    this.description = "",
    required this.descriptionEn,
    this.descriptionAr = "",
    this.usageTips,
    this.usageTipsEn,
    this.usageTipsAr,
    this.customBadge,
    this.customBadgeEn,
    this.customBadgeAr,
    this.contents,
    this.composition,
    this.unit,
    this.flavorOptions,
    this.tags = const [],
    this.score,
  });

  // --- Sauvegarde vers Firestore ---
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'title_en': titleEn,
      'title_ar': titleAr,
      'brand': brand,
      'price': price,
      'costPrice': costPrice,
      'imageUrl': imageUrl,
      'category': category,
      'category_en': categoryEn,
      'subCategory': subCategory,
      'subCategory_en': subCategoryEn,
      'origin': origin,
      'isPack': isPack,
      'isNewArrival': isNewArrival,
      'isOutOfStock': isOutOfStock, // <--- AJOUTÉ ICI
      'createdAt': createdAt,
      'description': description,
      'description_en': descriptionEn,
      'description_ar': descriptionAr,
      'usageTips': usageTips,
      'usageTips_en': usageTipsEn,
      'usageTips_ar': usageTipsAr,
      'customBadge': customBadge,
      'customBadge_en': customBadgeEn,
      'customBadge_ar': customBadgeAr,
      'contents': contents,
      'unit': unit,
      'composition': composition,
      'tags': tags,
      'score': score,
      'flavorOptions': flavorOptions
          ?.map(
            (f) => {
              'name': f.name,
              'name_en': f.nameEn,
              'name_ar': f.nameAr,
              'color': f.color.value,
              'imageUrl': f.imageUrl,
            },
          )
          .toList(),
    };
  }

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Product.fromMap({...data, 'id': doc.id});
  }

  // --- Lecture depuis Firestore ---
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      titleEn: map['title_en']?.toString() ?? map['title']?.toString() ?? '',
      titleAr: map['title_ar']?.toString() ?? '',
      brand: map['brand']?.toString(),
      price: map['price']?.toString() ?? '',
      costPrice: (map['costPrice'] is num)
          ? (map['costPrice'] as num).toDouble()
          : 0.0,
      imageUrl: map['imageUrl']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      categoryEn:
          map['category_en']?.toString() ?? map['category']?.toString() ?? '',
      subCategory: map['subCategory']?.toString(),
      subCategoryEn:
          map['subCategory_en']?.toString() ?? map['subCategory']?.toString(),
      origin: map['origin']?.toString() ?? "Local",
      isPack: map['isPack'] ?? false,
      isNewArrival: map['isNewArrival'] ?? false,
      isOutOfStock: map['isOutOfStock'] ?? false, // <--- AJOUTÉ ICI
      createdAt: map['createdAt'],
      description: map['description']?.toString() ?? '',
      descriptionEn:
          map['description_en']?.toString() ??
          map['description']?.toString() ??
          '',
      descriptionAr: map['description_ar']?.toString() ?? '',
      usageTips: map['usageTips']?.toString(),
      usageTipsEn:
          map['usageTips_en']?.toString() ?? map['usageTips']?.toString(),
      usageTipsAr: map['usageTips_ar']?.toString(),
      customBadge: map['customBadge']?.toString(),
      customBadgeEn:
          map['customBadge_en']?.toString() ?? map['customBadge']?.toString(),
      customBadgeAr: map['customBadge_ar']?.toString(),
      contents: map['contents']?.toString(),
      unit: map['unit']?.toString(),
      composition: map['composition']?.toString(),
      tags: _convertToList(map['tags']),
      flavorOptions: map['flavorOptions'] != null
          ? (map['flavorOptions'] as List<dynamic>)
                .map(
                  (f) => FlavorOption(
                    name: f['name']?.toString() ?? '',
                    nameEn:
                        f['name_en']?.toString() ?? f['name']?.toString() ?? '',
                    nameAr:
                        f['name_ar']?.toString() ?? f['name']?.toString() ?? '',
                    color: Color(
                      f['color'] is int ? f['color'] : _parseColor(f['color']),
                    ),
                    imageUrl: f['imageUrl']?.toString() ?? '',
                  ),
                )
                .toList()
          : null,
      score: map['score'] as int?,
    );
  }

  // Les méthodes statiques restent identiques...
  static List<String> _convertToList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value.map((e) => e.toString()));
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  static int _parseColor(dynamic colorValue) {
    if (colorValue is int) return colorValue;
    if (colorValue is String) {
      String hex = colorValue.startsWith('0x')
          ? colorValue.substring(2)
          : colorValue;
      hex = hex.startsWith('#') ? hex.substring(1) : hex;
      if (hex.length == 6) hex = 'ff$hex';
      try {
        return int.parse(hex, radix: 16);
      } catch (e) {
        return 0xFF000000;
      }
    }
    return 0xFF000000;
  }
}

class FlavorOption {
  final String name;
  final String nameEn;
  final String nameAr;
  final Color color;
  final String imageUrl;

  FlavorOption({
    required this.name,
    required this.nameEn,
    this.nameAr = "",
    required this.color,
    required this.imageUrl,
  });
}
