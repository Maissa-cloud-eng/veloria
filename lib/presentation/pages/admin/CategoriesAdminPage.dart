import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CategoriesAdminPage extends StatelessWidget {
  const CategoriesAdminPage({super.key});

  static const String collectionName = 'categories';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Gestion Catégories (Bilingue)",
          style: TextStyle(color: Colors.white),
        ),
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
                    "$nameFr / $nameEn",
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
                          ? "${sub['name']} / ${sub['name_en']}"
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
                      label: const Text("Ajouter une sous-catégorie bilingue"),
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

  // --- LE DIALOGUE QUI TE PERMET D'ENTRER LES 2 LANGUES ---
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
    final String initialOrder = isEdit
        ? (data?['order']?.toString() ?? '0')
        : '0';

    // On initialise les contrôleurs avec des chaînes non-nulles
    final idController = TextEditingController(text: initialId);
    final nameFrController = TextEditingController(text: initialNameFr);
    final nameEnController = TextEditingController(text: initialNameEn);
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
                    'order': int.tryParse(orderController.text) ?? 0,
                  }, SetOptions(merge: true));
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  // --- AJOUT DE SOUS-CATÉGORIE BILINGUE ---
  Future<void> _showSubCategoryDialog(
    BuildContext context,
    String catId,
  ) async {
    final frController = TextEditingController();
    final enController = TextEditingController();

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
                        },
                      ]),
                    });
                Navigator.pop(context);
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
