import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriesAdminPage extends StatelessWidget {
  const CategoriesAdminPage({super.key});

  static const String collectionName = 'categories';

  static const Map<String, String> _categoryNameAr = {
    'brumes': 'البخاخات',
    'mists': 'البخاخات',
    'cheveux': 'العناية بالشعر',
    'hair care': 'العناية بالشعر',
    'maquillage': 'المكياج',
    'makeup': 'المكياج',
    'soins corps': 'العناية بالجسم',
    'body care': 'العناية بالجسم',
    'soins visage': 'العناية بالوجه',
    'face care': 'العناية بالوجه',
    'solaires': 'واقيات الشمس',
    'sun care': 'واقيات الشمس',
  };

  static const Map<String, String> _subCategoryNameAr = {
    'fruité': 'فاكهي',
    'fruity': 'فاكهي',
    'floral': 'زهري',
    'boisé': 'خشبي',
    'woody': 'خشبي',
    'sucré': 'حلو',
    'sweet': 'حلو',
    'masque': 'ماسك',
    'hair mask': 'ماسك للشعر',
    'mask': 'ماسك',
    'sérum/huile': 'سيروم/زيت',
    'serum/oil': 'سيروم/زيت',
    'protecteur de chaleur': 'واقي من الحرارة',
    'heat protectant': 'واقي من الحرارة',
    'shampooing': 'شامبو',
    'shampoo': 'شامبو',
    'après-shampooing': 'بلسم',
    'conditioner': 'بلسم',
    'soins sans rinçage': 'عناية بدون شطف',
    'no-rinse treatments': 'عناية بدون شطف',
    'coloration': 'صبغة شعر',
    'hair color': 'صبغة شعر',
    'poudre': 'بودرة',
    'powder': 'بودرة',
    'crayon à lèvres': 'قلم شفاه',
    'lip liners': 'قلم شفاه',
    'palettes': 'باليت',
    'fond de teint': 'كريم أساس',
    'fondation': 'كريم أساس',
    'foundation': 'كريم أساس',
    'mascara': 'ماسكارا',
    'anti-cernes': 'كونسيلر',
    'concealer': 'كونسيلر',
    'blush': 'بلاشر',
    'rouge à lèvres': 'أحمر شفاه',
    'lipstick': 'أحمر شفاه',
    'eyeliner': 'آيلاينر',
    'contour/bronzer': 'كونتور/برونزر',
    'highligher': 'هايلايتر',
    'highlighter': 'هايلايتر',
    'gloss': 'غلوس',
    'sourcils': 'الحواجب',
    'eyebrow': 'الحواجب',
    'base': 'برايمر',
    'primer': 'برايمر',
    'spray fixateur': 'بخاخ تثبيت',
    'fixer spray': 'بخاخ تثبيت',
    'encre à lèvres': 'تينت شفاه',
    'lip tint': 'تينت شفاه',
    'lait corporel': 'لوشن الجسم',
    'body lotion': 'لوشن الجسم',
    'gommage': 'مقشر',
    'scrub': 'مقشر',
    'huile': 'زيت للجسم',
    'body oil': 'زيت للجسم',
    'gel douche': 'جل استحمام',
    'shower gel': 'جل استحمام',
    'hygiène intime': 'العناية الحميمة',
    'intimate care': 'العناية الحميمة',
    'nettoyant': 'منظف',
    'cleanser': 'منظف',
    'crème': 'كريم',
    'cream': 'كريم',
    'sérum': 'سيروم',
    'serum': 'سيروم',
    'exfoliant': 'مقشر',
    'exfoliator': 'مقشر',
    'lotion': 'تونر',
    'toner': 'تونر',
    'baume à lèvres': 'مرطب شفاه',
    'lip balm': 'مرطب شفاه',
    'protection visage': 'حماية الوجه',
    'face protection': 'حماية الوجه',
    'protection corps': 'حماية الجسم',
    'body care': 'حماية الجسم',
    'après-solaire': 'بعد الشمس',
    'after-sun': 'بعد الشمس',
  };

  static String _translationKey(String value) {
    return value.toLowerCase().trim();
  }

  static String? _translationFor(
    Map<String, String> dictionary,
    Iterable<Object?> values,
  ) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text == null || text.isEmpty) continue;
      final translated = dictionary[_translationKey(text)];
      if (translated != null && translated.isNotEmpty) return translated;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Gestion Catégories (Trilingue)",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: "Remplir les traductions arabes",
            icon: const Icon(Icons.translate, color: Colors.white),
            onPressed: () => _fillArabicTranslations(context),
          ),
        ],
        backgroundColor: Colors.orange,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collectionName)
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs
              .where((doc) => doc.id != "WbCiUVtZupXa5IXef2lI")
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cat = docs[index];
              final data = cat.data() as Map<String, dynamic>;

              // Affichage bilingue dans la liste
              final String nameFr = data['name'] ?? cat.id;
              final String nameEn = data['name_en'] ?? "Sans nom EN";
              final String nameAr = data['name_ar'] ?? "Sans nom AR";
              final List subCats = data['subCategories'] ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 15),
                child: ExpansionTile(
                  leading: Icon(
                    IconData(
                      data['iconCodePoint'] ?? 58713,
                      fontFamily: 'MaterialIcons',
                    ),
                    color: Colors.orange,
                  ),
                  title: Text(
                    "$nameFr / $nameEn / $nameAr",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("ID: ${cat.id}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showCategoryDialog(context, doc: cat),
                  ),
                  children: [
                    const Divider(),
                    ...subCats.map((sub) {
                      String label = (sub is Map)
                          ? "${sub['name']} / ${sub['name_en']} / ${sub['name_ar'] ?? 'Sans nom AR'}"
                          : sub.toString();
                      return ListTile(
                        dense: true,
                        title: Text(label),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          onPressed: () => _deleteSubCategory(cat.id, sub),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () => _showSubCategoryDialog(context, cat.id),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text("Ajouter une sous-catégorie trilingue"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _fillArabicTranslations(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      int updatedCategories = 0;
      int updatedSubCategories = 0;

      for (final doc in snapshot.docs) {
        if (doc.id == "WbCiUVtZupXa5IXef2lI") continue;

        final data = doc.data();
        final Map<String, dynamic> updates = {};
        final existingNameAr = data['name_ar']?.toString().trim() ?? '';
        final categoryAr = _translationFor(_categoryNameAr, [
          data['name'],
          data['name_en'],
          doc.id,
        ]);

        if (existingNameAr.isEmpty && categoryAr != null) {
          updates['name_ar'] = categoryAr;
          updatedCategories++;
        }

        final rawSubCategories = data['subCategories'];
        if (rawSubCategories is List) {
          bool changed = false;
          final translatedSubCategories = rawSubCategories.map((subCategory) {
            if (subCategory is! Map) return subCategory;

            final subMap = Map<String, dynamic>.from(subCategory);
            final existingSubNameAr =
                subMap['name_ar']?.toString().trim() ?? '';

            if (existingSubNameAr.isNotEmpty) return subMap;

            final subCategoryAr = _translationFor(_subCategoryNameAr, [
              subMap['name'],
              subMap['name_en'],
            ]);

            if (subCategoryAr != null) {
              subMap['name_ar'] = subCategoryAr;
              changed = true;
              updatedSubCategories++;
            }

            return subMap;
          }).toList();

          if (changed) updates['subCategories'] = translatedSubCategories;
        }

        if (updates.isNotEmpty) batch.update(doc.reference, updates);
      }

      await batch.commit();

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            "Arabe rempli : $updatedCategories catégories, $updatedSubCategories sous-catégories.",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text("Erreur remplissage arabe : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- LE DIALOGUE QUI TE PERMET D'ENTRER LES 3 LANGUES ---
  Future<void> _showCategoryDialog(
    BuildContext context, {
    DocumentSnapshot? doc,
  }) async {
    final isEdit = doc != null;
    final data = isEdit ? doc.data() as Map<String, dynamic>? : null;

    // On prépare les chaînes de caractères de manière sécurisée
    final String initialId = isEdit ? doc.id : '';
    final String initialNameFr = isEdit
        ? (data?['name']?.toString() ?? doc.id)
        : '';
    final String initialNameEn = isEdit
        ? (data?['name_en']?.toString() ?? '')
        : '';
    final String initialNameAr = isEdit
        ? (data?['name_ar']?.toString() ?? '')
        : '';
    final String initialOrder = isEdit
        ? (data?['order']?.toString() ?? '0')
        : '0';

    // On initialise les contrôleurs avec des chaînes non-nulles
    final idController = TextEditingController(text: initialId);
    final nameFrController = TextEditingController(text: initialNameFr);
    final nameEnController = TextEditingController(text: initialNameEn);
    final nameArController = TextEditingController(text: initialNameAr);
    final orderController = TextEditingController(text: initialOrder);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? "Modifier" : "Ajouter"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEdit)
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: "ID technique"),
              ),
            TextField(
              controller: nameFrController,
              decoration: const InputDecoration(labelText: "Nom Français"),
            ),
            TextField(
              controller: nameEnController,
              decoration: const InputDecoration(labelText: "Nom Anglais"),
            ),
            TextField(
              controller: nameArController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: "Nom Arabe"),
            ),
            TextField(
              controller: orderController,
              decoration: const InputDecoration(labelText: "Ordre"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. On ferme immédiatement le dialogue
              Navigator.pop(context);

              // 2. On lance la sauvegarde en arrière-plan (sans await)
              FirebaseFirestore.instance
                  .collection(collectionName)
                  .doc(idController.text.trim())
                  .set({
                    'name': nameFrController.text.trim(),
                    'name_en': nameEnController.text.trim(),
                    'name_ar': nameArController.text.trim(),
                    'order': int.tryParse(orderController.text) ?? 0,
                  }, SetOptions(merge: true));
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  // --- AJOUT DE SOUS-CATÉGORIE TRILINGUE ---
  Future<void> _showSubCategoryDialog(
    BuildContext context,
    String catId,
  ) async {
    final frController = TextEditingController();
    final enController = TextEditingController();
    final arController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sous-catégorie"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frController,
              decoration: const InputDecoration(labelText: "Français"),
            ),
            TextField(
              controller: enController,
              decoration: const InputDecoration(labelText: "Anglais"),
            ),
            TextField(
              controller: arController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(labelText: "Arabe"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (frController.text.isNotEmpty &&
                  enController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection(collectionName)
                    .doc(catId)
                    .update({
                      'subCategories': FieldValue.arrayUnion([
                        {
                          'name': frController.text.trim(),
                          'name_en': enController.text.trim(),
                          'name_ar': arController.text.trim(),
                        },
                      ]),
                    });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubCategory(String catId, dynamic subData) async {
    await FirebaseFirestore.instance
        .collection(collectionName)
        .doc(catId)
        .update({
          'subCategories': FieldValue.arrayRemove([subData]),
        });
  }
}
