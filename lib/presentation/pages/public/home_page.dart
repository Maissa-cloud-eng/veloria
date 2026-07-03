import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';

import 'package:veloria/auth_service.dart';
import 'package:veloria/domain/entities/categories.dart';

import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/main.dart';

import 'package:veloria/presentation/pages/admin/admin_main_page.dart';

import 'package:veloria/presentation/pages/admin/analytics_helper.dart';
import 'package:veloria/presentation/pages/public/BeautyQuizPage.dart';

import 'package:veloria/presentation/states/language_provider.dart';
import 'package:veloria/presentation/widgets/NativeAutoPlayCarousel.dart';
import 'package:veloria/presentation/widgets/shake_btn.dart';

import 'shop_page.dart';
import 'package:device_info_plus/device_info_plus.dart'; // <--- AJOUTE ÇA

// ===========================================================

// CONSTANTES

// ===========================================================

const Color _kPrimaryPink = Colors.pink;

final Color _kLightPinkBackground = Colors.pink.shade50;

const String _kExcludedDocumentId = 'WbCiUVtZupXa5IXef2lI';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    _trackVisit();
  }

  @override
  void dispose() {
    logEvent('last_seen_home');

    super.dispose();
  }

  Future<void> _trackVisit() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      String? deviceId;

      // --- RÉCUPÉRATION DE L'ID UNIQUE DU TÉLÉPHONE ---
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id; // ID unique Android
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor; // ID unique iOS
      }

      await FirebaseFirestore.instance.collection('visits').add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid ?? "guest",
        'deviceId': deviceId ?? "unknown", // <--- LE VOICI !
        'platform': Platform.isAndroid ? "Android" : "iOS",
      });
    } catch (e) {
      debugPrint("Erreur tracking visite: $e");
    }
  }

  void _openShop(BuildContext context, String categoryId) {
    // 1. On cherche le document de la catégorie pour avoir son nom technique (FR)
    // car ton ShopScreen filtre sur le champ 'category' (en français dans ta base).
    final categoryDoc = preloadedCategories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => throw Exception("Catégorie non trouvée"),
    );

    // 2. On utilise la télécommande pour changer d'onglet
    // On passe categoryDoc.name car c'est le nom technique (ex: "Soins visage")
    MainWrapperState.jumpToShop(context, categoryDoc.name);
  }

  // Fonction Fallback si Firebase n'a pas d'image

  Widget _buildBannerFallback() {
    return Image.asset(
      "assets/banner.png",

      fit: BoxFit.cover,

      width: double.infinity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentLang = Provider.of<LanguageProvider>(
      context,
    ).selectedLanguage;
    final bool isEn = currentLang == "Anglais";
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ===== LOGO =====
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),

                  child: Image.asset(
                    "assets/logo.png",

                    height: 90,

                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ===== BOUTON ADMIN DASHBOARD =====
              FutureBuilder<bool>(
                future: AuthService.isAdmin(),

                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data == true) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,

                        vertical: 8,
                      ),

                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (_) => const AdminMainPage(),
                          ),
                        ),

                        child: Container(
                          padding: const EdgeInsets.all(12),

                          decoration: BoxDecoration(
                            color: _kPrimaryPink.withOpacity(0.1),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(color: _kPrimaryPink, width: 1),
                          ),

                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,

                            children: [
                              Icon(
                                Icons.admin_panel_settings,

                                color: _kPrimaryPink,
                              ),

                              SizedBox(width: 8),

                              Text(
                                "Accéder au Dashboard Admin",

                                style: TextStyle(
                                  color: _kPrimaryPink,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),

              // ===== BANNIÈRE DYNAMIQUE (CARROUSEL MULTILINGUE) =====
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('settings')
                    .doc('main_banner')
                    .snapshots(),
                builder: (context, snapshot) {
                  final languageProvider = Provider.of<LanguageProvider>(
                    context,
                  );
                  final bool isEn =
                      languageProvider.selectedLanguage == "Anglais";

                  List<String> bannerImages = [];

                  // 1. GESTION DU CHARGEMENT INITIAL (Le moment critique)
                  // Tant que Firestore n'a pas répondu au premier démarrage, on montre un squelette neutre
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      height:
                          230, // Même hauteur que ton carrousel final pour éviter un saut d'écran !
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100, // Fond gris neutre premium
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.pink,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  // 2. EXTRACTION DES DONNÉES (Une fois le chargement fini)
                  if (snapshot.hasData &&
                      snapshot.data != null &&
                      snapshot.data!.exists) {
                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final String languageKey = isEn ? 'images_en' : 'images_fr';

                    if (data[languageKey] != null) {
                      bannerImages = List<String>.from(data[languageKey]);
                    }
                  }

                  // 3. FALLBACK : Si la base est lue mais VRAIMENT vide (ex: pas d'Internet ou document supprimé)
                  if (bannerImages.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(16),
                      height: 160,
                      width: double.infinity,
                      child:
                          _buildBannerFallback(), // L'image de secours ne s'affiche qu'ICI en dernier recours
                    );
                  }

                  // 4. CARROUSEL FINAL (Quand tout est prêt)
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    height: 230,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: NativeAutoPlayCarousel(bannerImages: bannerImages),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Text(
                  isEn ? "Categories" : "Catégories",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== CATÉGORIES DYNAMIQUES =====
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('categories')
                        .orderBy('order', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final categoryDocs = snapshot.data!.docs
                          .where((doc) => doc.id != _kExcludedDocumentId)
                          .toList();

                      // On récupère la langue actuelle via le Provider
                      final String currentLang = Provider.of<LanguageProvider>(
                        context,
                      ).selectedLanguage;

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: categoryDocs.map((doc) {
                          // 1. On transforme le doc Firestore en notre objet CategoryData
                          final category = CategoryData.fromFirestore(doc);

                          // 2. On choisit le libellé selon la langue
                          // Si c'est "Anglais", on prend name_en, sinon name (Français)
                          final String displayLabel = (currentLang == "Anglais")
                              ? category.name_en
                              : category.name;

                          return _CategoryItem(
                            // On utilise l'icône définie dans l'objet
                            icon: category.iconData,
                            // On affiche le nom traduit
                            label: displayLabel,
                            // On garde l'ID technique (doc.id) pour filtrer le Shop
                            onTap: () => _openShop(context, doc.id),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // ... après le Wrap des catégories ...
              const SizedBox(height: 30),

              Center(
                child: ShakeButton(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (c) => BeautyQuizPage(mode: "routine"),
                      ),
                    );
                  },

                  child: Text(
                    isEn
                        ? "Create my beauty routine in 30s"
                        : "Créer ma routine beauté en 30 sec",

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,

                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              // ... avant _buildNewArrivalsSection(isEn) ...
              // ===== NOUVEAUTÉS =====
              _buildNewArrivalsSection(isEn),

              const SubmitProductButton(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewArrivalsSection(bool isEn) {
    return StreamBuilder<QuerySnapshot>(
      // CORRECTION : Ajout du tri par date (du plus récent au plus ancien)
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('isNewArrival', isEqualTo: true)
          .orderBy(
            'createdAt',
            descending: true,
          ) // Assure-toi que ce champ existe dans Firestore
          .snapshots(),

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Si tu as une erreur ici, c'est probablement qu'il faut créer un index dans Firestore
          // (Firebase te donnera un lien dans la console pour le faire en un clic)
          debugPrint("Erreur Firestore: ${snapshot.error}");
        }
        if (!snapshot.hasData) return const SizedBox.shrink();

        final newArrivals = snapshot.data!.docs
            .where((doc) => doc.id != _kExcludedDocumentId)
            .map((doc) => Product.fromFirestore(doc))
            .toList();

        if (newArrivals.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEn ? "✨ New Arrivals" : "✨ Nouveautés",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // AJOUT : Bouton "Voir tout"
                  TextButton(
                    onPressed: () {
                      // On utilise la "télécommande" qu'on a créée juste au-dessus
                      MainWrapperState.jumpToShop(context, 'new_arrivals');
                    },
                    child: Text(
                      isEn ? "See all" : "Voir tout",
                      style: const TextStyle(color: _kPrimaryPink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 360,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: newArrivals.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 170,
                      child: ProductCard(product: newArrivals[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

// ===========================================================

// WIDGETS SECONDAIRES

// ===========================================================

class _CategoryItem extends StatelessWidget {
  final IconData icon;

  final String label;

  final VoidCallback? onTap;

  const _CategoryItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: SizedBox(
        width: 90,

        child: Column(
          children: [
            Container(
              height: 65,

              width: 65,

              decoration: BoxDecoration(
                color: _kLightPinkBackground,

                shape: BoxShape.circle,
              ),

              child: Icon(icon, size: 30, color: _kPrimaryPink),
            ),

            const SizedBox(height: 6),

            Text(
              label,

              textAlign: TextAlign.center,

              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de soumission de produit (Inchangé mais conservé pour le bouton pulsant)

class SubmitProductButton extends StatefulWidget {
  const SubmitProductButton({super.key});

  @override
  State<SubmitProductButton> createState() => _SubmitProductButtonState();
}

class _SubmitProductButtonState extends State<SubmitProductButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 1.0,

      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _showBottomSheet(BuildContext context, bool isEn) {
    final nameController = TextEditingController();

    final brandController = TextEditingController();

    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),

      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,

            left: 20,

            right: 20,

            top: 15,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 40,

                height: 4,

                margin: const EdgeInsets.only(bottom: 20),

                decoration: BoxDecoration(
                  color: Colors.grey.shade300,

                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                isEn
                    ? "Can't find your product?"
                    : "Tu ne trouves pas ton produit ?",

                style: const TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                  color: _kPrimaryPink,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                isEn
                    ? "Suggest it to us and we'll add it for you"
                    : "Propose-le nous et nous l'ajouterons pour toi",

                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: nameController,

                decoration: InputDecoration(
                  hintText: isEn ? "Product name" : "Nom du produit",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: brandController,

                decoration: InputDecoration(
                  hintText: isEn ? "Brand" : "Marque",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              isSubmitting
                  ? const CircularProgressIndicator(color: _kPrimaryPink)
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryPink,

                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,

                          vertical: 14,
                        ),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),

                      onPressed: () async {
                        if (nameController.text.trim().isNotEmpty &&
                            brandController.text.trim().isNotEmpty) {
                          setModalState(() => isSubmitting = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection('product_submissions')
                                .add({
                                  'productName': nameController.text.trim(),

                                  'brandName': brandController.text.trim(),

                                  'submittedBy':
                                      FirebaseAuth.instance.currentUser?.uid ??
                                      'Anonyme',

                                  'status': 'pending',

                                  'createdAt': FieldValue.serverTimestamp(),
                                });

                            if (context.mounted) {
                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEn
                                        ? "Thank you! We'll let you know. ✨"
                                        : "Merci ! On vous préviendra. ✨",
                                  ),

                                  backgroundColor: _kPrimaryPink,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSubmitting = false);
                          }
                        }
                      },

                      child: Text(
                        isEn ? "Submit" : "Soumettre",

                        style: const TextStyle(
                          color: Colors.white,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn =
        Provider.of<LanguageProvider>(context).selectedLanguage == "Anglais";
    return Padding(
      padding: const EdgeInsets.only(bottom: 70),

      child: GestureDetector(
        onTap: () => _showBottomSheet(context, isEn),

        child: ScaleTransition(
          scale: _animation,

          child: Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(vertical: 16),

            margin: const EdgeInsets.symmetric(horizontal: 16),

            decoration: BoxDecoration(
              color: Colors.pink.shade100,

              borderRadius: BorderRadius.circular(16),
            ),

            child: Center(
              child: Text(
                isEn
                    ? "Can't find your product? Click here!"
                    : "Tu ne trouves pas ton produit ? Clique ici !",

                style: const TextStyle(
                  color: _kPrimaryPink,

                  fontWeight: FontWeight.bold,

                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
