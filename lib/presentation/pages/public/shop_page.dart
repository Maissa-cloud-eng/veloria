import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:veloria/domain/entities/categories.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/pages/admin/analytics_helper.dart';
import 'package:veloria/presentation/pages/public/cart_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import '../../../main.dart';
import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/presentation/pages/public/product_page.dart';

// ===========================================================
// CONSTANTES DE COULEUR
// ===========================================================
const Color _kPrimaryPink = Colors.pink;
final Color _kLightPinkBackground = Colors.pink.shade50;
const Color _kActiveText = Colors.white;
const Color _kPassivText = Colors.black;
const Color _kPearlGrey = Color(0xFFDCDCDC);

class ShopScreen extends StatefulWidget {
  final String? initialFilter;
  const ShopScreen({super.key, this.initialFilter});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasLoggedScroll = false;
  String selectedCategory = "Tous";
  String? selectedSubCategory;
  String selectedOrigin = "Tous";
  bool isForYouEnabled = false; // Nouveau mode de filtrage
  String selectedSort = "none"; // Peut être "none", "asc", ou "desc"
  String? selectedMakeupSection; // Peut être null, "Teint", "Yeux", ou "Lèvres"

  String? userSkinType;
  String? userHairTexture;
  String? userHairState;

  final Map<String, List<String>> makeupSections = {
    "Teint": [
      "Fond de teint",
      "Anti-cernes",
      "Poudre",
      "Blush",
      "Highlighter",
      "Base",
      "Spray Fixateur",
    ],
    "Yeux": ["Mascara", "Eyeliner", "Palettes", "Sourcils"],
    "Lèvres": ["Rouge à lèvres", "Gloss", "Crayon à lèvres", "Encre à lèvres"],
  };

  TextEditingController searchController = TextEditingController();
  bool isSearching = false;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (widget.initialFilter != null) selectedCategory = widget.initialFilter!;

    if (widget.initialFilter != null) {
      if (widget.initialFilter == 'new_arrivals') {
        selectedCategory =
            "Nouveautés"; // On force le nom lisible pour "allumer" le bouton
      } else {
        selectedCategory = widget.initialFilter!;
      }
    }

    userSkinType = preloadedUserData?['skinType'];
    userHairTexture = preloadedUserData?['hairTexture'];
    userHairState = preloadedUserData?['hairState'];

