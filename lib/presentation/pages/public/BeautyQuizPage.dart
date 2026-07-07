import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/pages/public/cart_page.dart';
import 'package:veloria/presentation/pages/public/product_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import 'package:veloria/presentation/widgets/shake_btn.dart';

class BeautyQuizPage extends StatefulWidget {
  final String mode; // "routine" ou "search"
  const BeautyQuizPage({super.key, required this.mode});

  @override
  State<BeautyQuizPage> createState() => _BeautyQuizPageState();
}

class _BeautyQuizPageState extends State<BeautyQuizPage> {
  final PageController _pageController = PageController();
  final ScrollController _quizScrollController = ScrollController();
  late bool isEn;

  // État du Quiz
  int currentStep = 0;
  String? selectedCategory;
  String? selectedProfile;
  String? selectedSecondary;
  String? selectedGoal;
  String? selectedImperfectionType;
  String? skinType;
  String? hairTexture;
  String? hairState;
  bool isHairDamaged = false;
  bool isHairColored = false;
  bool isBlonde = false;
  bool _isLoadingResult = false;

  bool get isAr =>
      Provider.of<LanguageProvider>(context, listen: false).languageCode ==
      'ar';

  String _q(String fr, String en, String ar) => isAr ? ar : (isEn ? en : fr);

  String _badgeText(String value) {
    final key = value.toLowerCase().trim();
    final labels = <String, List<String>>{
      'hydratation': ['Hydratation', 'Hydration', 'ترطيب'],
      'réparation': ['Réparation', 'Repair', 'ترميم'],
      'reparation': ['Réparation', 'Repair', 'ترميم'],
      'brillance': ['Brillance', 'Shine', 'لمعان'],
      'anti-chute': ['Anti-chute', 'Anti-hair loss', 'ضد التساقط'],
      'volume': ['Volume', 'Volume', 'حجم'],
      'anti-imperfections': [
        'Anti-imperfections',
        'Anti-imperfections',
        'ضد الشوائب',
      ],
      'éclat': ['Éclat', 'Radiance', 'إشراقة'],
      'eclat': ['Éclat', 'Radiance', 'إشراقة'],
      'anti-âge': ['Anti-âge', 'Anti-aging', 'مضاد للتقدم في السن'],
      'anti-age': ['Anti-âge', 'Anti-aging', 'مضاد للتقدم في السن'],
      'apaisant': ['Apaisant', 'Soothing', 'تهدئة'],
      'boutons': ['Boutons & Acné', 'Pimple & Acne', 'حبوب وحب الشباب'],
      'taches': ['Taches & Cicatrices', 'Dark Spots & Marks', 'بقع وآثار'],
      'entretenir': ['Entretenir', 'Maintain', 'عناية يومية'],
      'maintenance': ['Maintenance', 'Maintenance', 'عناية مستمرة'],
      'lisses': ['Lisses', 'Straight', 'أملس'],
      'ondulés': ['Ondulés', 'Wavy', 'مموج'],
      'bouclés': ['Bouclés', 'Curly', 'كيرلي'],
      'frisés': ['Frisés', 'Coily', 'مجعد'],
      'crépus': ['Crépus', 'Kinky', 'أفرو'],
      'secs': ['Secs', 'Dry', 'جاف'],
      'normaux': ['Normaux', 'Normal', 'عادي'],
      'gras': ['Gras', 'Oily', 'دهني'],
      'mixtes': ['Mixtes', 'Combination', 'مختلط'],
      'sèche': ['Sèche', 'Dry Skin', 'جافة'],
      'seche': ['Sèche', 'Dry Skin', 'جافة'],
      'très sèche': ['Très Sèche', 'Very Dry Skin', 'جافة جداً'],
      'tres seche': ['Très Sèche', 'Very Dry Skin', 'جافة جداً'],
      'très_sèche': ['Très Sèche', 'Very Dry Skin', 'جافة جداً'],
      'tres_seche': ['Très Sèche', 'Very Dry Skin', 'جافة جداً'],
      'normale': ['Normale', 'Normal Skin', 'عادية'],
      'grasse': ['Grasse', 'Oily Skin', 'دهنية'],
      'mixte': ['Mixte', 'Combination Skin', 'مختلطة'],
      'sensible': ['Sensible', 'Sensitive Skin', 'حساسة'],
      'teint': ['Teint', 'Complexion', 'البشرة'],
      'yeux': ['Yeux', 'Eyes', 'العيون'],
      'lèvres': ['Lèvres', 'Lips', 'الشفاه'],
      'levres': ['Lèvres', 'Lips', 'الشفاه'],
      'lumineux': ['Lumineux', 'Radiant', 'مشرق'],
      'mat': ['Mat', 'Matte', 'مطفي'],
      'matte': ['Mat', 'Matte', 'مطفي'],
      'glossy': ['Brillant', 'Glossy', 'لامع'],
      'couvrance_moyenne': [
        'Couvrance Moyenne',
        'Medium Coverage',
        'تغطية متوسطة',
      ],
      'haute_couvrance': ['Haute Couvrance', 'Full Coverage', 'تغطية عالية'],
      'naturel': ['Naturel', 'Natural Look', 'طبيعي'],
      'intense': ['Intense', 'Bold Look', 'قوي'],
      'waterproof': ['Waterproof', 'Waterproof', 'مقاوم للماء'],
      'baume_tinté': ['Baume Teinté', 'Tinted Balm', 'بلسم ملون'],
      'baume_teinte': ['Baume Teinté', 'Tinted Balm', 'بلسم ملون'],
      'blush': ['Blush', 'Blush', 'بلاشر'],
      'highlighter': ['Highlighter', 'Highlighter', 'هايلايتر'],
      'highligher': ['Highlighter', 'Highlighter', 'هايلايتر'],
      'poudre': ['Poudre', 'Powder', 'بودرة'],
      'spray fixateur': ['Spray Fixateur', 'Setting Spray', 'بخاخ تثبيت'],
      'anti-cernes': ['Anti-cernes', 'Concealer', 'كونسيلر'],
      'anti-cerne': ['Anti-cernes', 'Concealer', 'كونسيلر'],
      'sourcils': ['Sourcils', 'Eyebrows', 'الحواجب'],
      'soucils': ['Sourcils', 'Eyebrows', 'الحواجب'],
      'mascara': ['Mascara', 'Mascara', 'ماسكارا'],
      'eyeliner': ['Eyeliner', 'Eyeliner', 'آيلاينر'],
      'crayon à lèvres': ['Crayon à lèvres', 'Lip liner', 'قلم شفاه'],
      'crayon a levres': ['Crayon à lèvres', 'Lip liner', 'قلم شفاه'],
      'rouge à lèvres': ['Rouge à lèvres', 'Lipstick', 'أحمر شفاه'],
      'rouge a levres': ['Rouge à lèvres', 'Lipstick', 'أحمر شفاه'],
      'gloss': ['Gloss', 'Gloss', 'غلوس'],
      'encre à lèvres': ['Encre à lèvres', 'Lip tint', 'تينت شفاه'],
      'encre a levres': ['Encre à lèvres', 'Lip tint', 'تينت شفاه'],
      'encres à lèvres': ['Encre à lèvres', 'Lip tint', 'تينت شفاه'],
      'encres a levres': ['Encre à lèvres', 'Lip tint', 'تينت شفاه'],
      'gel douche': ['Gel douche', 'Body wash', 'جل استحمام'],
      'gommage': ['Gommage', 'Body scrub', 'مقشر جسم'],
      'lait corporel': ['Lait corporel', 'Body lotion', 'لوشن جسم'],
      'shampooing': ['Shampooing', 'Shampoo', 'شامبو'],
      'masque': ['Masque', 'Mask', 'ماسك'],
      'après-shampooing': ['Après-shampooing', 'Conditioner', 'بلسم'],
      'apres-shampooing': ['Après-shampooing', 'Conditioner', 'بلسم'],
      'sérum/huile': ['Sérum/Huile', 'Serum/Oil', 'سيروم/زيت'],
      'serum/huile': ['Sérum/Huile', 'Serum/Oil', 'سيروم/زيت'],
    };
    final label = labels[key];
    if (label == null) return value;
    return isAr ? label[2] : (isEn ? label[1] : label[0]);
  }

  bool isLoading = true; // Par défaut, on considère qu'on charge les données
  String? blondeRoutinePreference;

  bool _isJumping = false;
  List<Map<String, dynamic>> results = [];
  Set<String> displayedProductIds = {};

  // --- NOUVEAU : GETTERS SÉCURISÉS POUR LES UNIVERS ---
  bool get _isHairUniverse {
    final cat = _normalizeTag(selectedCategory ?? "");
    return cat.contains("cheveux") || cat.contains("hair");
  }

  bool get _isFaceUniverse {
    final cat = _normalizeTag(selectedCategory ?? "");
    return cat.contains("soins_visage") || cat.contains("face");
  }

  // Calcul dynamique des étapes
  int get totalSteps {
    int steps = 5; // Par défaut : Catégorie -> Profil -> Objectif -> Résultat

    // Si c'est les cheveux, on a l'étape de l'état actuel
    if (widget.mode == "routine" && _isHairUniverse) {
      steps++;
    }

    // Si c'est le visage et qu'on choisit Anti-imperfections, on ajoute l'étape Boutons/Taches
    if (widget.mode == "routine" &&
        _isFaceUniverse &&
        (_normalizeTag(selectedGoal ?? "").contains("imperfection"))) {
      steps++;
    }

    return steps;
  }

