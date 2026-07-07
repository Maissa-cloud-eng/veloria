import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/auth_service.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/controllers/wishlist_controller.dart';
import 'package:veloria/presentation/pages/public/cart_page.dart';
import 'package:veloria/presentation/pages/public/profile_page.dart';
import 'package:veloria/presentation/pages/public/home_page.dart';
import 'package:veloria/presentation/pages/public/shop_page.dart';
import 'package:veloria/presentation/pages/public/wishlist_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/domain/entities/categories.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

bool shouldJumpToRatings = false;
// ================== Préchargements ==================
Map<String, dynamic>? preloadedUserData;
List<Product> preloadedProducts = [];
List<CategoryData> preloadedCategories = []; // À ajouter en haut du main.dart
List<String> preloadedCategoryNames = ["Tous"];
// Avant : Map<String, List<String>>
// Maintenant :
Map<String, List<SubCategoryData>> preloadedSubCategoriesMap = {};

Future<void> preloadUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  if (doc.exists) {
    final data = doc.data() ?? {};
    preloadedUserData = {
      'name': data['name'] ?? '',
      'email': data['email'] ?? '',
      'phone': data['phone'] ?? '',
      'addressLine': data['addressLine'] ?? '',
      'city': data['city'] ?? '',
      'postalCode': data['postalCode'] ?? '',
      'skinType': data['skinType'] ?? '',
      'hairTexture': data['hairTexture'] ?? '',
      'hairState': data['hairState'] ?? '',
      'selectedLanguage': data['selectedLanguage'] ?? 'Français',
      'orderHistory': List<Map<String, dynamic>>.from(
        data['orderHistory'] ?? [],
      ),
      'totalOrdersCount': data['totalOrdersCount'] ?? 0,
    };
  }
}

Future<void> preloadShopData() async {
  const String categoryIdToExclude = 'WbCiUVtZupXa5IXef2lI';

  try {
    final catSnapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where(FieldPath.documentId, isNotEqualTo: categoryIdToExclude)
        .orderBy('order', descending: false)
        .get();

    preloadedCategoryNames = ["Tous"];
    // Dans main.dart -> preloadShopData
    preloadedCategories = catSnapshot.docs
        .map((doc) => CategoryData.fromFirestore(doc))
        .toList();
    preloadedSubCategoriesMap = {}; // Reset de la map

    for (var doc in catSnapshot.docs) {
      final categoryData = CategoryData.fromFirestore(doc);

      // On utilise toujours categoryData.name (le Français) comme clé technique
      if (categoryData.name.isNotEmpty) {
        preloadedCategoryNames.add(categoryData.name);

        // Stockage de la liste d'objets SubCategoryData
        preloadedSubCategoriesMap[categoryData.name] =
            categoryData.subCategories;
      }
    }
    preloadedCategoryNames.add("Packs");
  } catch (e) {
    print("Erreur préchargement catégories: $e");
  }

  try {
    final prodSnapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isTemplate', isEqualTo: false)
        .get();

    preloadedProducts = prodSnapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .where(
          (p) =>
              p.title.isNotEmpty &&
              p.imageUrl.isNotEmpty &&
              p.price.isNotEmpty &&
              p.category.isNotEmpty,
        )
        .toList();
  } catch (e) {
    print("Erreur préchargement produits: $e");
  }
}

// ================== MAIN ==================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialisation des formats de date
    await initializeDateFormatting('fr_FR', null);
    await initializeDateFormatting('en_US', null);

    // 2. Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 3. Configuration des notifications (on ne bloque pas si ça échoue)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // 4. Authentification et Préchargement (C'est ici que ça bloquait !)
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      // On lance les préchargements
      await preloadUserData();
      await preloadShopData();
    } catch (e) {
      print('⚠️ Erreur lors de l\'initialisation des données : $e');
      // On continue quand même pour ne pas laisser l'écran noir
    }
  } catch (e) {
    print('❌ Erreur critique au démarrage : $e');
  }

  // 5. Lancement de l'application (Quoi qu'il arrive !)
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(
          create: (_) => WishlistController()..syncFromFirestore(),
        ),
        ChangeNotifierProvider(create: (_) => CartController()),
      ],
      child: const MyApp(),
    ),
  );
}

// ================== MyApp ==================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Veloria',
      theme: ThemeData(
        useMaterial3: true,
        // colorSchemeSeed génère automatiquement toutes les nuances
        // de rose pour les inputs, les loaders et les boutons.
        colorSchemeSeed: Colors.pink,
      ),

      // --- LA PROTECTION ULTIME S'INJECTE ICI ---
      builder: (context, child) {
        final language = context.watch<LanguageProvider>();

        return Directionality(
          textDirection: language.textDirection,
          child: Container(
            color: Colors
                .white, // Force les barres latérales de l'iPad en blanc pur
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth:
                      450, // Bloque TOUS les écrans (onglets, pages isolées, popups) à 450px max
                ),
                child: child,
              ),
            ),
          ),
        );
      },

      home: const MainWrapper(),
    );
  }
}

// ================== MainWrapper ==================
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => MainWrapperState();
}

class MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  String? _shopFilter;
  List<Widget> get _screens => [
    const HomeScreen(),
    ShopScreen(initialFilter: _shopFilter), // <--- ON PASSE LE FILTRE ICI
    const WishlistScreen(),
    const CartPage(),
    const ProfileScreen(),
  ];
  // --- AJOUTE CETTE MÉTHODE STATIQUE ---
  // Elle permettra d'appeler MainPage.jumpToShop(filter) de n'importe où
  static void jumpToShop(BuildContext context, String filter) {
    final state = context.findAncestorStateOfType<MainWrapperState>();
    if (state != null) {
      state.setState(() {
        state._shopFilter = filter;
        state._currentIndex = 1; // Index du Shop
      });
    }
  }

  // ---------------------------------------
  bool _popupAlreadyOpening = false;
  @override
  void initState() {
    super.initState();
    AuthService.signInAnonymouslyIfNeeded();
    // On attend que l'app soit prête pour injecter la langue préchargée
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (preloadedUserData != null &&
          preloadedUserData!['selectedLanguage'] != null) {
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).setLanguage(preloadedUserData!['selectedLanguage']);
      }
      _checkRatingPopup();
    });

    _syncCartWithController();

    // --- AJOUTE CE BLOC ICI ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRatingPopup();
    });
    // --------------------------
  }

  // --- LOGIQUE POPUP DE NOTATION ---
  Future<void> _checkRatingPopup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("🔍 Vérification du popup pour: ${user.uid}");

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return;

    final userData = userDoc.data()!;
    final bool alreadyShown = userData['ratingPopupShown'] ?? false;

    // DEBUG: Si tu veux forcer le test, commente la ligne ci-dessous
    if (alreadyShown) {
      print("ℹ️ Popup déjà montré auparavant.");
      return;
    }

    // On récupère les dernières commandes de l'utilisateur
    final orderQuery = await FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .get();

    print("📦 Nombre de commandes trouvées: ${orderQuery.docs.length}");

    bool hasDeliveredOrder = false;

    for (var doc in orderQuery.docs) {
      final status = (doc.data()['deliveryStatus'] ?? "")
          .toString()
          .toLowerCase()
          .trim();
      print("📝 Statut de la commande ${doc.id}: '$status'");

      if (status == "delivered" || status == "livré") {
        hasDeliveredOrder = true;
        break;
      }
    }

    if (hasDeliveredOrder && !_popupAlreadyOpening) {
      print("✅ Commande livrée trouvée ! Affichage du popup...");
      if (mounted) {
        _popupAlreadyOpening = true;
        _showRatingDialog(user.uid);
      }
    } else {
      print(
        "❌ Aucune commande livrée avec le statut exact 'delivered' ou 'livré'.",
      );
    }
  }

  void _showRatingDialog(String uid) {
    // On récupère la langue avant de construire le dialogue
    final bool isEn =
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).selectedLanguage ==
        'Anglais';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isEn ? "Your opinion matters ❤️" : "Ton avis compte ❤️",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.pink,
          ),
        ),
        content: Text(
          isEn
              ? "Your feedback is precious! Don't hesitate to rate your products to help us improve our recommendations."
              : "Ton avis nous est précieux ! N'hésites pas à noter tes produits pour nous aider à améliorer nos recommandations.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              isEn ? "Later" : "Plus tard",
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .update({'ratingPopupShown': true});

              if (mounted) {
                // ON UTILISE LA VARIABLE GLOBALE
                shouldJumpToRatings = true;

                setState(() {
                  _currentIndex = 4; // Index du profil
                });
                Navigator.pop(context);
              }
            },
            child: Text(
              isEn ? "Rate my products" : "Noter mes produits",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _syncCartWithController() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartController = Provider.of<CartController>(context, listen: false);

    FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          int totalItems = 0;

          if (snapshot.exists) {
            final data = snapshot.data();
            final String status = data?['status'] ?? '';
            final items = data?['items'] as List<dynamic>? ?? [];

            // Si la commande est passée (ordered), le panier doit être considéré comme vide
            if (status == 'ordered' || items.isEmpty) {
              totalItems = 0;
            } else {
              totalItems = items.fold<int>(
                0,
                (sum, item) => sum + (item['quantity'] as int? ?? 0),
              );
            }
          }

          // On met à jour le controller quoi qu'il arrive
          cartController.setCount(totalItems);
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- MODIFICATION ICI : On encadre le body pour l'iPad ---
      body: Container(
        color: Colors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450, // Largeur parfaite format smartphone
            ),
            child: _screens[_currentIndex],
          ),
        ),
      ),
      // --------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        // Dans main.dart, dans le BottomNavigationBar
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Si on clique sur un autre onglet que la Boutique,
            // on efface le filtre pour la prochaine fois
            if (index != 1) {
              _shopFilter = null;
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: context.t("nav.home"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: context.t("nav.shop"),
          ),
          BottomNavigationBarItem(
            icon: Consumer<WishlistController>(
              builder: (context, wishlistController, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.favorite),
                    if (wishlistController.items.isNotEmpty)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            wishlistController.items.length.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: context.t("nav.favorites"),
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartController>(
              builder: (context, cartController, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    if (cartController.count > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: Colors.red,
                          child: Text(
                            cartController.count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            label: context.t("nav.cart"),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: context.t("nav.profile"),
          ),
        ],
      ),
    );
  }
}