    searchController.addListener(
      () => setState(() => searchQuery = searchController.text),
    );

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _fetchUserPreferences(user.uid);
    });
  }

  @override
  void didUpdateWidget(ShopScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si le filtre change (ex: passage de null à 'new_arrivals')
    if (widget.initialFilter != oldWidget.initialFilter &&
        widget.initialFilter != null) {
      setState(() {
        if (widget.initialFilter == 'new_arrivals') {
          selectedCategory = "Nouveautés";
        } else {
          selectedCategory = widget.initialFilter!;
        }
        // On remet à zéro les autres filtres pour que l'affichage soit propre
        selectedSubCategory = null;
        searchQuery = '';
        searchController.clear();
      });
    }
  }

  void _onScroll() {
    // Si elles scrollent plus de 40% de la page, on considère qu'elles explorent
    if (_scrollController.position.pixels >
            (_scrollController.position.maxScrollExtent * 0.4) &&
        !_hasLoggedScroll) {
      logEvent('shop_scroll_deep');
      _hasLoggedScroll =
          true; // On ne le fait qu'une fois par session pour ne pas spammer Firestore
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    logEvent('last_seen_shop');
    super.dispose();
  }

  Future<void> _fetchUserPreferences(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        userSkinType = data?['skinType']?.toString();
        userHairTexture = data?['hairTexture']?.toString();
        userHairState = data?['hairState']?.toString();
      });
    }
  }

  Stream<List<Product>> getProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Product.fromFirestore(doc))
              .where(
                (p) =>
                    p.title.isNotEmpty &&
                    p.imageUrl.isNotEmpty &&
                    p.price.isNotEmpty &&
                    p.category.isNotEmpty,
              )
              .toList(),
        );
  }

  void _handleSearchToggle() {
    setState(() {
      isSearching = !isSearching;
      if (!isSearching) searchController.clear();
    });
  }

  void _showBasicsGuide(BuildContext context, String categoryTechName) {
    // 1. On récupère la langue actuelle
    final String lang = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).selectedLanguage;
    final bool isEn = lang == "Anglais";

    // 2. On trouve l'objet CategoryData complet (celui qui contient le guide)
    // On utilise techName car c'est la clé (ex: "Soins visage")
    final categoryData = preloadedCategories.firstWhere(
      (c) => c.name == categoryTechName,
      orElse: () => throw Exception("Catégorie non trouvée"),
    );

    final guide = categoryData.guide;

    // Si aucun guide n'est rempli dans Firestore pour cette catégorie, on ne fait rien
    if (guide == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TITRE TRADUIT
              Text(
                isEn ? categoryData.name_en : categoryData.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryPink,
                ),
              ),

              // INTRO TRADUITE
              if ((isEn ? guide.intro_en : guide.intro).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  isEn ? guide.intro_en : guide.intro,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],

              const Divider(height: 32),

              // --- ÉTAPES (STEPS) DYNAMIQUES ---
              ...guide.steps.map((step) {
                final String sTitle = isEn ? step.title_en : step.title;
                final String sDesc = isEn ? step.desc_en : step.desc;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: _kPrimaryPink,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              height: 1.4,
                            ),
                            children: [
                              TextSpan(
                                text: "$sTitle : ",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: sDesc),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // --- OPTIONNEL DYNAMIQUE ---
              if (guide.optional.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  isEn ? "➕ Optional:" : "➕ Optionnel :",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[300],
                  ),
                ),
                const SizedBox(height: 8),
                ...guide.optional.map((opt) {
                  final String oTitle = isEn ? opt.title_en : opt.title;
                  final String oDesc = isEn ? opt.desc_en : opt.desc;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: "• $oTitle",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (oDesc.isNotEmpty) TextSpan(text: " : $oDesc"),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              // --- MINI-FACTS DYNAMIQUES ---
              if ((isEn ? guide.facts_en : guide.facts).isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isEn
                        ? "💡 Mini-facts: ${guide.facts_en}"
                        : "💡 Mini-facts : ${guide.facts}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: _kPrimaryPink,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. On récupère la vraie largeur de l'écran
    double largeurEcran = MediaQuery.of(context).size.width;

    // 2. L'ASTUCE : Si l'écran dépasse 450px (comme sur iPad), on bloque le calcul à 450 !
    if (largeurEcran > 450) {
      largeurEcran = 450;
    }

    // 3. Tes calculs magiques restent exactement les mêmes !
    double largeurColonne = (largeurEcran - 48) / 2;
    double hauteurFixeTexte =
        190; // Garde tes 190 ou baisse à 160-170 si tu trouves la carte trop longue
    double hauteurTotaleCarte = largeurColonne + hauteurFixeTexte;
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: isSearching
            ? _buildSearchField()
            : Text(
                isEn ? "Shop" : "Boutique",
                style: const TextStyle(color: _kActiveText),
              ),
        backgroundColor: _kPrimaryPink,
        actions: [
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: _kActiveText,
            ),
            onPressed: _handleSearchToggle,
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: getProductsStream(),
        initialData: preloadedProducts,
        builder: (context, prodSnapshot) {
          if (!prodSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allProducts = prodSnapshot.data!;
          final filteredProducts = _applyFilters(allProducts);
          return _buildMainScrollArea(
            filteredProducts,
            allProducts,
            hauteurTotaleCarte,
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _kLightPinkBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: isEn ? "Search..." : "Rechercher...",
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildMakeupSectionBar() {
    if (selectedCategory != "Maquillage") return const SizedBox.shrink();

    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";

    // Liste des sections intermédiaires
    final List<String> sections = ["Teint", "Yeux", "Lèvres"];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            final isSel = selectedMakeupSection == section;

            // Traductions simples
            String displayLabel = section;
            if (isEn) {
              if (section == "Teint") displayLabel = "Face";
              if (section == "Yeux") displayLabel = "Eyes";
              if (section == "Lèvres") displayLabel = "Lips";
            }

            return GestureDetector(
              onTap: () => setState(() {
                // Si on reclique sur le même, on désactive le filtre intermédiaire
                selectedMakeupSection = isSel ? null : section;
                // On réinitialise la sous-catégorie précise à chaque changement de section
                selectedSubCategory = null;
              }),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? _kPrimaryPink.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? _kPrimaryPink : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayLabel,
                    style: TextStyle(
                      color: isSel ? _kPrimaryPink : Colors.black87,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEducationalHeader() {
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";

    // 1. On cherche la catégorie sélectionnée pour voir si elle a un guide
    CategoryData? currentCat;
    try {
      currentCat = preloadedCategories.firstWhere(
        (c) => c.name == selectedCategory,
      );
    } catch (e) {
      return const SizedBox.shrink();
    }

    // 2. Si la catégorie n'a pas de guide sur Firestore, on n'affiche rien
    if (currentCat.guide == null) {
      return const SizedBox.shrink();
    }

    // 3. LOGIQUE DE TRADUCTION "EN DUR" DES PHRASES D'ACCROCHE
    String question = "";
    String linkText = "";

    // On traduit la question selon la catégorie et la langue
    switch (selectedCategory) {
      case "Soins visage":
        question = isEn
            ? "Don't know the steps of a face routine?"
            : "Tu ne connais pas les étapes d’une routine visage ?";
        break;
      case "Maquillage":
        question = isEn
            ? "Don't know how to create an easy makeup look?"
            : "Tu ne sais pas comment composer un maquillage facile ?";
        break;
      case "Soins corps":
        question = isEn
            ? "Don't know where to start for your body care?"
            : "Tu ne sais pas par quoi commencer pour ton corps ?";
        break;
      case "Cheveux":
        question = isEn
            ? "Don't know the steps for your hair routine?"
            : "Tu ne connais pas les étapes pour tes cheveux ?";
        break;
      default:
        // Phrase générique pour les nouvelles catégories ajoutées sur Firestore
        question = isEn
            ? "Want to learn the basics for this category?"
            : "Tu veux apprendre les bases pour cette catégorie ?";
    }

    // Traduction du bouton
    linkText = isEn ? "Discover the basics" : "Découvrir les bases";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          InkWell(
            onTap: () => _showBasicsGuide(context, selectedCategory),
            child: Text(
              linkText,
              style: const TextStyle(
                fontSize: 13,
                color: _kPrimaryPink,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainScrollArea(
    List<Product> products,
    List<Product> rawProducts,
    double hauteurTotaleCarte,
  ) {
    // --- ON RÉCUPÈRE LA LANGUE ICI ---
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildCategoryBar(rawProducts)),
        SliverToBoxAdapter(child: _buildMakeupSectionBar()),
        SliverToBoxAdapter(child: _buildSubCategoryBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 10)),
        SliverToBoxAdapter(child: _buildOriginFilter()),
        SliverToBoxAdapter(child: _buildEducationalHeader()),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        if (products.isEmpty)
          SliverFillRemaining(
            // On retire le "const" ici car isEn est dynamique
            child: Center(
              // Ajoute un Center pour que ce soit joli
              child: Text(
                isEn ? "No products available." : "Aucun produit disponible.",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: hauteurTotaleCarte,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ProductCard(product: products[i]),
                childCount: products.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildCategoryBar(List<Product> allProducts) {
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;

    List<String> categories = List<String>.from(preloadedCategoryNames);
    categories.remove("Packs");

    if (!categories.contains("Nouveautés")) {
      int indexToInsert = categories.contains("Tous")
          ? categories.indexOf("Tous") + 1
          : 0;
      categories.insert(indexToInsert, "Nouveautés");
    }

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final String techName = categories[index];
          final isSel = techName == selectedCategory;

          String displayLabel = techName;

          if (lang == "Anglais") {
            if (techName == "Tous") {
              displayLabel = "All";
            } else if (techName == "Nouveautés") {
              // 🌟 INTERCEPTION ICI : On traduit le bouton virtuel manuellement
              displayLabel = "New Arrivals";
            } else {
              // Pour les vraies catégories de Firestore, on cherche l'objet traduit
              try {
                final catObj = preloadedCategories.firstWhere(
                  (c) => c.name == techName,
                );
                displayLabel = catObj.name_en;
              } catch (e) {
                displayLabel = techName;
              }
            }
          }

          return GestureDetector(
            onTap: () => setState(() {
              selectedCategory =
                  techName; // Stocke bien "Nouveautés" en FR pour tes filtres
              selectedSubCategory = null;
              selectedMakeupSection = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 10, top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? _kPrimaryPink : _kLightPinkBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  displayLabel, // Affiche "New Arrivals" proprement !
                  style: TextStyle(
                    color: isSel ? _kActiveText : _kPrimaryPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Product> _applyFilters(List<Product> all) {
    List<Product> filtered = all;

    // 1. FILTRE DE CATÉGORIE (Navigation principale)
    // On ne traite plus "Pour toi" comme une catégorie, mais comme un filtre global
    if (selectedCategory == "Nouveautés" ||
        selectedCategory == "new_arrivals") {
      filtered = filtered.where((p) => p.isNewArrival).toList();
      filtered.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      filtered = filtered.take(12).toList();
    } else if (selectedCategory != "Tous" && selectedCategory != "Pour toi") {
      filtered = filtered.where((p) => p.category == selectedCategory).toList();
    }

    // 2. LOGIQUE GLOBALE "POUR TOI" (Si le bouton est enclenché)
    // Ce bloc s'applique par-dessus la catégorie sélectionnée
    // 2. LOGIQUE GLOBALE "POUR TOI" (Si le bouton est enclenché)
    if (isForYouEnabled) {
      filtered = filtered.where((p) {
        // Nettoyage des tags
        List<String> tags = [];
        final dynamic rawTags = p.tags;
        if (rawTags is List) {
          tags = rawTags.map((t) => t.toString().toLowerCase().trim()).toList();
        } else if (rawTags is String) {
          tags = rawTags.toLowerCase().split(',').map((e) => e.trim()).toList();
        }

        // --- LOGIQUE D'INCLUSION ---

        // A. Est-ce un produit universel ou sans tags ?
        // On l'affiche s'il contient "tout_type", s'il est vide, ou s'il n'a aucun tag de diagnostic
        bool isUniversal =
            tags.contains("tout_type") ||
            tags.contains("tous types") ||
            tags.isEmpty;

        // B. Match PEAU
        bool skinMatch =
            (userSkinType != null &&
            tags.contains(userSkinType!.toLowerCase()));

        // C. Match CHEVEUX (Texture + État)
        bool hairMatch = false;
        if (userHairTexture != null && userHairState != null) {
          bool hasTexture = tags.contains(userHairTexture!.toLowerCase());
          bool hasState = tags.contains(userHairState!.toLowerCase());
          hairMatch = hasTexture && hasState;
        }

        // D. SÉCURITÉ : Si le produit a des tags mais aucun qui ne concerne la peau ou les cheveux
        // On définit ici la liste de tes tags "critiques" (ceux qui servent au filtrage)
        const specificTags = [
          "sèche",
          "grasse",
          "mixte",
          "normale",
          "lisses",
          "ondulés",
          "bouclés",
          "frisés",
          "crépus",
          "secs",
          "gras",
          "abîmés",
          "colorés",
          "fins",
        ];

        // Si le produit n'a AUCUN des tags spécifiques ci-dessus, on l'affiche par défaut
        bool hasNoSpecificRestriction = !tags.any(
          (t) => specificTags.contains(t),
        );

        // Le produit est gardé s'il est universel, s'il match, ou s'il n'a pas de restriction
        return isUniversal ||
            skinMatch ||
            hairMatch ||
            hasNoSpecificRestriction;
      }).toList();
    }
    // --- NOUVEAU : Filtrage par Section Intermédiaire Maquillage ---
    if (selectedCategory == "Maquillage" &&
        selectedMakeupSection != null &&
        (selectedSubCategory == null || selectedSubCategory!.isEmpty)) {
      final List<String> allowedSubs =
          makeupSections[selectedMakeupSection!] ?? [];
      // On ne garde que les produits dont la sous-catégorie appartient à la section sélectionnée (Teint, Yeux, Lèvres)
      filtered = filtered
          .where((p) => allowedSubs.contains(p.subCategory))
          .toList();
    }
    // 3. FILTRES SECONDAIRES (Sous-catégorie, Origine, Recherche)
    if (selectedSubCategory != null && selectedSubCategory!.isNotEmpty) {
      filtered = filtered
          .where((p) => p.subCategory == selectedSubCategory)
          .toList();
    }

    if (selectedOrigin != "Tous") {
      filtered = filtered.where((p) => p.origin == selectedOrigin).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    }

    // 4. ALGO DE TRI ALÉATOIRE STABILISÉ
    if (selectedCategory != "Nouveautés" &&
        selectedCategory != "new_arrivals" &&
        searchQuery.isEmpty) {
      int sessionSeed =
          DateTime.now().day + DateTime.now().month + DateTime.now().year;
      filtered.shuffle(Random(sessionSeed));
    }
    // --- LOGIQUE DE TRI PAR PRIX ---
    if (selectedSort == "asc") {
      filtered.sort(
        (a, b) => double.parse(a.price).compareTo(double.parse(b.price)),
      );
    } else if (selectedSort == "desc") {
      filtered.sort(
        (a, b) => double.parse(b.price).compareTo(double.parse(a.price)),
      );
    } else if (selectedSort == "none" && searchQuery.isEmpty) {
      // On remet le shuffle stabilisé si aucun tri n'est sélectionné
      int sessionSeed =
          DateTime.now().day + DateTime.now().month + DateTime.now().year;
      filtered.shuffle(Random(sessionSeed));
    }

    return filtered;
  }

  Widget _buildOriginFilter() {
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";

    bool hasProfile =
        (userSkinType != null && userSkinType!.isNotEmpty) ||
        (userHairTexture != null && userHairTexture!.isNotEmpty);

    return SizedBox(
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // --- 1. TES BOUTONS ORIGINE (REMIS COMME AVANT) ---
              ToggleButtons(
                constraints: const BoxConstraints(minHeight: 39.0),
                borderRadius: BorderRadius.circular(16),
                selectedColor: _kPassivText,
                fillColor: _kPearlGrey,
                color: _kPrimaryPink,
                isSelected: [
                  selectedOrigin == "Tous",
                  selectedOrigin == "Local",
                  selectedOrigin == "Importation",
                ],
                onPressed: (index) {
                  setState(() {
                    if (index == 0) selectedOrigin = "Tous";
                    if (index == 1) selectedOrigin = "Local";
                    if (index == 2) selectedOrigin = "Importation";
                  });
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(isEn ? "All" : "Tous"),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text("🇩🇿Local"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(isEn ? "🌍Imported" : "🌍Import"),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // --- 2. BOUTON POUR TOI (NOUVEAU DESIGN) ---
              GestureDetector(
                // Dans le GestureDetector du bouton POUR TOI
                onTap: () {
                  if (hasProfile) {
                    // CAS 1 : L'utilisateur a un profil -> On active/désactive le filtre
                    setState(() {
                      isForYouEnabled = !isForYouEnabled;
                      if (isForYouEnabled) {
                        logEvent('for_you_click');
                      }
                    });
                  } else {
                    // CAS 2 : Pas de profil -> On explique pourquoi ça ne marche pas
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEn
                              ? "Complete your beauty profile in the account tab to unlock personalization! ✨"
                              : "Complète ton profil beauté dans l'onglet compte pour débloquer la personnalisation ! ✨",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: _kPrimaryPink,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior
                            .floating, // Pour un look plus moderne
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 39, // Aligné sur la hauteur des ToggleButtons
                  width: 120,
                  decoration: BoxDecoration(
                    gradient: isForYouEnabled
                        ? const LinearGradient(
                            colors: [Colors.pink, Color(0xFFFF80AB)],
                          )
                        : null,
                    color: isForYouEnabled
                        ? null
                        : (hasProfile ? Colors.white : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasProfile ? _kPrimaryPink : Colors.transparent,
                      width: 1,
                    ),
                    boxShadow: isForYouEnabled
                        ? [
                            BoxShadow(
                              color: _kPrimaryPink.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: isForYouEnabled
                            ? Colors.white
                            : (hasProfile ? _kPrimaryPink : Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isEn ? "FOR YOU" : "POUR TOI",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isForYouEnabled
                              ? Colors.white
                              : (hasProfile ? _kPrimaryPink : Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. L'ENTONNOIR DE TRI ---
              _buildSortButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    // On récupère la langue actuelle depuis le Provider
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;
    final bool isEn = lang == "Anglais";

    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // On garde ton design d'icône (ajuste le container/padding si tu veux le rendre encore plus petit)
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _kPearlGrey),
        ),
        child: const Icon(Icons.filter_list, color: Colors.black87, size: 15),
      ),
      onSelected: (value) => setState(() => selectedSort = value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "none",
          child: Text(isEn ? "Default" : "Par défaut"),
        ),
        PopupMenuItem(
          value: "asc",
          child: Text(isEn ? "Price: Low to High" : "Prix croissant"),
        ),
        PopupMenuItem(
          value: "desc",
          child: Text(isEn ? "Price: High to Low" : "Prix décroissant"),
        ),
      ],
    );
  }

  Widget _buildSubCategoryBar() {
    if (!preloadedSubCategoriesMap.containsKey(selectedCategory)) {
      return const SizedBox.shrink();
    }

    // 1. On récupère la liste d'objets SubCategoryData
    List<SubCategoryData> subs = preloadedSubCategoriesMap[selectedCategory]!;

    // 2. SI on est dans le maquillage ET qu'une section intermédiaire est sélectionnée :
    if (selectedCategory == "Maquillage" && selectedMakeupSection != null) {
      final List<String> allowedSubs =
          makeupSections[selectedMakeupSection!] ?? [];
      // On filtre toujours sur la valeur technique en FR (subObj.name)
      subs = subs.where((subObj) => allowedSubs.contains(subObj.name)).toList();
    }

    // 3. On récupère la langue actuelle
    final String lang = Provider.of<LanguageProvider>(context).selectedLanguage;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final subObj = subs[index];

            // 4. LOGIQUE D'AFFICHAGE UNIQUEMENT : On traduit pour les yeux de l'utilisateur
            final String displayName = (lang == "Anglais")
                ? subObj.name_en
                : subObj.name;

            // 5. COMPARAISON SÉCURISÉE : On compare TOUJOURS avec la valeur technique en FR (subObj.name)
            final isSel = subObj.name == selectedSubCategory;

            return GestureDetector(
              // 6. ACTION : On stocke TOUJOURS la valeur en Français pour Firebase !
              onTap: () => setState(() => selectedSubCategory = subObj.name),
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSel
                      ? _kPrimaryPink.withOpacity(0.8)
                      : _kLightPinkBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    displayName, // On affiche le nom traduit (anglais ou français)
                    style: TextStyle(
                      color: isSel ? _kActiveText : _kPrimaryPink,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  // 🌟 Le dictionnaire magique pour l'affichage en Anglais
  static const Map<String, String> tagTranslationsEn = {
    "secs": "Dry",
    "sèche": "Dry",
    "normaux": "Normal",
    "normale": "Normal",
    "gras": "Oily",
    "grasse": "Oily",
    "mixte": "Mixed",
    "abîmés": "Damaged",
    "colorés": "Colored",
    "fins": "Fine",
    "tout_type": "All Types",
    "tous types": "All Types",
    "tous types ": "All Types",
  };
  List<String> getDisplayTagsList(dynamic rawTags) {
    // 1. Conversion du format Cloudinary (List ou String) vers List<String>
    List<String> allTags = [];
    if (rawTags is List) {
      allTags = rawTags.map((t) => t.toString().trim().toLowerCase()).toList();
    } else if (rawTags is String) {
      allTags = rawTags.split(',').map((e) => e.trim().toLowerCase()).toList();
    }

    if (allTags.isEmpty) return [];

    // 2. RÈGLE PRIORITAIRE : Si "fins" est présent, on ignore tout le reste
    if (allTags.contains("fins")) {
      return ["fins"];
    }

    // 3. TES LISTES DE RÉFÉRENCE (FILTRE STRICT)
    const states = [
      "secs",
      "normaux",
      "gras",
      "abîmés",
      "colorés",
      "tout_type",
      "fins",
    ];
    const skin = ["normale", "sèche", "grasse", "mixte", "tous types"];

    List<String> results = [];

    // 4. ON NE GARDE QUE LES TAGS QUI SONT DANS TES LISTES
    for (var tag in allTags) {
      if (states.contains(tag) || skin.contains(tag)) {
        // --- LOGIQUE D'EXCLUSION ---
        // Si le tag est "tout_type" MAIS qu'on a déjà "abîmés" dans la liste, on ignore le "tout_type"
        if (tag == "tout_type" && results.contains("abîmés")) {
          continue;
        }

        // Si le tag est "abîmés" MAIS qu'on a déjà "tout_type" dans la liste, on enlève le "tout_type"
        if (tag == "abîmés" && results.contains("Tous Types")) {
          results.remove("Tous Types");
        }
        // ---------------------------

        // Transformation visuelle pour "tout_type"
        String finalName = (tag == "tout_type") ? "Tous Types" : tag;

        // On évite les doublons au cas où
        if (!results.contains(finalName)) {
          results.add(finalName);
        }
      }
    }

    // 5. ON RETOURNE LES 3 PREMIERS MAXIMUM
    return results.take(3).toList();
  }

  Color getTagColor(String tag) {
    final t = tag.toLowerCase().trim();

    // --- ÉTATS SPÉCIFIQUES ---

    if (t == "abîmés") {
      // Un corail/rouge doux mais saturé, bien visible
      return const Color(0xFFFFCDD2);
    }
    if (t == "secs" || t == "sec") {
      return const Color(0xFFE3F2FD); // Bleu ciel (eau/souplesse)
    }
    if (t == "colorés") {
      return const Color(0xFFE1BEE7); // Violet
    }
    if (t == "gras" || t == "grasse") {
      return const Color(0xFFC8E6C9); // Vert
    }
    if (t == "sèche") {
      return const Color(0xFFFFECB3); // Ambre/Jaune
    }
    if (t == "mixte") {
      return const Color(0xFFE0F2F1); // Turquoise (Zone T)
    }

    // --- TYPES UNIVERSELS (Gris neutre propre) ---
    if (t == "normaux" ||
        t == "normale" ||
        t == "tout_type" ||
        t == "tous types") {
      return const Color(0xFFF5F5F5); // Gris clair élégant
    }

    return const Color(0xFFF5F5F5);
  }

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // ON UTILISE LE PROVIDER AU LIEU DU LOCALE SYSTÈME
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.selectedLanguage == "Anglais";

    // Sélection dynamique des textes
    final String displayTitle = isEn ? product.titleEn : product.title;
    final String displayBadge = isEn
        ? (product.customBadgeEn ?? '')
        : (product.customBadge ?? '');

    final String buyLabel = isEn ? "Buy" : "Acheter";
    final String addedToCartMsg = isEn ? "added to cart" : "ajouté au panier";
    final String loginNeededMsg = isEn
        ? "Please login to add to cart"
        : "Connectez-vous pour ajouter au panier";

    final bool isOutOfStock = product.isOutOfStock;

    return GestureDetector(
      onTap: () {
        logEvent('product_view');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(product: product)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: _kLightPinkBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: product.imageUrl.startsWith('http')
                            ? Image.network(product.imageUrl, fit: BoxFit.cover)
                            : Image.asset(product.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
                // Affichage du Badge EN ou FR
                if (displayBadge.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        displayBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TITRE ---
                  SizedBox(
                    height: 45,
                    child: Text(
                      displayTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // --- MARQUE ---
                  if (product.brand != null && product.brand!.isNotEmpty)
                    Text(
                      product.brand!,
                      maxLines: 1, // On force le texte sur une seule ligne
                      overflow: TextOverflow
                          .ellipsis, // On ajoute les "..." si ça dépasse
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                  const SizedBox(height: 5), // Un peu d'espace avant le badge
                  // --- BLOC BADGES DYNAMIQUES ---
                  SizedBox(
                    height: 19,
                    child: Builder(
                      builder: (context) {
                        // 1. Récupération de la liste technique brute (en FR : ["secs", "grasse"...])
                        final displayTags = getDisplayTagsList(product.tags);

                        if (displayTags.isEmpty) return const SizedBox.shrink();

                        // 2. On récupère la langue actuelle de l'application Veloria
                        final String lang = Provider.of<LanguageProvider>(
                          context,
                        ).selectedLanguage;
                        final bool isEn = (lang == "Anglais");

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayTags.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 4),
                          itemBuilder: (context, index) {
                            final tagFr =
                                displayTags[index]; // La valeur brute reste en FR pour la couleur

                            // 3. Traduction pour l'affichage uniquement
                            String labelAffiche = tagFr;
                            if (isEn) {
                              // On utilise le dictionnaire statique qu'on a défini à l'étape précédente
                              labelAffiche =
                                  ProductCard.tagTranslationsEn[tagFr
                                      .toLowerCase()
                                      .trim()] ??
                                  tagFr;
                            } else {
                              // En français, on gère proprement l'affichage de "tout_type"
                              if (tagFr == "tout_type")
                                labelAffiche = "Tous Types";
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                // 4. On passe toujours la valeur FR d'origine à getTagColor pour garder les bonnes couleurs
                                color: getTagColor(tagFr),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                labelAffiche
                                    .toUpperCase(), // 5. On affiche le texte traduit et en MAJUSCULES !
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  // --- PRIX ---
                  Text(
                    "${product.price} DA",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ElevatedButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () async {
                        logEvent('add_to_cart');
                        final user = FirebaseAuth.instance.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loginNeededMsg),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        context.read<CartController>().increment();

                        // Dans votre page Shop, on n'a pas de variante, donc le titre est direct
                        final String finalTitle = displayTitle;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartPage(),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "$finalTitle $addedToCartMsg", // Exemple: "Gloss ajouté !"
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons
                                          .shopping_cart_checkout, // Même icône pour la cohérence
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            backgroundColor: const Color(0xFFDCDCDC),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                        final cartRef = FirebaseFirestore.instance
                            .collection('carts')
                            .doc(user.uid);

                        try {
                          final cartDoc = await cartRef.get();
                          List<Map<String, dynamic>> items = [];
                          String currentStatus = '';

                          if (cartDoc.exists) {
                            final data = cartDoc.data();
                            items = List<Map<String, dynamic>>.from(
                              data?['items'] ?? [],
                            );
                            currentStatus = data?['status'] ?? '';
                          }

                          // --- LOGIQUE ANTI-DOUBLON ET TRADUCTION ---
                          final String cartItemId = product.id;
                          final index = items.indexWhere(
                            (i) => i['productId'] == product.id,
                          );

                          if (index >= 0) {
                            // Le produit existe déjà, on augmente juste la quantité
                            items[index]['quantity'] += 1;
                            items[index]['costPrice'] = product.costPrice;

                            // 🟢 SÉCURITÉ : On force l'ajout du titre EN si l'ancien panier ne l'avait pas
                            items[index]['title_en'] = product.titleEn;
                            items[index]['title'] = product.title;
                          } else {
                            // Nouveau produit : on enregistre le titre FR ET le titre EN
                            items.add({
                              'cartItemId': cartItemId,
                              'productId': product.id,
                              'title': product.title,
                              'title_en': product.titleEn, // Parfait !
                              'brand': product.brand,
                              'price': product.price,
                              'costPrice': product.costPrice,
                              'quantity': 1,
                              'imageUrl': product.imageUrl,
                            });
                          }

                          Map<String, dynamic> cartData = {
                            'items': items,
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          // Si c'est un nouveau panier ou un panier vidé/commandé, on reset le statut
                          if (currentStatus == '' ||
                              currentStatus == 'empty' ||
                              currentStatus == 'ordered' ||
                              !cartDoc.exists) {
                            cartData['status'] = 'initiated';
                          }

                          await cartRef.set(cartData, SetOptions(merge: true));
                        } catch (e) {
                          debugPrint("Erreur panier: $e");
                        }
                      },

                icon: Icon(
                  // On change l'icône si rupture
                  product.isOutOfStock
                      ? Icons.not_interested
                      : Icons.shopping_cart,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  // TEXTE DYNAMIQUE : Rupture ou Acheter
                  product.isOutOfStock
                      ? (isEn ? "OUT OF STOCK" : "RUPTURE")
                      : buyLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryPink,
                  // COULEUR DU BOUTON QUAND IL EST DÉSACTIVÉ (Rupture)
                  disabledBackgroundColor: Colors.grey.shade400,
                  // COULEUR DU TEXTE/ICONE QUAND IL EST DÉSACTIVÉ
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