  // --- NOUVEAU : METHODE DE SCROLL AUTOMATIQUE ---
  void _scrollToBottom() {
    // On attend que Flutter ait fini de dessiner les nouvelles options (le blond, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_quizScrollController.hasClients) {
        _quizScrollController.animateTo(
          // ou .animateTo
          _quizScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _nextStep() async {
    int nextStep = currentStep + 1;

    // 1. GESTION DU SKIP (Si on est à l'état des cheveux et qu'on est coloré)
    if (currentStep == 2 && isHairColored) {
      // Si l'utilisateur a choisi la routine violette, on peut directement
      // générer les résultats et aller à l'écran de fin (Index 6)
      if (blondeRoutinePreference == "violet") {
        nextStep = 6;
      } else {
        // Sinon, on passe au moins l'objectif et on va à l'étape suivante (Index 4)
        nextStep = 4;
      }
    }

    // 2. DÉCLENCHEMENT DE LA ROUTINE
    // Si la page suivante est l'écran des résultats (Index 6), on affiche le loader puis on génère la routine.
    if (nextStep == 6) {
      _goToResultWithLoader();
      return;
    }

    // 3. TRANSITION DE PAGE ULTRA-RAPIDE ANTI-BALAYAGE
    if (nextStep == currentStep + 1) {
      // Avancement normal d'une seule page : joli glissement classique
      _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 🌟 PARCOURS AVEC SAUT (Zapping) :
      // On force une animation d'une seule milliseconde.
      // C'est tellement flash qu'il est physiquement impossible de voir le défilement !
      _pageController.animateToPage(
        nextStep,
        duration: const Duration(milliseconds: 1),
        curve: Curves.linear,
      );
    }

    setState(() {
      currentStep = nextStep;
    });

    // On laisse le temps au scroll vertical de s'ajuster proprement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((
      doc,
    ) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          // Sécurisation des chaînes de caractères
          skinType = data['skinType']?.toString();
          hairTexture = data['hairTexture']?.toString();
          hairState = data['hairState']?.toString();

          // 🛡️ Sécurisation ABSOLUE des booléens (accepte true ou "true")
          isHairDamaged =
              data['isHairDamaged'] == true ||
              data['isHairDamaged'].toString() == 'true';
          isHairColored =
              data['isHairColored'] == true ||
              data['isHairColored'].toString() == 'true';
          isBlonde =
              data['isBlonde'] == true || data['isBlonde'].toString() == 'true';
        });
        debugPrint("✨ Profil chargé : $skinType / $hairTexture");
      }
    });
  }

  Future<void> _saveToFirestore(String field, String value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // On utilise un try-catch pour éviter que l'erreur ne remonte à l'UI
    try {
      // Suppression du await ici n'est pas nécessaire si l'appelant ne l'attend pas,
      // mais on s'assure que c'est bien une opération asynchrone isolée.
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        field: value,
        'lastQuizDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Firestore sync: $field");
    } catch (e) {
      debugPrint("❌ Erreur silencieuse Firestore: $e");
    }
  }

  Widget _buildMemoryMessage() {
    String? info;
    String normCategory = _normalizeTag(selectedCategory ?? "");

    if (normCategory.contains("soins_visage") && skinType != null) {
      info = skinType;
    }
    if (normCategory.contains("cheveux") && hairState != null) info = hairState;

    if (info == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: Colors.pink[300], size: 16),
          const SizedBox(width: 8),

          // 🟢 ON ENVELOPPE LE TEXT DANS UN EXPANDED
          Expanded(
            child: Text(
              _q(
                "On a gardé ton profil (${getTranslatedBadge(info, isEn)}) en mémoire !",
                "We remembered your ${getTranslatedBadge(info, isEn)} profile!",
                "تذكرنا ملفك (${getTranslatedBadge(info, isEn)})!",
              ),
              style: TextStyle(
                color: Colors.pink[700],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeTag(String tag) {
    return tag
        .toLowerCase()
        .replaceAll(' ', '_') // Remplace les espaces par des underscores
        .trim(); // Enlève les espaces au début et à la fin
  }

  String _normalizeMatchTag(String tag) {
    return tag
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ä', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c');
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // --- MOTEUR DE MATCHING RECONSTRUIT ET SÉCURISÉ ---
  Future<List<Map<String, dynamic>>> _matchProducts(
    List<String> currentTags, {
    bool excludeDisplayed = true,
    bool trackDisplayed = true,
    bool limitToBestByOrigin = true,
  }) async {
    if (currentTags.isEmpty || selectedCategory == null) {
      debugPrint("⚠️ [MATCH] Abandon : tags vides ou catégorie nulle.");
      return [];
    }

    final products = await _fetchProducts();

    // Normalisation complète des tags de recherche (on remplace aussi tout-type par tout_type au cas où)
    final tagSet = currentTags.map((t) {
      String clean = _normalizeMatchTag(t);
      if (clean == "tout_types") return "tout_type";
      return clean;
    }).toSet();

    debugPrint("⚙️ [MATCH] Lancement du matching pour : $tagSet");

    const tagsProfilUniversels = {
      "normale",
      "seche",
      "grasse",
      "mixte",
      "lisses",
      "ondules",
      "boucles",
      "frises",
      "crepus",
      "normaux",
      "secs",
      "gras",
      "tout_type",
      "tout_types",
    };

    List<Map<String, dynamic>> eligible = products.where((p) {
      // Normalisation de la catégorie pour éviter les pièges FR/EN de l'UI
      String dbCategory = p['category'].toString().toLowerCase().trim();
      String uiCategory = selectedCategory!.toLowerCase().trim();

      if (uiCategory.contains("soins visage") || uiCategory.contains("face")) {
        if (!dbCategory.contains("soins visage") &&
            !dbCategory.contains("face")) {
          return false;
        }
      } else if (uiCategory.contains("cheveux") ||
          uiCategory.contains("hair")) {
        if (!dbCategory.contains("cheveux") && !dbCategory.contains("hair")) {
          return false;
        }
      } else if (uiCategory.contains("soins corps") ||
          uiCategory.contains("body")) {
        if (!dbCategory.contains("soins corps") &&
            !dbCategory.contains("body")) {
          return false;
        }
      } else if (uiCategory.contains("maquillage") ||
          uiCategory.contains("makeup")) {
        if (!dbCategory.contains("maquillage") &&
            !dbCategory.contains("makeup")) {
          return false;
        }
      }

      // Sécurité ID
      if (excludeDisplayed && displayedProductIds.contains(p['id'])) {
        return false;
      }

      // Récupération et normalisation des tags du produit
      final productTags = List<String>.from(
        p['tags'] ?? [],
      ).map((t) => _normalizeMatchTag(t)).toList();

      // 🌟 LE FILTRAGE INTELLIGENT ET FLEXIBLE :
      return tagSet.every((requiredTag) {
        if (tagsProfilUniversels.contains(requiredTag)) {
          // Un produit correspond si il a le tag précis OU s'il est universel (avec _ ou -)
          return productTags.contains(requiredTag) ||
              productTags.contains("tout_type") ||
              productTags.contains("tout_types");
        } else {
          return productTags.contains(requiredTag);
        }
      });
    }).toList();

    if (!limitToBestByOrigin) {
      eligible.shuffle();
      return eligible;
    }

    List<Map<String, dynamic>> finalSelection = [];

    Map<String, dynamic>? pickBest(
      List<Map<String, dynamic>> candidates,
      String origin,
    ) {
      if (candidates.isEmpty) return null;

      var specificMatches = candidates.where((p) {
        final pTags = List<String>.from(
          p['tags'] ?? [],
        ).map((t) => _normalizeMatchTag(t)).toList();
        return tagSet.any(
          (tag) => tagsProfilUniversels.contains(tag) && pTags.contains(tag),
        );
      }).toList();

      if (specificMatches.isNotEmpty) {
        specificMatches.shuffle();
        return specificMatches.first;
      } else {
        candidates.shuffle();
        return candidates.first;
      }
    }

    var localCandidates = eligible
        .where((p) => p['origin'] == 'Local')
        .toList();
    var bestLocal = pickBest(localCandidates, "Local");
    if (bestLocal != null) finalSelection.add(bestLocal);

    var importCandidates = eligible
        .where((p) => p['origin'] == 'Importation')
        .toList();
    var bestImport = pickBest(importCandidates, "Importation");
    if (bestImport != null) finalSelection.add(bestImport);

    // Sécurité : si l'origine n'est pas exactement Local/Importation, on garde quand même un candidat valide.
    if (finalSelection.isEmpty && eligible.isNotEmpty) {
      eligible.shuffle();
      finalSelection.add(eligible.first);
    }

    // On enregistre les IDs pour ne pas les dupliquer au sein d'un même écran de résultats
    if (trackDisplayed) {
      for (var p in finalSelection) {
        displayedProductIds.add(p['id']);
      }
    }

    return finalSelection;
  }

  Future<void> _shuffleSingleProduct(String type, int indexToReplace) async {
    // Étape 1 : Recréer les tags pour relancer la recherche spécifique de ce type
    String category = selectedCategory?.trim() ?? "";
    String profile = selectedProfile ?? "";
    String normType = _normalizeTag(type);

    List<String> tagsForThisType = [
      _normalizeTag(category),
      _normalizeTag(profile),
    ];
    if (selectedSecondary != null) {
      tagsForThisType.add(_normalizeTag(selectedSecondary!));
    }
    if (selectedGoal != null) tagsForThisType.add(_normalizeTag(selectedGoal!));
    tagsForThisType.add(normType);

    String oldId = results[indexToReplace]['id'];
    final currentRoutineIds = results
        .asMap()
        .entries
        .where((entry) => entry.key != indexToReplace)
        .map((entry) => entry.value['id']?.toString())
        .whereType<String>()
        .toSet();

    // --- 🌟 L'ASTUCE TOUT-TYPES ICI ---
    // 1. On lance la première recherche stricte (Profil exact)
    var alternativeProducts = await _matchProducts(
      tagsForThisType,
      excludeDisplayed: false,
      trackDisplayed: false,
      limitToBestByOrigin: false,
    );

    // 2. On prépare une deuxième liste de tags où on remplace le profil par "tout-types"
    List<String> fallbackTags = List.from(tagsForThisType);
    String normProfile = _normalizeTag(profile);

    if (fallbackTags.contains(normProfile)) {
      int profileIndex = fallbackTags.indexOf(normProfile);
      fallbackTags[profileIndex] = "tout_type"; // Change par "tout_type"
    }

    // 3. On lance la deuxième recherche (Produits universels)
    var universalProducts = await _matchProducts(
      fallbackTags,
      excludeDisplayed: false,
      trackDisplayed: false,
      limitToBestByOrigin: false,
    );

    // 4. On fusionne les résultats pour maximiser les alternatives sans sortir du profil.
    List<Map<String, dynamic>> allCandidates = [
      ...alternativeProducts,
      ...universalProducts,
    ];

    // 🛡️ FILTRE DE SÉCURITÉ STRICT (Exclusion Colorés / Abîmés)
    // On élimine les produits techniques si l'utilisatrice n'a pas coché ces critères
    allCandidates = allCandidates.where((product) {
      final productTags = List<String>.from(product['tags'] ?? []);

      // Si l'utilisatrice n'est PAS colorée (isHairColored == false), on vire les produits tagués "colorés"
      if (!isHairColored && productTags.contains('colorés')) {
        return false;
      }

      // Si l'utilisatrice n'a PAS les cheveux abîmés, on vire les produits tagués "abîmés" ou "réparation"
      if (!isHairDamaged &&
          (productTags.contains('abîmés') ||
              productTags.contains('réparation'))) {
        return false;
      }

      return true; // Le produit est validé
    }).toList();

    // On évite de reprendre le même produit ou un produit déjà visible dans la routine.
    var realAlts = allCandidates.where((p) {
      final id = p['id']?.toString();
      return id != null && id != oldId && !currentRoutineIds.contains(id);
    }).toList();

    // On utilise un Set pour éliminer les doublons de produits au cas où un produit aurait les deux tags
    final uniqueIds = <String>{};
    realAlts.retainWhere((p) => uniqueIds.add(p['id']));

    if (realAlts.isNotEmpty) {
      realAlts.shuffle();

      setState(() {
        displayedProductIds.remove(oldId);
        results[indexToReplace] = realAlts.first;
        // On s'assure de bien ré-enregistrer le nouvel ID affiché dans ton tracking
        displayedProductIds.add(realAlts.first['id']);
      });
      debugPrint(
        "🎯 Nouveau produit assigné à l'étape $indexToReplace (Profil ou Tout-types nettoyé) !",
      );
    } else {
      // S'il n'y a vraiment aucune alternative dans le catalogue pour ce type de produit.
      displayedProductIds.add(oldId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _q(
                "Aucun autre produit disponible pour cette étape.",
                "No other product available for this step.",
                "لا يوجد منتج آخر متاح لهذه الخطوة.",
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB76E79),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // --- ROUTINE LOGIQUE RE-UNIFIÉE ET NETTOYÉE ---
  Future<void> _generateRoutine() async {
    debugPrint("--------------------------------------------------");
    debugPrint("🚀 [VELORIA TRACKING] INITIALISATION DE LA ROUTINE");

    setState(() {
      isLoading = true; // 🟢 1. On active le chargement immédiatement
      results = [];
      displayedProductIds.clear();
    });

    // 🌟 1. DICTIONNAIRE DE CONVERSION UI (EN -> FR) POUR LE MOTEUR
    String category = selectedCategory?.trim() ?? "";
    String profile = selectedProfile?.trim() ?? "";
    String? secondary = selectedSecondary?.trim();
    String? goal = selectedGoal?.trim();
    String categoryLower = category.toLowerCase();

    // 🛠️ MODIFICATION 1 : GESTION ET PRIORISATION DU DIAGNOSTIC BLOND / SAUT ETAPE
    if (_isHairUniverse) {
      if (isBlonde && blondeRoutinePreference != "violet") {
        goal = "blond";
        debugPrint(
          "📌 [VELORIA TRACKING] Profil Blonde détecté (Routine Régulière) -> Objectif forcé à: 'blond'",
        );
      } else if (goal == null) {
        if (isHairColored) {
          goal = "colorés";
          debugPrint(
            "📌 [VELORIA TRACKING] Étape Goal sautée -> Requalification automatique sur le tag: 'colorés'",
          );
        } else if (isHairDamaged) {
          goal = "abîmés";
          debugPrint(
            "📌 [VELORIA TRACKING] Étape Goal sautée -> Requalification automatique sur le tag: 'réparation'",
          );
        }
      }
    }

    // Affichage complet de l'état des variables avant traitement
    debugPrint("📊 [VELORIA TRACKING] Valeurs brutes récoltées au clic :");
    debugPrint(
      "   - Univers (Category) : $category (Tag: ${_normalizeTag(category)})",
    );
    debugPrint(
      "   - Profil / Structure : $profile (Tag: ${_normalizeTag(profile)})",
    );
    debugPrint(
      "   - Cuir chevelu (Secondary) : $secondary (Tag: ${secondary != null ? _normalizeTag(secondary) : 'null'})",
    );
    debugPrint("   - Objectif retenu (Goal) : $goal");
    debugPrint(
      "   - Flags techniques : Abîmé=$isHairDamaged | Coloré=$isHairColored | Blond=$isBlonde (Pref: $blondeRoutinePreference)",
    );

    // 1. ROUTINE BLONDE VIOLETTE AUTOMATIQUE (Reste inchangée)
    if (_isHairUniverse && isBlonde && blondeRoutinePreference == "violet") {
      List<String> types = ["Shampooing", "Masque"];
      List<Map<String, dynamic>> violetRoutine = [];
      debugPrint(
        "💜 [VELORIA TRACKING] Mode spécial : Routine Blonde Déjaunissante activée.",
      );

      for (String type in types) {
        List<String> violetTags = [
          _normalizeTag(category),
          'blond-violet',
          _normalizeTag(type),
        ];
        debugPrint(
          "🔍 [VELORIA TRACKING] Requête Firestore Violette [$type] avec les tags: $violetTags",
        );

        var matches = await _matchProducts(violetTags);
        if (matches.isNotEmpty) {
          matches.shuffle();
          violetRoutine.add(matches.first);
        }
      }

      if (mounted) {
        setState(() {
          results = violetRoutine;
          isLoading =
              false; // 🟢 2. Sécurité : chargement fini pour la routine violette
        });
      }
      debugPrint(
        "✅ [VELORIA TRACKING] Fin de traitement. Routine Violette générée.",
      );
      return;
    }

    // 2. ROUTINE STANDARD OU ADAPTATIVE
    List<String> baseProfileTags = [
      _normalizeTag(category),
      _normalizeTag(profile),
    ];
    if (secondary != null) baseProfileTags.add(_normalizeTag(secondary));
    if (goal != null) baseProfileTags.add(_normalizeTag(goal));

    // 🛠️ MODIFICATION 2 : SÉCURITÉ STRICTE SUR LE TAG COULEUR
    if (_isHairUniverse &&
        isHairColored &&
        !isBlonde &&
        !baseProfileTags.contains("colorés")) {
      baseProfileTags.add("colorés");
    }

    if (selectedImperfectionType != null &&
        categoryLower.contains("soins_visage") &&
        goal == "anti-imperfections") {
      baseProfileTags.add(selectedImperfectionType!);
    }

    debugPrint(
      "🏷️ [VELORIA TRACKING] Bloc de tags de base consolidé : $baseProfileTags",
    );

    // Détermination des types de produits à chercher
    List<String> typesToSearch = [];

    if (categoryLower.contains("soins_visage") ||
        categoryLower.contains("face")) {
      typesToSearch = ["Nettoyant", "Sérum", "Crème"];
    } else if (categoryLower.contains("cheveux") ||
        categoryLower.contains("hair")) {
      typesToSearch = ["Shampooing", "Masque", "Sérum/Huile"];
    } else if (categoryLower.contains("maquillage") ||
        categoryLower.contains("makeup")) {
      String profileLower = profile.toLowerCase();
      String goalLower = (selectedGoal ?? "").toLowerCase();

      if (profileLower.contains("teint") ||
          profileLower.contains("complexion")) {
        typesToSearch = ["Base", "Fond de teint"];
        if (goalLower.contains("mat")) {
          typesToSearch.add("Poudre");
        } else if (goalLower.contains("lumineux")) {
          typesToSearch.add("blush");
        } else if (goalLower.contains("couvrance_moyenne") ||
            goalLower.contains("haute_couvrance")) {
          typesToSearch.add("Anti-cernes");
        } else {
          typesToSearch.add("Poudre");
        }
      } else if (profileLower.contains("yeux") ||
          profileLower.contains("eyes")) {
        typesToSearch = ["Mascara", "Eyeliner", "sourcils"];
      } else {
        if (goalLower.contains("glossy")) {
          typesToSearch = ["Crayon à lèvres", "Gloss", "Baume"];
        } else if (goalLower.contains("mat")) {
          typesToSearch = [
            "Crayon à lèvres",
            "Rouge à lèvres",
            "Encre à lèvres",
          ];
        } else if (goalLower.contains("baume_teinte")) {
          typesToSearch = ["Baume", "Encre à lèvres"];
        } else {
          typesToSearch = ["Crayon à lèvres", "Rouge à lèvres", "Gloss"];
        }
      }
    } else {
      typesToSearch = ["Gel douche", "Gommage", "Lait corporel"];
    }

    // Fallback Masque -> Après-shampooing
    if (categoryLower.contains("cheveux") || categoryLower.contains("hair")) {
      List<String> testMasqueTags = List.from(baseProfileTags);

      if (isHairColored && !isBlonde) {
        if (!testMasqueTags.contains("colorés")) {
          testMasqueTags.add("colorés");
        }
      } else if (isHairDamaged) {
        if (!testMasqueTags.contains("abîmés") &&
            !testMasqueTags.contains("réparation")) {
          testMasqueTags.add("réparation");
        }
      }

      testMasqueTags.add("masque");

      debugPrint(
        "🔍 [VELORIA TRACKING] Test Masque strict avec les tags : $testMasqueTags",
      );

      var masqueResults = await _matchProducts(
        testMasqueTags,
        excludeDisplayed: false,
        trackDisplayed: false,
        limitToBestByOrigin: false,
      );

      Set<String> uniqueMasqueFallbackTags = {};
      String normProfile = _normalizeTag(profile);
      String normSecondary = secondary != null ? _normalizeTag(secondary) : "";

      for (String tag in testMasqueTags) {
        if (tag == normProfile || tag == normSecondary) {
          uniqueMasqueFallbackTags.add("tout_type");
        } else {
          uniqueMasqueFallbackTags.add(tag);
        }
      }

      List<String> testMasqueFallbackTags = uniqueMasqueFallbackTags.toList();

      debugPrint(
        "🌟 [VELORIA TRACKING] Test Masque universel avec les tags nettoyés : $testMasqueFallbackTags",
      );

      var masqueUniversalResults = await _matchProducts(
        testMasqueFallbackTags,
        excludeDisplayed: false,
        trackDisplayed: false,
        limitToBestByOrigin: false,
      );

      List<Map<String, dynamic>> allMasqueResults = [
        ...masqueResults,
        ...masqueUniversalResults,
      ];

      final uniqueMasqueIds = <String>{};
      allMasqueResults.retainWhere((p) => uniqueMasqueIds.add(p['id']));

      if (allMasqueResults.isNotEmpty) {
        for (var p in allMasqueResults) {
          displayedProductIds.remove(p['id']);
        }
      } else {
        debugPrint(
          "⚠️ [VELORIA TRACKING] Aucun Masque strict ou tout_type en stock. Mutation du type en 'Après-shampooing'",
        );

        int index = typesToSearch.indexOf("Masque");
        if (index != -1) {
          typesToSearch[index] = "Après-shampooing";
        }
      }
    }

    Map<String, List<Map<String, dynamic>>> candidatesByType = {};
    Set<String> potentialRanges = {};

    for (String type in typesToSearch) {
      List<String> tagsForThisType = List.from(baseProfileTags);
      String normType = _normalizeTag(type);

      if (categoryLower.contains("cheveux") || categoryLower.contains("hair")) {
        if (isHairColored && !isBlonde) {
          if (!tagsForThisType.contains("colorés"))
            tagsForThisType.add("colorés");
        } else if (isHairDamaged) {
          if (!tagsForThisType.contains("abîmés") &&
              !tagsForThisType.contains("réparation")) {
            tagsForThisType.add("réparation");
          }
        } else if (secondary != null && secondary.isNotEmpty) {
          tagsForThisType.add(_normalizeTag(secondary));
        }
      }

      tagsForThisType.add(normType);
      debugPrint(
        "🔍 [VELORIA TRACKING] Requête Stricte [$type] avec les tags : $tagsForThisType",
      );

      var typeMatches = await _matchProducts(tagsForThisType);

      Set<String> uniqueFallbackTags = {};
      String normProfile = _normalizeTag(profile);
      String normSecondary = secondary != null ? _normalizeTag(secondary) : "";

      for (String tag in tagsForThisType) {
        if (tag == normProfile || tag == normSecondary) {
          uniqueFallbackTags.add("tout_type");
        } else {
          uniqueFallbackTags.add(tag);
        }
      }

      List<String> fallbackTags = uniqueFallbackTags.toList();
      debugPrint(
        "🌟 [VELORIA TRACKING] Requête Universelle [$type] avec les tags nettoyés : $fallbackTags",
      );
      var universalMatches = await _matchProducts(fallbackTags);

      List<Map<String, dynamic>> combinedMatches = [
        ...typeMatches,
        ...universalMatches,
      ];
      final uniqueIds = <String>{};
      combinedMatches.retainWhere((p) => uniqueIds.add(p['id']));

      candidatesByType[type] = combinedMatches;

      for (var p in combinedMatches) {
        final pTags = List<String>.from(
          p['tags'] ?? [],
        ).map((t) => t.toLowerCase().trim()).toList();
        for (var t in pTags) {
          if (t.startsWith("gamme_")) potentialRanges.add(t);
        }
      }
      // 🔍 AJOUTE CE PRINT DE SÉCURITÉ ICI :
      debugPrint(
        "🔍 [TEST] Étape $type - Candidats trouvés : ${combinedMatches.map((p) => p['title']).toList()}",
      );
    }

    // --- HARMONISATION DE LA GAMME DOMINANTE ---
    String? bestRange;
    int maxCount = 0;

    for (String range in potentialRanges) {
      int count = 0;
      String targetRange = range.toLowerCase().trim();

      for (String type in typesToSearch) {
        final matches = candidatesByType[type] ?? [];
        bool hasRange = matches.any((p) {
          final pTags = List<String>.from(
            p['tags'] ?? [],
          ).map((t) => t.toLowerCase().trim()).toList();
          return pTags.contains(targetRange);
        });
        if (hasRange) count++;
      }

      if (count > maxCount) {
        maxCount = count;
        bestRange = targetRange;
      }
    }

    // --- CONSTRUCTION DE LA ROUTINE FINALE ---
    List<Map<String, dynamic>> finalRoutine = [];
    List<String> typesEffectivementTrouves = [];

    for (String type in typesToSearch) {
      var candidates = List<Map<String, dynamic>>.from(
        candidatesByType[type] ?? [],
      );
      if (candidates.isEmpty) {
        debugPrint(
          "❌ [VELORIA TRACKING] Aucun produit trouvé pour l'étape [$type]",
        );
        continue;
      }

      Map<String, dynamic>? selected;

      if (bestRange != null) {
        var rangeMatches = candidates.where((p) {
          final pTags = List<String>.from(
            p['tags'] ?? [],
          ).map((t) => t.toLowerCase().trim()).toList();
          return pTags.contains(bestRange);
        }).toList();

        if (rangeMatches.isNotEmpty) {
          rangeMatches.shuffle();
          selected = rangeMatches.first;
        }
      }

      if (selected == null) {
        candidates.shuffle();
        selected = candidates.first;
      }

      finalRoutine.add(selected);
      typesEffectivementTrouves.add(type);
    }

    // Sécurité Produit Local Veloria
    bool hasLocal = finalRoutine.any((p) => p['origin'] == 'Local');
    if (!hasLocal && finalRoutine.isNotEmpty) {
      for (int i = 0; i < finalRoutine.length; i++) {
        String typeReel = typesEffectivementTrouves[i];
        var localAlt = candidatesByType[typeReel]
            ?.where((p) => p['origin'] == 'Local')
            .toList();

        if (localAlt != null && localAlt.isNotEmpty) {
          localAlt.shuffle();
          finalRoutine[i] = localAlt.first;
          break;
        }
      }
    }

    // 🟢 3. MISE À JOUR FINALE DE L'ÉTAT GRAPHIQUE ET FIN DU LOADER
    if (mounted) {
      setState(() {
        results = finalRoutine;
        isLoading =
            false; // Tout est fini (vide ou plein), on coupe la recherche !
      });
      debugPrint(
        "✅ [VELORIA TRACKING] PROCESSUS TERMINÉ : ${results.length} produits affichés.",
      );
      debugPrint("--------------------------------------------------");
    }
  }

  Future<void> _goToResultWithLoader() async {
    if (!mounted) return;

    setState(() {
      currentStep = 6;
      _isLoadingResult = true;
      isLoading = true;
      results = [];
      displayedProductIds.clear();
    });

    _pageController.jumpToPage(6);

    try {
      await Future.wait([
        _generateRoutine(),
        Future.delayed(const Duration(milliseconds: 2200)),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResult = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    isEn =
        Provider.of<LanguageProvider>(context, listen: false).languageCode ==
        "en";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // On utilise une icône de fermeture (X) ou on garde la flèche si tu préfères,
          // mais le "X" indique mieux qu'on va "Quitter"
          icon: const Icon(Icons.close, color: Colors.black54, size: 22),
          onPressed: () {
            // On ferme simplement l'écran du quiz pour revenir à l'accueil de Veloria
            Navigator.pop(context);
          },
        ),
        title: LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: Colors.pink[50],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.pink),
        ),
      ),
      // 1. On enlève le SingleChildScrollView qui bloque le PageView
      // 2. On ajuste la structure pour que le Stack soit bien fermé
      body: SizedBox(
        height:
            MediaQuery.of(context).size.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.top,
        child: Stack(
          children: [
            // 1. Ton PageView
            AnimatedOpacity(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              opacity: _isJumping ? 0.0 : 1.0,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCategoryStep(),
                  _buildProfileStep(),
                  _buildHairScalpStep(),
                  _buildHairHistoryStep(),
                  _buildGoalStep(),
                  _buildImperfectionTypeStep(),
                  _buildResultStep(),
                ],
              ),
            ),

            // 2. ÉCRAN DE CHARGEMENT (Placé dans le Stack, après le PageView)
            if (_isLoadingResult)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.92),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _q(
                            "Analyse de vos réponses...",
                            "Analyzing your answers...",
                            "تحليل إجاباتك...",
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.pink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _q(
                            "Nous préparons votre routine sur-mesure",
                            "We are preparing your custom routine",
                            "نحضّر روتينك المخصص",
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),

      bottomNavigationBar:
          (currentStep == 6 &&
              results.isNotEmpty &&
              !_isLoadingResult &&
              !isLoading)
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _q("Total Routine", "Total Routine", "مجموع الروتين"),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          AppText.formatPrice(
                            Provider.of<LanguageProvider>(
                              context,
                              listen: false,
                            ).languageCode,
                            results.fold<double>(
                              0.0,
                              (sum, item) =>
                                  sum +
                                  (double.tryParse(item['price'].toString()) ??
                                      0),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Dans ton Row du bottomNavigationBar
                    const SizedBox(width: 15), // Un peu d'espace avec le prix
                    Expanded(
                      child: SizedBox(
                        height:
                            65, // FIXE : Force la hauteur du bouton (ajuste entre 40 et 50)
                        child: ShakeButton(
                          onPressed: _addAllToCart,
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              disabledBackgroundColor: Colors.pink,
                              disabledForegroundColor: Colors.white,
                              elevation:
                                  0, // Plat c'est souvent plus joli quand c'est petit
                              padding: EdgeInsets
                                  .zero, // On enlève tout le padding interne
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _q(
                                "JE VEUX CETTE ROUTINE",
                                "I WANT THIS ROUTINE",
                                "أريد هذا الروتين",
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _addAllToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Gestion erreur connexion
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid);

    try {
      // 1. Récupérer le panier actuel
      final cartDoc = await cartRef.get();
      List<Map<String, dynamic>> items = [];
      String currentStatus = '';

      if (cartDoc.exists) {
        items = List<Map<String, dynamic>>.from(cartDoc.data()?['items'] ?? []);
        currentStatus = cartDoc.data()?['status'] ?? '';
      }

      // 2. Boucler sur les résultats du quiz
      for (var product in results) {
        final String cartItemId = product['id'];
        final index = items.indexWhere((i) => i['cartItemId'] == cartItemId);

        if (index >= 0) {
          items[index]['quantity'] += 1;
        } else {
          items.add({
            'cartItemId': cartItemId,
            'productId': product['id'],
            'title': product['title'],
            'title_en': product['title_en'] ?? product['title'],
            'title_ar': product['title_ar'] ?? product['title'],
            'brand': product['brand'] ?? '',
            'price': double.tryParse(product['price'].toString()) ?? 0.0,
            'costPrice':
                double.tryParse(product['costPrice']?.toString() ?? '0') ?? 0.0,
            'quantity': 1,
            'imageUrl': product['imageUrl'] ?? '',
            'variantName': "",
            'variantNameEn': "",
          });
        }
      }

      // 3. Mise à jour Firestore (Une seule fois !)
      await cartRef.set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': (currentStatus == '' || currentStatus == 'ordered')
            ? 'initiated'
            : currentStatus,
      }, SetOptions(merge: true));

      // 4. Mettre à jour le badge du panier (CartController)
      // On ajoute le nombre de nouveaux produits uniques
      for (int i = 0; i < results.length; i++) {
        context.read<CartController>().increment();
      }

      // 5. Feedback de succès
      // 5. Feedback de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _q(
                "Routine complète ajoutée !",
                "Full routine added!",
                "تمت إضافة الروتين الكامل!",
              ),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            // --- CHANGEMENT DE COULEUR ---
            backgroundColor: Colors.grey[900], // Un gris anthracite élégant
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(
              15,
            ), // Pour qu'elle ne touche pas les bords
            action: SnackBarAction(
              label: _q("VOIR", "VIEW", "عرض"),
              // On met le texte du bouton en rose pour le rappel de marque
              textColor: Colors.pink[200],
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur ajout global: $e");
    }
  }
  // --- LES ÉTAPES DE L'INTERFACE GRAPHIQUE ---

  Widget _buildCategoryStep() {
    return _buildSelectionGrid(
      title: _q(
        "Quel univers t'intéresse ?",
        "Which universe interests you?",
        "أي عالم يهمك؟",
      ),
      options: [
        {
          'title': _q('Soins visage', 'Face care', 'العناية بالوجه'),
          'icon': Icons.face,
          'value': 'soins_visage',
        },
        {
          'title': _q('Cheveux', 'Hair care', 'العناية بالشعر'),
          'icon': Icons.content_cut,
          'value': 'cheveux',
        },
        {
          'title': _q('Soins corps', 'Body care', 'العناية بالجسم'),
          'icon': Icons.accessibility,
          'value': 'soins_corps',
        },
        {
          'title': _q('Maquillage', 'Makeup', 'المكياج'),
          'icon': Icons.auto_awesome,
          'value': 'maquillage',
        },
      ],
      onSelect: (val) {
        // Au lieu de passer le 'title' (qui change selon la langue), on cherche la 'value' technique stable
        final selectedOption = [
          {
            'title': _q('Soins visage', 'Face care', 'العناية بالوجه'),
            'value': 'soins_visage',
          },
          {
            'title': _q('Cheveux', 'Hair care', 'العناية بالشعر'),
            'value': 'cheveux',
          },
          {
            'title': _q('Soins corps', 'Body care', 'العناية بالجسم'),
            'value': 'soins_corps',
          },
          {
            'title': _q('Maquillage', 'Makeup', 'المكياج'),
            'value': 'maquillage',
          },
        ].firstWhere((element) => element['title'] == val);

        setState(() => selectedCategory = selectedOption['value']);
        _nextStep();
      },
    );
  }

  String getTranslatedBadge(String? value, bool isEn) {
    if (value == null || value.isEmpty) return '';
    if (value.contains('&')) {
      return value
          .split('&')
          .map((part) => _badgeText(part.trim()))
          .join(' & ');
    }
    return _badgeText(value);
  }

  Widget _buildMemoryScreen({
    required String details,
    required VoidCallback onContinue,
    required VoidCallback onChange,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône stylisée avec un fond doux
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.pink, size: 50),
          ),
          const SizedBox(height: 30),

          // Titre
          Text(
            _q(
              "Heureuse de vous revoir !",
              "Welcome back, beautiful!",
              "سعيدة بعودتك!",
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Texte de description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: _q(
                    "Nous avons gardé votre profil ",
                    "We kept your ",
                    "احتفظنا بملفك ",
                  ),
                ),
                TextSpan(
                  // 🟢 ON APPLIQUE LA TRADUCTION ICI
                  text: getTranslatedBadge(
                    details,
                    isEn,
                  ), // 🟢 On rajoute isEn ici
                  style: const TextStyle(
                    color: Colors.pink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: _q(
                    " en mémoire pour vous.",
                    " profile ready for you.",
                    " جاهزاً لك.",
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Bouton Continuer (Action principale)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onContinue,
              child: Text(
                _q(
                  "CONTINUER AVEC CE PROFIL",
                  "CONTINUE WITH THIS PROFILE",
                  "المتابعة بهذا الملف",
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton Modifier (Action secondaire)
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
            child: Text(
              _q(
                "Modifier mes informations",
                "Change profile",
                "تعديل معلوماتي",
              ),
              style: const TextStyle(
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToStep(int pageIndex) {
    if (!_pageController.hasClients) return;

    final int previousStep = currentStep;
    if (previousStep == pageIndex) return;

    // Si on va vers la page de résultats, on passe par le loader unique.
    if (pageIndex == 6) {
      _goToResultWithLoader();
      return;
    }

    // Code de transition classique pour les autres pages (0 à 4)
    int difference = (pageIndex - previousStep).abs();
    if (difference > 1) {
      setState(() {
        _isJumping = true;
        currentStep = pageIndex;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _pageController.jumpToPage(pageIndex);
        Future.delayed(const Duration(milliseconds: 30), () {
          if (mounted) setState(() => _isJumping = false);
        });
      });
    } else {
      setState(() => currentStep = pageIndex);
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // --- ÉTAPE 2 : PROFIL CORRIGÉE ---
  Widget _buildProfileStep() {
    String normCategory = _normalizeTag(selectedCategory ?? "");

    // --- LOGIQUE DE RAPPEL CHEVEUX ---
    if (normCategory.contains("cheveux")) {
      if (hairTexture != null && selectedProfile == null) {
        String details = hairTexture!;
        if (hairState != null) details += " & $hairState";

        return _buildMemoryScreen(
          details: details,
          onContinue: () {
            setState(() {
              selectedProfile = hairTexture;
              selectedSecondary = hairState;
            });
            _jumpToStep(3);
          },
          onChange: () => setState(() {
            hairTexture = null;
            hairState = null;
          }),
        );
      }
    }

    // --- LOGIQUE DE RAPPEL VISAGE ---
    if (normCategory.contains("soins_visage") &&
        skinType != null &&
        selectedProfile == null) {
      return _buildMemoryScreen(
        details: skinType!,
        onContinue: () {
          setState(() => selectedProfile = skinType);
          _jumpToStep(4);
        },
        onChange: () => setState(() => skinType = null),
      );
    }

    String title = "";
    List<Map<String, dynamic>> options = [];

    if (normCategory.contains("soins_visage") ||
        normCategory.contains("face")) {
      title = _q("Ton type de peau ?", "Your skin type?", "ما نوع بشرتك؟");
      options = [
        {
          'title': _q('Normale', 'Normal', 'عادية'),
          'tag': 'normale',
          'icon': Icons.check_circle_outline,
        },
        {
          'title': _q('Sèche', 'Dry', 'جافة'),
          'tag': 'sèche',
          'icon': Icons.water_drop_outlined,
        },
        {
          'title': _q('Grasse', 'Oily', 'دهنية'),
          'tag': 'grasse',
          'icon': Icons.opacity,
        },
        {
          'title': _q('Mixte', 'Combination', 'مختلطة'),
          'tag': 'mixte',
          'icon': Icons.waves,
        },
      ];
    } else if (normCategory.contains("cheveux") ||
        normCategory.contains("hair")) {
      title = _q(
        "Structure de tes cheveux ?",
        "Your hair structure?",
        "ما طبيعة شعرك؟",
      );
      options = [
        {
          'title': _q('Lisses', 'Straight', 'أملس'),
          'tag': 'lisses',
          'icon': Icons.segment,
        },
        {
          'title': _q('Ondulés', 'Wavy', 'مموج'),
          'tag': 'ondulés',
          'icon': Icons.gesture,
        },
        {
          'title': _q('Bouclés', 'Curly', 'كيرلي'),
          'tag': 'bouclés',
          'icon': Icons.all_inclusive,
        },
        {
          'title': _q('Frisés', 'Coily', 'مجعد'),
          'tag': 'frisés',
          'icon': Icons.texture,
        },
        {
          'title': _q('Crépus', 'Kinky', 'أفرو'),
          'tag': 'crépus',
          'icon': Icons.grain,
        },
      ];
    } else if (normCategory.contains("soins_corps") ||
        normCategory.contains("body")) {
      title = _q(
        "Type de peau (Corps) ?",
        "Your skin type?",
        "ما نوع بشرة جسمك؟",
      );
      options = [
        {
          'title': _q('Normale', 'Normal', 'عادية'),
          'tag': 'normale',
          'icon': Icons.check_circle_outline,
        },
        {
          'title': _q('Sèche', 'Dry', 'جافة'),
          'tag': 'sèche',
          'icon': Icons.water_drop_outlined,
        },
        {
          'title': _q('Très sèche', 'Very Dry', 'جافة جداً'),
          'tag': 'très_sèche',
          'icon': Icons.warning_amber_rounded,
        },
      ];
    } else if (normCategory.contains("maquillage") ||
        normCategory.contains("makeup")) {
      title = _q(
        "Que cherches-tu ?",
        "What are you looking for?",
        "ماذا تبحثين عنه؟",
      );
      options = [
        {
          'title': _q('Teint', 'Complexion', 'البشرة'),
          'tag': 'teint',
          'icon': Icons.face_retouching_natural,
        },
        {
          'title': _q('Yeux', 'Eyes', 'العيون'),
          'tag': 'yeux',
          'icon': Icons.remove_red_eye_outlined,
        },
        {
          'title': _q('Lèvres', 'Lips', 'الشفاه'),
          'tag': 'lèvres',
          'icon': Icons.auto_fix_high,
        },
      ];
    } else {
      title = _q("Ta préférence", "Your preference", "تفضيلك");
      options = [
        {
          'title': _q('Normale', 'Normal', 'عادية'),
          'tag': 'normale',
          'icon': Icons.face,
        },
        {
          'title': _q('Sensible', 'Sensitive', 'حساسة'),
          'tag': 'sensible',
          'icon': Icons.auto_awesome_motion,
        },
      ];
    }

    return _buildSelectionGrid(
      title: title,
      options: options,
      onSelect: (val) {
        // 🌟 CORRECTION CRUCIALE : On récupère le tag technique associé au titre sélectionné
        final selectedOption = options.firstWhere(
          (opt) => opt['title'] == val,
          orElse: () => {'tag': _normalizeTag(val)},
        );
        String techTag = selectedOption['tag'];

        setState(() => selectedProfile = techTag);

        if (normCategory.contains("soins_visage")) {
          skinType = techTag;
          _saveToFirestore('skinType', techTag);
          _jumpToStep(4); // 🔴 CORRIGÉ : Le visage va à l'étape Goal (Index 4)
        } else if (normCategory.contains("soins_corps")) {
          _saveToFirestore('bodyType', techTag);
          _jumpToStep(4); // 🔴 CORRIGÉ : Le corps va à l'étape Goal (Index 4)
        } else if (normCategory.contains("maquillage")) {
          _jumpToStep(
            4,
          ); // 🔴 CORRIGÉ : Le maquillage va à l'étape Goal (Index 4)
        } else if (normCategory.contains("cheveux")) {
          hairTexture = techTag;
          _saveToFirestore('hairTexture', techTag);
          _jumpToStep(
            2,
          ); // 🟢 CORRIGÉ : Les cheveux vont au Cuir Chevelu (Index 2)
        }
      },
    );
  }

  // --- ÉTAPE SUPPLÉMENTAIRE CHEVEUX ---
  // --- ÉTAPE DU CUIR CHEVELU (SÉLECTION UNIQUE) ---
  Widget _buildHairScalpStep() {
    final List<Map<String, dynamic>> statusOptions = [
      {
        'title': _q('Secs', 'Dry', 'جافة'),
        'icon': Icons.warning_amber_outlined,
        'tag': 'secs',
      },
      {
        'title': _q('Normaux', 'Normal', 'عادية'),
        'icon': Icons.check_circle_outline,
        'tag': 'normaux',
      },
      {
        'title': _q('Gras', 'Oily', 'دهنية'),
        'icon': Icons.opacity,
        'tag': 'gras',
      },
      {
        'title': _q('Mixtes', 'Combination', 'مختلطة'),
        'icon': Icons.contrast,
        'tag': 'mixtes',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _q(
              "Comment est ton cuir chevelu ?",
              "How is your scalp?",
              "كيف هي فروة رأسك؟",
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: statusOptions.length,
            itemBuilder: (context, index) {
              final opt = statusOptions[index];
              final bool isSelected = selectedSecondary == opt['tag'];

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedSecondary = opt['tag'];
                    hairState = opt['title'];
                  });
                  _saveToFirestore('hairState', opt['tag']);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.pink[50]
                        : Colors.pink[50]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? Colors.pink : Colors.pink[100]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        opt['icon'],
                        color: isSelected ? Colors.pink : Colors.pink[300],
                        size: 26,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opt['title'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.pink[700] : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // Bouton simple qui pousse vers l'étape des antécédents
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedSecondary != null
                    ? Colors.pink
                    : Colors.pink[100],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: selectedSecondary != null
                  ? () {
                      debugPrint(
                        "➡️ Cuir chevelu sélectionné -> Passage aux antécédents (Index 3).",
                      );
                      _jumpToStep(
                        3,
                      ); // 🟢 CORRIGÉ : Direction stricte vers l'index 3
                    }
                  : null,
              child: Text(
                _q("CONTINUER", "CONTINUE", "متابعة"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ÉTAPE DES ANTÉCÉDENTS ET LONGUEURS (SÉLECTIONS MULTIPLES & ROUTAGE) ---
  Widget _buildHairHistoryStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _q(
              "Tes longueurs & antécédents :",
              "Your lengths & history:",
              "أطراف شعرك وتاريخه:",
            ),
            style: const TextStyle(
              fontSize:
                  20, // Légèrement augmenté car c'est un titre de page principal maintenant
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Checkbox Abîmés
          CheckboxListTile(
            title: Text(
              _q("Abîmés / Cassants", "Damaged / Brittle hair", "تالف / يتكسر"),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            secondary: Icon(
              Icons.heart_broken_outlined,
              color: isHairDamaged ? Colors.pink : Colors.pink[200],
            ),
            value: isHairDamaged,
            activeColor: Colors.pink,
            onChanged: (bool? value) {
              setState(() => isHairDamaged = value ?? false);
              _saveToFirestore('isHairDamaged', isHairDamaged.toString());
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.pink[50]?.withOpacity(0.15),
          ),
          const SizedBox(height: 10),

          // Checkbox Colorés
          CheckboxListTile(
            title: Text(
              _q(
                "Colorés / Méchés",
                "Color-treated / Highlights",
                "مصبوغ / فيه هايلايت",
              ),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            secondary: Icon(
              Icons.color_lens_outlined,
              color: isHairColored ? Colors.pink : Colors.pink[200],
            ),
            value: isHairColored,
            activeColor: Colors.pink,
            onChanged: (bool? value) {
              setState(() {
                isHairColored = value ?? false;
                if (!isHairColored) {
                  isBlonde = false;
                  blondeRoutinePreference = null;
                }
              });
              _saveToFirestore('isHairColored', isHairColored.toString());
              _scrollToBottom();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.pink[50]?.withOpacity(0.15),
          ),

          // CONDITIONNEL : Si coloré -> Blond ?
          if (isHairColored) ...[
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: SwitchListTile(
                title: Text(
                  _q(
                    "S'agit-il d'un blond / décoloration ?",
                    "Is it blonde / bleached?",
                    "هل هو أشقر أو مفتّح؟",
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                value: isBlonde,
                activeColor: Colors.pink,
                onChanged: (bool value) {
                  setState(() {
                    isBlonde = value;
                    if (!isBlonde) blondeRoutinePreference = null;
                  });
                  _saveToFirestore('isBlonde', isBlonde.toString());
                  _scrollToBottom();
                },
              ),
            ),
          ],

          // CONDITIONNEL : Si blond -> Choix Routine
          if (isBlonde) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.pink[100]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _q(
                      "Quel type de routine préfères-tu ?",
                      "What type of routine do you want?",
                      "أي نوع روتين تفضلين؟",
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RadioListTile<String>(
                    title: Text(
                      _q(
                        "Déjaunissante (Soins Violets)",
                        "Anti-yellowing (Purple routine)",
                        "إزالة الاصفرار (روتين بنفسجي)",
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: "violet",
                    groupValue: blondeRoutinePreference,
                    activeColor: Colors.pink,
                    onChanged: (val) {
                      setState(() => blondeRoutinePreference = val);
                      _scrollToBottom();
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(
                      _q(
                        "Entretien régulier / Nourrissant",
                        "Regular nourishing care",
                        "عناية عادية ومغذية",
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: "regular",
                    groupValue: blondeRoutinePreference,
                    activeColor: Colors.pink,
                    onChanged: (val) {
                      setState(() => blondeRoutinePreference = val);
                      _scrollToBottom();
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // La tour de contrôle : Redirection intelligente au clic
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors
                    .pink, // Toujours cliquable car les choix ici sont optionnels (on peut n'avoir aucun antécédent)
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                debugPrint(
                  "⚡ [VELORIA ACTION] Clic sur CONTINUER (Étape Antécédents)",
                );

                if (isHairColored || isHairDamaged) {
                  debugPrint(
                    "⏭️ Cheveux Colorés/Abîmés. Saut automatique vers Résultat (Index 6).",
                  );
                  _goToResultWithLoader();
                } else {
                  debugPrint(
                    "➡️ Cheveux naturels & sains. Passage à l'étape Objectif (Index 4).",
                  );
                  _jumpToStep(
                    4,
                  ); // 🟢 CORRIGÉ : Direction l'étape Goal pour les cheveux
                }
              },
              child: Text(
                _q("CONTINUER", "CONTINUE", "متابعة"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- ÉTAPE 3 : OBJECTIF ---
  Widget _buildGoalStep() {
    String title = _q(
      "Quel est ton objectif ?",
      "What is your goal?",
      "ما هدفك؟",
    );
    List<Map<String, dynamic>> options = [];

    String normCategory = _normalizeTag(selectedCategory ?? "");
    String normProfile = _normalizeTag(selectedProfile ?? "");

    if (normCategory.contains("soins_visage") ||
        normCategory.contains("face")) {
      options = [
        {
          'title': _q('Hydratation', 'Hydration', 'ترطيب'),
          'tag': 'hydratation',
          'icon': Icons.water,
        },
        {
          'title': _q('Anti-imperfections', 'Anti-imperfections', 'ضد الشوائب'),
          'tag': 'anti-imperfections',
          'icon': Icons.cleaning_services,
        },
        {
          'title': _q('Éclat', 'Radiance', 'إشراقة'),
          'tag': 'éclat',
          'icon': Icons.lightbulb_outline,
        },
        {
          'title': _q('Anti-âge', 'Anti-aging', 'مضاد للتقدم في السن'),
          'tag': 'anti-âge',
          'icon': Icons.history,
        },
        {
          'title': _q('Apaisant', 'Soothing', 'تهدئة'),
          'tag': 'Apaisant',
          'icon': Icons.shield_outlined,
        },
      ];
    } else if (normCategory.contains("cheveux") ||
        normCategory.contains("hair")) {
      options = [
        {
          'title': _q('Hydratation', 'Hydration', 'ترطيب'),
          'tag': 'hydratation',
          'icon': Icons.water_drop,
        },
        {
          'title': _q('Réparation', 'Repair', 'ترميم'),
          'tag': 'réparation',
          'icon': Icons.build,
        },
        {
          'title': _q('Brillance', 'Shine', 'لمعان'),
          'tag': 'brillance',
          'icon': Icons.star_border,
        },
        {
          'title': _q('Anti-chute', 'Anti-hair loss', 'ضد التساقط'),
          'tag': 'anti-chute',
          'icon': Icons.do_not_disturb_on_total_silence,
        },
        {
          'title': _q('Volume', 'Volume', 'حجم'),
          'tag': 'volume',
          'icon': Icons.waves,
        },
      ];
    } else if (normCategory.contains("soins_corps") ||
        normCategory.contains("body")) {
      options = [
        {
          'title': _q(
            'Hydrater et adoucir ma peau',
            'Hydrate & Soften',
            'ترطيب وتنعيم بشرتي',
          ),
          'tag': 'hydratation',
          'icon': Icons.spa_outlined,
        },
        {
          'title': _q(
            'Apaiser les tiraillements',
            'Soothe tightness',
            'تهدئة الشد',
          ),
          'tag': 'apaisant',
          'icon': Icons.health_and_safety_outlined,
        },
        {
          'title': _q(
            'Juste entretenir ma peau',
            'Daily maintenance',
            'عناية يومية فقط',
          ),
          'tag': 'entretenir',
          'icon': Icons.favorite_border_rounded,
        },
      ];
    } else if (normCategory.contains("maquillage") ||
        normCategory.contains("makeup")) {
      if (normProfile.contains("teint") || normProfile.contains("complexion")) {
        title = _q(
          "Quel fini recherches-tu ?",
          "Which finish?",
          "أي لمسة نهائية تريدين؟",
        );
        options = [
          {
            'title': _q(
              'Naturel & Lumineux',
              'Natural & Luminous',
              'طبيعي ومشرق',
            ),
            'tag': 'lumineux',
            'icon': Icons.wb_sunny_outlined,
          },
          {
            'title': _q('Couvrance Moyenne', 'Medium Coverage', 'تغطية متوسطة'),
            'tag': 'couvrance_moyenne',
            'icon': Icons.filter_none_outlined,
          },
          {
            'title': _q('Haute Couvrance', 'High Coverage', 'تغطية عالية'),
            'tag': 'haute_couvrance',
            'icon': Icons.layers_outlined,
          },
          {
            'title': _q(
              'Mat / Sans brillance',
              'Matte / Shine-free',
              'مطفي بدون لمعان',
            ),
            'tag': 'mat',
            'icon': Icons.vignette_outlined,
          },
        ];
      } else if (normProfile.contains("yeux") || normProfile.contains("eyes")) {
        title = _q(
          "Quel effet souhaites-tu ?",
          "Which effect?",
          "أي تأثير تريدين؟",
        );
        options = [
          {
            'title': _q('Intense', 'Intense', 'قوي'),
            'tag': 'intense',
            'icon': Icons.remove_red_eye,
          },
          {
            'title': _q('Naturel', 'Natural', 'طبيعي'),
            'tag': 'naturel',
            'icon': Icons.visibility_outlined,
          },
          {
            'title': _q('Waterproof', 'Waterproof', 'مقاوم للماء'),
            'tag': 'waterproof',
            'icon': Icons.water_drop_outlined,
          },
        ];
      } else if (normProfile.contains("lèvres") ||
          normProfile.contains("lips")) {
        title = _q(
          "Quelle texture préfères-tu ?",
          "Which texture?",
          "أي قوام تفضلين؟",
        );
        options = [
          {
            'title': _q('Brillant / Glossy', 'Glossy', 'لامع / غلوسي'),
            'tag': 'glossy',
            'icon': Icons.auto_awesome,
          },
          {
            'title': _q('Mat / Sans transfert', 'Matte', 'مطفي بدون انتقال'),
            'tag': 'mat',
            'icon': Icons.format_color_fill,
          },
          {
            'title': _q(
              'Baume teinté hydratant',
              'Tinted balm',
              'بلسم ملون مرطب',
            ),
            'tag': 'baume_teinte',
            'icon': Icons.spa_outlined,
          },
        ];
      }
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                return InkWell(
                  onTap: () {
                    String selectedTag = opt['tag'] as String;
                    setState(() => selectedGoal = selectedTag);

                    String normCat = _normalizeTag(selectedCategory ?? "");

                    if (normCat.contains("soins_visage") &&
                        selectedTag == "anti-imperfections") {
                      debugPrint(
                        "🎯 Direction stricte Étape Imperfections (Index 5)",
                      );

                      // 🟢 CORRECTION : On met d'abord à jour l'index de l'étape pour verrouiller l'affichage
                      setState(() {
                        currentStep = 5;
                      });

                      // Puis on lance l'animation de transition
                      _pageController.animateToPage(
                        5,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      debugPrint(
                        "➡️ Objectif classique -> Calcul de la routine et saut final (Index 6)",
                      );
                      _goToResultWithLoader();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 35,
                          color: Colors.pink,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          opt['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  //étape supllementaire anti-imperfections
  // --- ÉTAPE ANTI-IMPERFECTIONS CORRIGÉE ---
  Widget _buildImperfectionTypeStep() {
    String normCat = _normalizeTag(selectedCategory ?? "");
    String normGoal = _normalizeTag(selectedGoal ?? "");

    if (!normCat.contains("soins_visage") &&
        !normGoal.contains("imperfection")) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Ajout d'une clé 'tag' technique stable pour éviter les soucis de traduction
    final List<Map<String, dynamic>> imperfectionOptions = [
      {
        'title': _q('Boutons & Acné', 'Pimple & Acne', 'حبوب وحب الشباب'),
        'tag': 'boutons',
        'icon': Icons.gpp_bad_outlined,
      },
      {
        'title': _q('Taches & Cicatrices', 'Dark Spots & Marks', 'بقع وآثار'),
        'tag': 'taches',
        'icon': Icons.blur_on,
      },
    ];

    return _buildSelectionGrid(
      title: _q(
        "Que veux-tu cibler en priorité ?",
        "What do you want to target primarily?",
        "ما الذي تريدين استهدافه أولاً؟",
      ),
      options: imperfectionOptions,
      onSelect: (val) {
        // 🌟 Récupération propre via le dictionnaire technique
        final selectedOption = imperfectionOptions.firstWhere(
          (opt) => opt['title'] == val,
          orElse: () => {'tag': 'boutons'},
        );

        String techTag = selectedOption['tag'];

        setState(() => selectedImperfectionType = techTag);

        _goToResultWithLoader();
      },
    );
  }

  // Petit helper pour obtenir le titre éducatif de l'étape de manière dynamique
  Map<String, String> _getStepEducation(String type, String categoryLower) {
    String typeLower = type.toLowerCase().trim();

    // --- UNIVERS VISAGE ---
    if (categoryLower.contains("soins_visage") ||
        categoryLower.contains("face")) {
      if (typeLower.contains("nettoyant")) {
        return {"num": "1", "action": _q("1. NETTOYER", "CLEANSE", "1. تنظيف")};
      }
      if (typeLower.contains("sérum") || typeLower.contains("serum")) {
        return {
          "num": "2",
          "action": _q(
            "2. TRAITER (STAR ✨)",
            "TREAT (STAR ✨)",
            "2. علاج (الأهم ✨)",
          ),
        };
      }
      if (typeLower.contains("crème") || typeLower.contains("creme")) {
        return {"num": "3", "action": _q("3. HYDRATER", "HYDRATE", "3. ترطيب")};
      }
    }

    // --- UNIVERS CHEVEUX ---
    if (categoryLower.contains("cheveux") || categoryLower.contains("hair")) {
      if (typeLower.contains("shampooing")) {
        return {"num": "1", "action": _q("1. LAVER", "WASH", "1. غسل")};
      }
      if (typeLower.contains("masque") ||
          typeLower.contains("après-shampooing")) {
        return {
          "num": "2",
          "action": _q(
            "2. SOIGNER (STAR ✨)",
            "DEEP CARE (STAR ✨)",
            "2. عناية عميقة (الأهم ✨)",
          ),
        };
      }
      if (typeLower.contains("sérum/huile") ||
          typeLower.contains("huile") ||
          typeLower.contains("serum")) {
        return {
          "num": "3",
          "action": _q("3. SUBLIMER", "PROTECT", "3. حماية ولمعان"),
        };
      }
    }

    // --- MAQUILLAGE / CORPS TRADUCTION DES TYPES PAR DÉFAUT ---
    const Map<String, String> typeLabelsFr = {
      "encres à lèvres": "Encre à lèvres",
      "encres a levres": "Encre à lèvres",
    };

    String actionLabel = (typeLabelsFr[typeLower] ?? type).toUpperCase();
    if (isEn || isAr) {
      final Map<String, String> typeTranslations = isAr
          ? {
              "fond de teint": "فاونديشن",
              "base": "برايمر",
              "primer": "برايمر",
              "anti-cerne": "كونسيلر",
              "anti-cernes": "كونسيلر",
              "poudre": "بودرة",
              "blush": "بلاشر",
              "highlighter": "هايلايتر",
              "highligher": "هايلايتر",
              "mascara": "ماسكارا",
              "eyeliner": "آيلاينر",
              "sourcils": "الحواجب",
              "soucils": "الحواجب",
              "palettes": "باليت",
              "palette": "باليت",
              "crayon à lèvres": "قلم شفاه",
              "crayon a levres": "قلم شفاه",
              "rouge à lèvres": "أحمر شفاه",
              "rouge a levres": "أحمر شفاه",
              "gloss": "غلوس",
              "baume": "بلسم شفاه",
              "encre à lèvres": "تينت شفاه",
              "encre a levres": "تينت شفاه",
              "encres à lèvres": "تينت شفاه",
              "encres a levres": "تينت شفاه",
              "contour/bronzer": "كونتور/برونزر",
              "contour": "كونتور",
              "bronzer": "برونزر",
              "gel douche": "جل استحمام",
              "gommage": "مقشر جسم",
              "lait corporel": "لوشن جسم",
              "crème corps": "كريم جسم",
              "creme corps": "كريم جسم",
              "lotion": "لوشن",
              "déodorant": "مزيل عرق",
              "deodorant": "مزيل عرق",
              "shampooing": "شامبو",
              "masque": "ماسك",
              "après-shampooing": "بلسم",
              "apres-shampooing": "بلسم",
              "sérum/huile": "سيروم/زيت",
              "serum/huile": "سيروم/زيت",
              "huile": "زيت",
            }
          : {
              "fond de teint": "FOUNDATION",
              "base": "PRIMER",
              "primer": "PRIMER",
              "anti-cerne": "CONCEALER",
              "anti-cernes": "CONCEALER",
              "poudre": "POWDER",
              "blush": "BLUSH",
              "highlighter": "HIGHLIGHTER",
              "highligher": "HIGHLIGHTER",
              "mascara": "MASCARA",
              "eyeliner": "EYELINER",
              "sourcils": "EYEBROWS",
              "soucils": "EYEBROWS",
              "palettes": "PALETTES",
              "palette": "PALETTE",
              "crayon à lèvres": "LIP LINER",
              "crayon a levres": "LIP LINER",
              "rouge à lèvres": "LIPSTICK",
              "rouge a levres": "LIPSTICK",
              "gloss": "GLOSS",
              "baume": "LIP BALM",
              "encre à lèvres": "LIP TINT",
              "encre a levres": "LIP TINT",
              "encres à lèvres": "LIP TINT",
              "encres a levres": "LIP TINT",
              "contour/bronzer": "CONTOUR/BRONZER",
              "contour": "CONTOUR",
              "bronzer": "BRONZER",
              "gel douche": "BODY WASH",
              "gommage": "BODY SCRUB",
              "lait corporel": "BODY LOTION",
              "crème corps": "BODY CREAM",
              "creme corps": "BODY CREAM",
              "lotion": "LOTION",
              "déodorant": "DEODORANT",
              "deodorant": "DEODORANT",
              "shampooing": "SHAMPOO",
              "masque": "MASK",
              "après-shampooing": "CONDITIONER",
              "apres-shampooing": "CONDITIONER",
              "sérum/huile": "SERUM/OIL",
              "serum/huile": "SERUM/OIL",
              "huile": "OIL",
            };
      actionLabel = typeTranslations[typeLower] ?? type.toUpperCase();
    }

    return {"num": "", "action": actionLabel, "desc": ""};
  }

  // --- NOUVEL ÉCRAN DE RÉSULTAT OPTIMISÉ POUR LA CONVERSION ---
  Widget _buildResultStep() {
    // ==========================================
    // CAS 1 : EN COURS DE GÉNÉRATION (EFFET CHRONO DURANT 2.5s)
    // ==========================================
    if (_isLoadingResult || isLoading) {
      return const SizedBox.expand();
    }

    // ==========================================
    // CAS 2 : AUCUN RÉSULTAT DETECTÉ (SÉCURITÉ ÉCRAN BLANC)
    // ==========================================
    // Si le chargement est fini et que la liste de résultats est vide, on affiche le message directement
    if (!isLoading && results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.pink,
              ),
              const SizedBox(height: 16),
              Text(
                _q(
                  "Aucune routine détectée",
                  "No routine detected",
                  "لم يتم العثور على روتين",
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _q(
                  "Nous n'avons pas trouvé de produits correspondants exactement à tes critères. Essaie de modifier tes réponses.",
                  "We couldn't find products matching your criteria. Try changing your answers.",
                  "لم نجد منتجات تطابق اختياراتك تماماً. جرّبي تعديل إجاباتك.",
                ),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Optionnel : Réinitialise tes variables de quiz ici si nécessaire
                  _jumpToStep(0); // Retour à la première étape du quiz
                },
                child: Text(
                  _q("Recommencer", "Retry", "إعادة المحاولة"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // ==========================================
    // CAS 3 : AFFICHAGE DE TA ROUTINE (FONCTIONNEMENT NORMAL)
    // ==========================================
    final String catLower = _normalizeTag(selectedCategory ?? "");

    String getTranslatedBadge(String? technicalTag) {
      if (technicalTag == null || technicalTag.isEmpty) {
        return _q("Profil", "Profile", "الملف");
      }
      return _badgeText(technicalTag);
    }

    return Stack(
      children: [
        // 1️⃣ CONTENU : En-tête + Liste de produits
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- EN-TÊTE AVEC RÉCAPITULATIF ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _q(
                      "Ta Routine Sur-Mesure",
                      "Your Custom Routine",
                      "روتينك المخصص",
                    ),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSmallBadge(
                        Icons.person_outline,
                        (catLower.contains("cheveux") &&
                                selectedSecondary != null &&
                                selectedProfile != null)
                            ? "${getTranslatedBadge(selectedSecondary)} & ${getTranslatedBadge(selectedProfile)}"
                            : getTranslatedBadge(selectedProfile),
                      ),
                      if (selectedGoal != null && selectedGoal!.isNotEmpty)
                        _buildSmallBadge(
                          Icons.track_changes,
                          getTranslatedBadge(selectedGoal),
                        ),
                      if (selectedImperfectionType != null)
                        _buildSmallBadge(
                          Icons.bug_report_outlined,
                          getTranslatedBadge(selectedImperfectionType),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // --- LISTE DES PRODUITS ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 95),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final data = results[index];
                  final ed = _getStepEducation(
                    data['subCategory'] ?? '',
                    catLower,
                  );
                  bool isStar = ed['num'] == "2";

                  final String displayTitle = isAr
                      ? (data['title_ar'] ?? data['title'] ?? '')
                      : isEn
                      ? (data['title_en'] ?? data['title'] ?? '')
                      : (data['title'] ?? '');

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ProductPage(product: Product.fromMap(data)),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (index == 0) _buildMemoryMessage(),

                          // CARTE PRINCIPALE
                          Container(
                            height: isStar ? 170 : 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: isStar
                                  ? Border.all(
                                      color: Colors.pink[100]!,
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isStar ? 0.08 : 0.04,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // IMAGE
                                Expanded(
                                  flex: 4,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.horizontal(
                                      left: Radius.circular(24),
                                    ),
                                    child: Image.network(
                                      data['imageUrl'] ?? '',
                                      fit: BoxFit.cover,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                // INFOS
                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            ed['action']?.toUpperCase() ?? '',
                                            style: TextStyle(
                                              color: isStar
                                                  ? Colors.pink
                                                  : Colors.grey,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            displayTitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isStar ? 16 : 14,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            AppText.formatPrice(
                                              Provider.of<LanguageProvider>(
                                                context,
                                                listen: false,
                                              ).languageCode,
                                              data['price'],
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),

                                          // BLOC SANS-SULFATES
                                          if ((data['subCategory'] ?? '')
                                              .toString()
                                              .toLowerCase()
                                              .contains('shampooing')) ...[
                                            const SizedBox(height: 4),
                                            if (List<String>.from(
                                              data['tags'] ?? [],
                                            ).contains('sans_sulfates')) ...[
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.eco_rounded,
                                                    size: 13,
                                                    color: Colors.green[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _q(
                                                      "Sans sulfates 🌿",
                                                      "Sulfate-free 🌿",
                                                      "بدون سلفات 🌿",
                                                    ),
                                                    style: TextStyle(
                                                      color: Colors.green[700],
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              InkWell(
                                                onTap: () =>
                                                    _switchToSulfateFree(
                                                      index,
                                                      data['subCategory'] ?? '',
                                                      catLower,
                                                    ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .auto_awesome_rounded,
                                                      size: 12,
                                                      color: Colors.pink[400],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _q(
                                                        "Option Sans-Sulfates ⟳",
                                                        "Sulfate-free option ⟳",
                                                        "خيار بدون سلفات ⟳",
                                                      ),
                                                      style: TextStyle(
                                                        color: Colors.pink[400],
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // BOUTON REFRESH
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              onPressed: () => _shuffleSingleProduct(
                                data['subCategory'] ?? '',
                                index,
                              ),
                              icon: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.white.withOpacity(0.9),
                                child: const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: Colors.pink,
                                ),
                              ),
                            ),
                          ),

                          // BOUTON PANIER
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: InkWell(
                              onTap: () => _addToCart(data),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isStar ? Colors.pink : Colors.black,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _switchToSulfateFree(
    int index,
    String subCategory,
    String category,
  ) async {
    // 1. On récupère les données actuelles du produit à cet index
    final currentProductData = results[index];

    // 2. On récupère ses tags existants (ex: [cheveux, frisés, secs, colorés, shampooing])
    List<String> currentTags = List<String>.from(
      currentProductData['tags'] ?? [],
    );

    // 3. On crée une liste propre et on s'assure d'y ajouter "sans_sulfates"
    List<String> sulfateFreeTags = List.from(currentTags);
    if (!sulfateFreeTags.contains("sans_sulfates")) {
      sulfateFreeTags.add("sans_sulfates");
    }

    debugPrint(
      "🌿 [VELORIA] Switch Sans-Sulfates intelligent pour l'index $index avec TOUS les tags préservés : $sulfateFreeTags",
    );

    // 4. Lancement de la recherche Firestore avec la combinaison exacte + sans_sulfates
    var matches = await _matchProducts(sulfateFreeTags);

    // 5. Mise à jour de l'état local si un produit correspond
    if (matches.isNotEmpty) {
      setState(() {
        results[index] = matches.first;
      });
    } else {
      // 🔄 RECOURS 1 : Si le match strict échoue, on tente d'enlever le tag de texture/profil
      // pour élargir la recherche tout en gardant l'univers, le type et l'état (ex: colorés)
      List<String> fallbackTags = [
        category.toLowerCase().trim(),
        "sans_sulfates",
        "shampooing",
      ];
      if (isHairColored && !isBlonde) fallbackTags.add("colorés");
      if (isHairDamaged) fallbackTags.add("réparation");

      var fallbackMatches = await _matchProducts(fallbackTags);

      // 🛡️ FILTRE DE SÉCURITÉ RECOURS 1
      fallbackMatches = fallbackMatches.where((product) {
        final productTags = List<String>.from(product['tags'] ?? []);
        if (!isHairColored && productTags.contains('colorés')) return false;
        if (!isHairDamaged &&
            (productTags.contains('abîmés') ||
                productTags.contains('réparation')))
          return false;
        return true;
      }).toList();

      if (fallbackMatches.isNotEmpty) {
        setState(() {
          results[index] = fallbackMatches.first;
        });
      } else {
        // 🔄 RECOURS 2 : Version Universelle (tout_type)
        fallbackTags.add("tout_type");
        var universalMatches = await _matchProducts(fallbackTags);

        // 🛡️ FILTRE DE SÉCURITÉ RECOURS 2 (Crucial ici à cause du tout_type)
        universalMatches = universalMatches.where((product) {
          final productTags = List<String>.from(product['tags'] ?? []);
          if (!isHairColored && productTags.contains('colorés')) return false;
          if (!isHairDamaged &&
              (productTags.contains('abîmés') ||
                  productTags.contains('réparation')))
            return false;
          return true;
        }).toList();

        if (universalMatches.isNotEmpty) {
          setState(() {
            results[index] = universalMatches.first;
          });
        } else {
          // Si vraiment aucun produit sans sulfates n'existe dans ton catalogue pour cette catégorie
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _q(
                  "Désolé, aucun shampooing sans sulfates correspondant à vos critères n'est disponible pour le moment. 🌿",
                  "Sorry, no sulfate-free shampoo matching your criteria is available right now. 🌿",
                  "عذراً، لا يوجد حالياً شامبو بدون سلفات يطابق معاييرك. 🌿",
                ),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.pink[400],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  // Widget utilitaire pour les petits badges en haut
  Widget _buildSmallBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.pink[300]),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionGrid({
    required String title,
    required List<Map<String, dynamic>> options,
    required Function(String) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.9,
              ),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                return InkWell(
                  onTap: () => onSelect(opt['title']),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.pink.withOpacity(0.1)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          opt['icon'] as IconData,
                          size: 35,
                          color: Colors.pink,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          opt['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> data) async {
    // On récupère le LanguageProvider comme dans ta fonction originale
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final bool isEn = languageProvider.languageCode == "en";

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? "Connect to add to cart"
                : isAr
                ? "سجّلي الدخول لإضافة المنتج إلى السلة"
                : "Connectez-vous pour ajouter au panier",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // On prépare les données (pas de flavor ici car c'est une recommandation auto)
    final String finalTitle = isAr
        ? (data['title_ar'] ?? data['title'])
        : isEn
        ? (data['title_en'] ?? data['title'])
        : data['title'];
    final String cartItemId = data['id']; // Simple ID car pas de variante

    // Incrément du badge du panier (si tu utilises le CartController)
    context.read<CartController>().increment();

    // SNACKBAR (Copie conforme de ton style tactile)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "$finalTitle ${isAr
                      ? 'تمت إضافته'
                      : isEn
                      ? 'added'
                      : 'ajouté'}",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
              const Icon(
                Icons.shopping_cart_checkout,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFDCDCDC),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // LOGIQUE FIRESTORE (Strictement identique à ton handleAddToCart)
    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid);
    try {
      final cartDoc = await cartRef.get();
      List<Map<String, dynamic>> items = [];
      String currentStatus = '';

      if (cartDoc.exists) {
        final fireData = cartDoc.data();
        items = List<Map<String, dynamic>>.from(fireData?['items'] ?? []);
        currentStatus = fireData?['status'] ?? '';
      }

      final index = items.indexWhere((i) => i['cartItemId'] == cartItemId);

      if (index >= 0) {
        items[index]['quantity'] += 1;
      } else {
        items.add({
          'cartItemId': cartItemId,
          'productId': data['id'],
          'title': data['title'],
          'title_en': data['title_en'] ?? data['title'],
          'title_ar': data['title_ar'] ?? data['title'],
          'brand': data['brand'] ?? '',
          'price': double.tryParse(data['price'].toString()) ?? 0.0,
          'costPrice':
              double.tryParse(data['costPrice']?.toString() ?? '0') ?? 0.0,
          'quantity': 1,
          'imageUrl': data['imageUrl'] ?? '',
          'variantName': "",
          'variantNameEn': "",
        });
      }

      await cartRef.set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
        'status':
            (currentStatus == '' ||
                currentStatus == 'ordered' ||
                currentStatus == 'empty')
            ? 'initiated'
            : currentStatus,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ [VELORIA] Erreur panier Quiz: $e");
    }
  }
}
