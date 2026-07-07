import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerManagerPage extends StatefulWidget {
  const BannerManagerPage({super.key});

  @override
  State<BannerManagerPage> createState() => _BannerManagerPageState();
}

class _BannerManagerPageState extends State<BannerManagerPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Contrôleurs pour saisir les URLs d'images
  final TextEditingController _frController = TextEditingController();
  final TextEditingController _enController = TextEditingController();
  final TextEditingController _arController = TextEditingController();

  @override
  void dispose() {
    _frController.dispose();
    _enController.dispose();
    _arController.dispose();
    super.dispose();
  }

  // --- LOGIQUE FIRESTORE : AJOUTER UNE URL ---
  Future<void> _addBannerUrl(
    String langKey,
    TextEditingController controller,
  ) async {
    final String url = controller.text.trim();
    if (url.isEmpty) return;

    try {
      // FieldValue.arrayUnion permet d'ajouter l'élément dans la liste sans écraser le reste
      await _firestore.collection('settings').doc('main_banner').set({
        langKey: FieldValue.arrayUnion([url]),
      }, SetOptions(merge: true));

      controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bannière ajoutée avec succès ! 🎉")),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  // --- LOGIQUE FIRESTORE : SUPPRIMER UNE URL ---
  Future<void> _deleteBannerUrl(String langKey, String url) async {
    try {
      // FieldValue.arrayRemove supprime l'élément exact de la liste Firestore
      await _firestore.collection('settings').doc('main_banner').update({
        langKey: FieldValue.arrayRemove([url]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bannière supprimée ! 🗑️")),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  void _showErrorSnackBar(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur : ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Bannières (Veloria)"),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('settings')
            .doc('main_banner')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<String> frBanners = [];
          List<String> enBanners = [];
          List<String> arBanners = [];

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['images_fr'] != null)
              frBanners = List<String>.from(data['images_fr']);
            if (data['images_en'] != null)
              enBanners = List<String>.from(data['images_en']);
            if (data['images_ar'] != null)
              arBanners = List<String>.from(data['images_ar']);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= SECTION FRANÇAIS =================
                _buildLanguageSection(
                  title: "🇫🇷 Bannières - Français",
                  langKey: "images_fr",
                  controller: _frController,
                  currentUrls: frBanners,
                ),

                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // ================= SECTION ANGLAIS =================
                _buildLanguageSection(
                  title: "🇬🇧 Bannières - Anglais",
                  langKey: "images_en",
                  controller: _enController,
                  currentUrls: enBanners,
                ),

                const SizedBox(height: 32),
                const Divider(thickness: 2),
                const SizedBox(height: 16),

                // ================= SECTION ARABE =================
                _buildLanguageSection(
                  title: "🇩🇿 البانرات - العربية",
                  langKey: "images_ar",
                  controller: _arController,
                  currentUrls: arBanners,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET REUTILISABLE POUR CHAQUE LANGUE ---
  Widget _buildLanguageSection({
    required String title,
    required String langKey,
    required TextEditingController controller,
    required List<String> currentUrls,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Champ d'insertion de l'URL
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Coller l'URL de l'image ici...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _addBannerUrl(langKey, controller),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Liste des bannières actuelles avec prévisualisation
        if (currentUrls.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Aucune bannière pour le moment.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: currentUrls.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final url = currentUrls[index];
              return Stack(
                children: [
                  // L'image de la bannière
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bouton de suppression positionné en haut à droite de l'image
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.6),
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _deleteBannerUrl(langKey, url),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}
