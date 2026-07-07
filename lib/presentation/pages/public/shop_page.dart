import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:veloria/core/i18n/app_text.dart';
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

  static const Map<String, String> _categoryLabelsAr = {
    "tous": "الكل",
    "nouveautés": "وصل جديد",
    "nouveautes": "وصل جديد",
    "new_arrivals": "وصل جديد",
    "soins visage": "العناية بالوجه",
    "soins_visage": "العناية بالوجه",
    "visage": "العناية بالوجه",
    "cheveux": "العناية بالشعر",
    "soins corps": "العناية بالجسم",
    "corps": "العناية بالجسم",
    "maquillage": "المكياج",
    "solaire": "واقيات الشمس",
    "solaires": "واقيات الشمس",
    "brume": "البخاخات",
    "brumes": "البخاخات",
    "parfum": "العطور",
    "parfums": "العطور",
    "accessoires": "الإكسسوارات",
    "packs": "المجموعات",
  };

  static const Map<String, String> _makeupSectionLabelsAr = {
    "Teint": "البشرة",
    "Yeux": "العيون",
    "Lèvres": "الشفاه",
  };

  static const Map<String, String> _subCategoryLabelsAr = {
    "fond de teint": "كريم أساس",
    "anti-cernes": "كونسيلر",
    "anti-cerne": "كونسيلر",
    "poudre": "بودرة",
    "blush": "بلاشر",
    "highlighter": "هايلايتر",
    "highligher": "هايلايتر",
    "hilighter": "هايلايتر",
    "base": "برايمر",
    "spray fixateur": "بخاخ تثبيت",
    "mascara": "ماسكارا",
    "eyeliner": "آيلاينر",
    "palettes": "باليت",
    "palette": "باليت",
    "sourcils": "الحواجب",
    "rouge à lèvres": "أحمر شفاه",
    "rouge a levres": "أحمر شفاه",
    "gloss": "غلوس",
    "crayon à lèvres": "قلم شفاه",
    "crayon a levres": "قلم شفاه",
    "encre à lèvres": "تينت شفاه",
    "encre a levres": "تينت شفاه",
    "encres à lèvres": "تينت شفاه",
    "encres a levres": "تينت شفاه",
    "nettoyant": "منظف",
    "sérum": "سيروم",
    "serum": "سيروم",
    "crème": "كريم",
    "creme": "كريم",
    "lotion": "لوشن",
    "tonique": "تونر",
    "lotion tonique": "تونر",
    "exfoliant": "مقشر",
    "exfoliation": "تقشير",
    "shampooing": "شامبو",
    "shampoing": "شامبو",
    "masque": "ماسك",
    "après-shampooing": "بلسم",
    "apres-shampooing": "بلسم",
    "sérum/huile": "سيروم/زيت",
    "serum/huile": "سيروم/زيت",
    "huile": "زيت",
    "gel douche": "جل استحمام",
    "gommage": "مقشر",
    "lait corporel": "لوشن الجسم",
    "déodorant": "مزيل عرق",
    "deodorant": "مزيل عرق",
    "protection solaire": "واقي شمس",
    "solaire": "واقي شمس",
    "contour/bronzer": "كونتور/برونزر",
    "contour": "كونتور",
    "bronzer": "برونزر",
    "baume à lèvres": "مرطب شفاه",
    "baume a levres": "مرطب شفاه",
    "baume lèvres": "مرطب شفاه",
    "baume levres": "مرطب شفاه",
    "hygiène intime": "العناية الحميمة",
    "hygiene intime": "العناية الحميمة",
    "gel intime": "غسول حميم",
    "huile sèche": "زيت جاف",
    "huile seche": "زيت جاف",
    "huile corps": "زيت للجسم",
    "crème corps": "كريم للجسم",
    "creme corps": "كريم للجسم",
    "protection visage": "حماية الوجه",
    "protection corps": "حماية الجسم",
    "après-solaire": "بعد الشمس",
    "apres-solaire": "بعد الشمس",
    "spf visage": "واقي وجه",
    "spf corps": "واقي جسم",
    "protecteur de chaleur": "واقي من الحرارة",
    "protection chaleur": "واقي من الحرارة",
    "soins sans rinçage": "عناية بدون شطف",
    "soins sans rincage": "عناية بدون شطف",
    "sans rinçage": "بدون شطف",
    "sans rincage": "بدون شطف",
    "coloration": "صبغة شعر",
    "couleur": "صبغة",
    "frisé": "للشعر المجعد",
    "frise": "للشعر المجعد",
    "frises": "للشعر المجعد",
    "bouclé": "للشعر الكيرلي",
    "boucle": "للشعر الكيرلي",
    "boucles": "للشعر الكيرلي",
    "lisse": "للشعر الناعم",
    "lisses": "للشعر الناعم",
    "fruité": "فاكهي",
    "fruite": "فاكهي",
    "floral": "زهري",
    "boisé": "خشبي",
    "boise": "خشبي",
    "sucré": "حلو",
    "sucre": "حلو",
    "oriental": "شرقي",
    "musc": "مسك",
    "vanille": "فانيلا",
  };

  String _labelKey(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r"\s+"), " ")
        .replaceAll("œ", "oe")
        .replaceAll("à", "a")
        .replaceAll("â", "a")
        .replaceAll("ä", "a")
        .replaceAll("á", "a")
        .replaceAll("ç", "c")
        .replaceAll("é", "e")
        .replaceAll("è", "e")
        .replaceAll("ê", "e")
        .replaceAll("ë", "e")
        .replaceAll("î", "i")
        .replaceAll("ï", "i")
        .replaceAll("ô", "o")
        .replaceAll("ö", "o")
        .replaceAll("ù", "u")
        .replaceAll("û", "u")
        .replaceAll("ü", "u");
  }

  CategoryData? _preloadedCategoryFor(String techName) {
    final key = _labelKey(techName).replaceAll("_", " ");
    for (final category in preloadedCategories) {
      final nameKey = _labelKey(category.name).replaceAll("_", " ");
      final idKey = _labelKey(category.id).replaceAll("_", " ");
      if (nameKey == key || idKey == key) return category;
    }
    return null;
  }

  String _categoryLabel(String techName, LanguageProvider language) {
    if (language.isAr) {
      final key = _labelKey(techName);
      if (key == "tous") return _categoryLabelsAr["tous"] ?? techName;
      if (key == "nouveautes" || key == "new_arrivals") {
        return _categoryLabelsAr["nouveautes"] ?? techName;
      }

      final category = _preloadedCategoryFor(techName);
      final arabicName = category?.name_ar.trim() ?? "";
      if (arabicName.isNotEmpty) return arabicName;

      return _categoryLabelsAr[key] ??
          _categoryLabelsAr[key.replaceAll("_", " ")] ??
          techName;
    }
    if (language.isEn) {
      final key = _labelKey(techName);
      if (key == "tous") return "All";
      if (key == "nouveautes" || key == "new_arrivals") return "New Arrivals";
      final category = _preloadedCategoryFor(techName);
      if (category != null && category.name_en.trim().isNotEmpty) {
        return category.name_en;
      }
      return techName;
    }
    return techName;
  }

  String _subCategoryLabel(SubCategoryData subObj, LanguageProvider language) {
    if (language.isAr) {
      if (subObj.name_ar.trim().isNotEmpty) return subObj.name_ar;
      final key = _labelKey(subObj.name);
      return _subCategoryLabelsAr[key] ??
          _subCategoryLabelsAr[key.replaceAll("_", " ")] ??
          subObj.name;
    }
    if (language.isEn) return subObj.name_en;
    return subObj.name;
  }

  Map<String, dynamic>? _arabicGuideFallback(String categoryName) {
    final key = _labelKey(categoryName).replaceAll('_', ' ');

    Map<String, dynamic> guide({
      required String intro,
      required List<Map<String, String>> steps,
      List<Map<String, String>> optional = const [],
      String facts = '',
    }) {
      return {
        'intro': intro,
        'steps': steps,
        'optional': optional,
        'facts': facts,
      };
    }

    if (key.contains('soins visage') || key.contains('visage')) {
      return guide(
        intro:
            'روتين الوجه لا يحتاج إلى خطوات كثيرة. الأهم هو ترتيب صحيح ومنتجات تناسب بشرتك.',
        steps: [
          {
            'title': 'منظف',
            'desc': 'يزيل الشوائب وبقايا اليوم ويحضّر البشرة لباقي الروتين.',
          },
          {
            'title': 'سيروم أو علاج',
            'desc': 'خطوة مركزة حسب الهدف: ترطيب، إشراقة، حبوب، بقع أو تهدئة.',
          },
          {
            'title': 'كريم',
            'desc': 'يرطب ويحافظ على راحة البشرة ونعومتها خلال اليوم.',
          },
          {
            'title': 'واقي شمس',
            'desc':
                'خطوة أساسية صباحاً لحماية البشرة من التصبغات وعلامات التقدم.',
          },
        ],
        optional: [
          {'title': 'ماسك', 'desc': 'دفعة إضافية عند الحاجة'},
          {'title': 'مقشر', 'desc': 'مرة إلى مرتين في الأسبوع بلطف'},
        ],
        facts:
            'البشرة تستجيب أكثر عندما يكون الروتين بسيطاً وثابتاً، لا عندما نكثر المنتجات.',
      );
    }

    if (key.contains('cheveux') || key.contains('شعر')) {
      return guide(
        intro:
            'روتين الشعر يبدأ من الفروة وينتهي بحماية الأطراف. اختاري المنتجات حسب طبيعة الشعر وحالته.',
        steps: [
          {
            'title': 'شامبو',
            'desc': 'ينظف الفروة والشعر من الزيوت والتراكمات بدون إثقال.',
          },
          {
            'title': 'ماسك أو بلسم',
            'desc': 'يساعد على تنعيم الشعر وفك التشابك ودعم الألياف.',
          },
          {
            'title': 'سيروم أو زيت',
            'desc': 'يحمي الأطراف ويضيف لمعاناً ويقلل الهيشان.',
          },
        ],
        optional: [
          {'title': 'واقي حرارة', 'desc': 'مهم قبل السشوار أو مكواة الشعر'},
          {'title': 'عناية بدون شطف', 'desc': 'مفيدة للشعر الجاف أو المجعد'},
        ],
        facts:
            'الأطراف الجافة تحتاج حماية منتظمة، والفروة الدهنية لا تعني أن الأطراف لا تحتاج ترطيباً.',
      );
    }

    if (key.contains('soins corps') || key.contains('corps')) {
      return guide(
        intro:
            'عناية الجسم هدفها تنظيف لطيف، ترطيب مستمر وراحة للبشرة بعد الاستحمام.',
        steps: [
          {
            'title': 'جل استحمام',
            'desc': 'ينظف البشرة بلطف ويتركها منتعشة بدون شد زائد.',
          },
          {
            'title': 'مقشر',
            'desc':
                'يساعد على تنعيم ملمس البشرة وإزالة الخلايا الميتة عند الحاجة.',
          },
          {
            'title': 'لوشن أو كريم جسم',
            'desc': 'يحافظ على الترطيب والنعومة بعد الاستحمام.',
          },
        ],
        optional: [
          {'title': 'زيت جسم', 'desc': 'لإضافة لمعة ونعومة أكثر'},
          {'title': 'عناية المناطق الجافة', 'desc': 'للركب، الأكواع والكعبين'},
        ],
        facts:
            'أفضل وقت للترطيب هو بعد الاستحمام مباشرة عندما تكون البشرة ما زالت رطبة قليلاً.',
      );
    }

    if (key.contains('solaire') || key.contains('solaires')) {
      return guide(
        intro:
            'الحماية من الشمس خطوة يومية وليست فقط للبحر أو الصيف. اختاري القوام حسب بشرتك.',
        steps: [
          {
            'title': 'حماية الوجه',
            'desc': 'واقي شمس خفيف يناسب نوع البشرة ولا يثقلها.',
          },
          {
            'title': 'حماية الجسم',
            'desc':
                'طبقة كافية على المناطق المكشوفة، مع إعادة التطبيق عند الحاجة.',
          },
          {
            'title': 'بعد الشمس',
            'desc': 'ترطيب وتهدئة للبشرة بعد التعرض للشمس.',
          },
        ],
        optional: [
          {
            'title': 'برونزر أو زيت تسمير',
            'desc': 'للمظهر البرونزي مع الانتباه للحماية',
          },
        ],
        facts:
            'الواقي الشمسي يساعد على تقليل التصبغات ويحافظ على إشراقة البشرة على المدى الطويل.',
      );
    }

    if (key.contains('brume') || key.contains('brumes')) {
      return guide(
        intro:
            'البخاخات تضيف انتعاشاً سريعاً ويمكن استخدامها خلال اليوم حسب الحاجة.',
        steps: [
          {
            'title': 'اختيار الرائحة',
            'desc': 'اختاري نفحات خفيفة لليوم أو أعمق للمساء.',
          },
          {
            'title': 'الرش',
            'desc': 'رشي على الجسم أو الملابس من مسافة مناسبة.',
          },
          {
            'title': 'التجديد',
            'desc': 'يمكن إعادة الرش خلال اليوم للحفاظ على الانتعاش.',
          },
        ],
        facts: 'البخاخات أخف من العطر وغالباً تناسب الاستخدام اليومي المتكرر.',
      );
    }

    if (key.contains('parfum') || key.contains('parfums')) {
      return guide(
        intro:
            'العطر يكتمل عندما تختارين عائلة روائح تناسب ذوقك ووقت الاستخدام.',
        steps: [
          {
            'title': 'اختيار العائلة',
            'desc': 'زهري، فاكهي، حلو، خشبي أو شرقي حسب المزاج والمناسبة.',
          },
          {
            'title': 'نقاط النبض',
            'desc': 'طبقيه على المعصمين، الرقبة أو خلف الأذن بدون فرك قوي.',
          },
          {
            'title': 'الثبات',
            'desc': 'ترطيب البشرة قبل العطر يساعد الرائحة على الثبات أكثر.',
          },
        ],
        facts:
            'الرائحة تتغير قليلاً من بشرة لأخرى، لذلك التجربة مهمة قبل الاختيار.',
      );
    }

    if (key.contains('maquillage')) {
      return guide(
        intro:
            'مكياج بسيط ومرتب يبدأ بتوحيد البشرة ثم إبراز العينين والشفاه حسب رغبتك.',
        steps: [
          {
            'title': 'البشرة',
            'desc':
                'وحّدي اللون بخفة بكريم أساس، BB كريم أو كونسيلر على المناطق التي تحتاج تغطية. الهدف: بشرة نضرة وغير متكلفة.',
          },
          {
            'title': 'البودرة',
            'desc':
                'تثبت كريم الأساس وتخفف اللمعان. طبقيها بفرشاة أو إسفنجة حسب الحاجة.',
          },
          {
            'title': 'العينان',
            'desc':
                'ماسكارا لفتح النظرة، ويمكن إضافة خط آيلاينر رفيع لتحديد العين.',
          },
          {
            'title': 'البلاشر',
            'desc':
                'يعطي الوجه حيوية وانتعاشاً. ربتيه على الخدين لتأثير طبيعي.',
          },
          {
            'title': 'الشفاه',
            'desc':
                'بلسم، غلوس أو أحمر شفاه حسب الرغبة. الترطيب يبقى دائماً أساسياً.',
          },
        ],
        optional: [
          {'title': 'باليتات', 'desc': 'للعب بالألوان'},
          {
            'title': 'أقلام العين أو الشفاه',
            'desc': 'لتكثيف أو إعادة تحديد الخط',
          },
          {'title': 'أحمر شفاه', 'desc': 'مطفي، ساتان أو لامع'},
          {'title': 'برايمر', 'desc': 'يحسن الثبات وينعم ملمس البشرة'},
          {'title': 'بخاخ تثبيت', 'desc': 'يطيل ثبات المكياج خلال اليوم'},
          {'title': 'كونتور', 'desc': 'ينحت ملامح الوجه ويحددها'},
        ],
        facts:
            'فيتامين E يساعد على حماية البشرة والحفاظ على راحتها حتى مع المكياج.',
      );
    }

    return null;
  }

  String _guideIntro(
    CategoryData categoryData,
    CategoryGuide guide,
    bool isEn,
    bool isAr,
  ) {
    if (isAr) {
      final fallback = _arabicGuideFallback(categoryData.name);
      return guide.intro_ar.trim().isNotEmpty
          ? guide.intro_ar
          : (fallback?['intro'] as String? ?? guide.intro);
    }
    return isEn ? guide.intro_en : guide.intro;
  }

  String _guideFacts(
    CategoryData categoryData,
    CategoryGuide guide,
    bool isEn,
    bool isAr,
  ) {
    if (isAr) {
      final fallback = _arabicGuideFallback(categoryData.name);
      return guide.facts_ar.trim().isNotEmpty
          ? guide.facts_ar
          : (fallback?['facts'] as String? ?? guide.facts);
    }
    return isEn ? guide.facts_en : guide.facts;
  }

  List<Map<String, String>> _guideSteps(
    CategoryData categoryData,
    List<GuideStep> source,
    bool isEn,
    bool isAr, {
    bool optional = false,
  }) {
    if (isAr) {
      final fallback = _arabicGuideFallback(categoryData.name);
      final fallbackList = fallback?[optional ? 'optional' : 'steps'];
      if (fallbackList is List) {
        return fallbackList
            .map((item) => Map<String, String>.from(item as Map))
            .toList();
      }
    }

    return source.map((step) {
      if (isAr) {
        return {
          'title': step.title_ar.trim().isNotEmpty ? step.title_ar : step.title,
          'desc': step.desc_ar.trim().isNotEmpty ? step.desc_ar : step.desc,
        };
      }
      return {
        'title': isEn ? step.title_en : step.title,
        'desc': isEn ? step.desc_en : step.desc,
      };
    }).toList();
  }

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
    final language = Provider.of<LanguageProvider>(context, listen: false);
    final bool isEn = language.isEn;
    final bool isAr = language.isAr;

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
                isAr
                    ? (categoryData.name_ar.trim().isNotEmpty
                          ? categoryData.name_ar
                          : _categoryLabel(categoryData.name, language))
                    : isEn
                    ? categoryData.name_en
                    : categoryData.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kPrimaryPink,
                ),
              ),

              // INTRO TRADUITE
              if (_guideIntro(categoryData, guide, isEn, isAr).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _guideIntro(categoryData, guide, isEn, isAr),
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                  ),
                ),
              ],

              const Divider(height: 32),

              // --- ÉTAPES (STEPS) DYNAMIQUES ---
              ..._guideSteps(categoryData, guide.steps, isEn, isAr).map((step) {
                final String sTitle = step['title'] ?? '';
                final String sDesc = step['desc'] ?? '';

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
              if (_guideSteps(
                categoryData,
                guide.optional,
                isEn,
                isAr,
                optional: true,
              ).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  context.t("shop.optional"),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.pink[300],
                  ),
                ),
                const SizedBox(height: 8),
                ..._guideSteps(
                  categoryData,
                  guide.optional,
                  isEn,
                  isAr,
                  optional: true,
                ).map((opt) {
                  final String oTitle = opt['title'] ?? '';
                  final String oDesc = opt['desc'] ?? '';

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
              if (_guideFacts(categoryData, guide, isEn, isAr).isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${context.t("shop.miniFacts")} ${_guideFacts(categoryData, guide, isEn, isAr)}",
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
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: isSearching
            ? _buildSearchField()
            : Text(
                context.t("shop.title"),
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
          hintText: context.t("shop.search"),
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(fontSize: 18, color: Colors.black87),
      ),
    );
  }

  Widget _buildMakeupSectionBar() {
    if (selectedCategory != "Maquillage") return const SizedBox.shrink();

    final language = Provider.of<LanguageProvider>(context);

    // Liste des sections intermédiaires
    final List<String> sections = ["Teint", "Yeux", "Lèvres"];

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: language.isAr,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final section = sections[index];
            final isSel = selectedMakeupSection == section;

            String displayLabel = section;
            if (language.isAr) {
              displayLabel = _makeupSectionLabelsAr[section] ?? section;
            } else if (language.isEn) {
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
    final language = Provider.of<LanguageProvider>(context);
    final bool isEn = language.isEn;
    final bool isAr = language.isAr;

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
        question = isAr
            ? "لا تعرفين خطوات روتين العناية بالوجه؟"
            : isEn
            ? "Don't know the steps of a face routine?"
            : "Tu ne connais pas les étapes d’une routine visage ?";
        break;
      case "Maquillage":
        question = isAr
            ? "لا تعرفين كيف تجهزين مكياجاً سهلاً؟"
            : isEn
            ? "Don't know how to create an easy makeup look?"
            : "Tu ne sais pas comment composer un maquillage facile ?";
        break;
      case "Soins corps":
        question = isAr
            ? "لا تعرفين من أين تبدئين العناية بالجسم؟"
            : isEn
            ? "Don't know where to start for your body care?"
            : "Tu ne sais pas par quoi commencer pour ton corps ?";
        break;
      case "Cheveux":
        question = isAr
            ? "لا تعرفين خطوات روتين الشعر؟"
            : isEn
            ? "Don't know the steps for your hair routine?"
            : "Tu ne connais pas les étapes pour tes cheveux ?";
        break;
      default:
        // Phrase générique pour les nouvelles catégories ajoutées sur Firestore
        question = isAr
            ? "تريدين معرفة أساسيات هذه الفئة؟"
            : isEn
            ? "Want to learn the basics for this category?"
            : "Tu veux apprendre les bases pour cette catégorie ?";
    }

    // Traduction du bouton
    linkText = context.t("shop.discoverBasics");

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
                context.t("shop.noProducts"),
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
    final language = Provider.of<LanguageProvider>(context);

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
        reverse: language.isAr,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final String techName = categories[index];
          final isSel = techName == selectedCategory;

          String displayLabel = _categoryLabel(techName, language);

          return GestureDetector(
            onTap: () => setState(() {
              selectedCategory =
                  techName; // Stocke bien "Nouveautés" en FR pour tes filtres
              selectedSubCategory = null;
              selectedMakeupSection = null;
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 10, top: 6),
              constraints: BoxConstraints(
                minWidth: techName == "Nouveautés" ? 116 : 0,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? _kPrimaryPink : _kLightPinkBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    displayLabel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSel ? _kActiveText : _kPrimaryPink,
                      fontWeight: FontWeight.w600,
                    ),
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
    final language = Provider.of<LanguageProvider>(context);
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
            textDirection: language.isAr
                ? TextDirection.rtl
                : TextDirection.ltr,
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
                    child: Text(context.t("shop.all")),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(context.t("shop.local")),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(context.t("shop.imported")),
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
                          context.t("shop.completeProfile"),
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
                        context.t("shop.forYou"),
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
    final language = Provider.of<LanguageProvider>(context);
    String sortText(String key) => AppText.t(language.languageCode, key);

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
      itemBuilder: (_) => [
        PopupMenuItem(value: "none", child: Text(sortText("shop.defaultSort"))),
        PopupMenuItem(value: "asc", child: Text(sortText("shop.priceAsc"))),
        PopupMenuItem(value: "desc", child: Text(sortText("shop.priceDesc"))),
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
    final language = Provider.of<LanguageProvider>(context);

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        height: 38,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: language.isAr,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subs.length,
          itemBuilder: (context, index) {
            final subObj = subs[index];

            // 4. LOGIQUE D'AFFICHAGE UNIQUEMENT : On traduit pour les yeux de l'utilisateur
            final String displayName = _subCategoryLabel(subObj, language);

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
  static const Map<String, String> tagTranslationsAr = {
    "secs": "جاف",
    "sèche": "جافة",
    "normaux": "عادي",
    "normale": "عادية",
    "gras": "دهني",
    "grasse": "دهنية",
    "mixte": "مختلطة",
    "abîmés": "متضرر",
    "colorés": "مصبوغ",
    "fins": "خفيف",
    "tout_type": "كل الأنواع",
    "tous types": "كل الأنواع",
    "tous types ": "كل الأنواع",
    "tous types de peaux": "كل أنواع البشرة",
    "très sèche": "جافة جداً",
    "tres seche": "جافة جداً",
    "sensible": "حساسة",
    "sensibles": "حساسة",
    "abîmé": "متضرر",
    "abime": "متضرر",
    "abimes": "متضرر",
    "sec": "جاف",
    "sèches": "جافة",
    "seches": "جافة",
    "coloré": "مصبوغ",
    "colore": "مصبوغ",
    "blond": "أشقر",
    "blonds": "أشقر",
    "bouclés": "كيرلي",
    "boucles": "كيرلي",
    "frisés": "مجعد",
    "frises": "مجعد",
    "crépus": "مجعد جداً",
    "crepus": "مجعد جداً",
  };

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
  String _localizedBadge(String rawBadge, bool isAr) {
    if (!isAr) return rawBadge;

    final normalized = rawBadge.toLowerCase().trim();
    final shadeMatch = RegExp(
      r'(?:teintes?|shades?)\s*(\d+)',
    ).firstMatch(normalized);
    if (shadeMatch != null) {
      return 'درجات ${shadeMatch.group(1)}';
    }

    const badgeTranslationsAr = {
      'nouveau': 'جديد',
      'new': 'جديد',
      'promo': 'تخفيض',
      'soldes': 'تخفيض',
      'best seller': 'الأكثر مبيعاً',
      'bestseller': 'الأكثر مبيعاً',
      'édition limitée': 'إصدار محدود',
      'edition limitee': 'إصدار محدود',
    };

    return badgeTranslationsAr[normalized] ?? rawBadge;
  }

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
    final bool isEn = languageProvider.isEn;
    final bool isAr = languageProvider.isAr;

    // Sélection dynamique des textes
    final String displayTitle = isAr && product.titleAr.trim().isNotEmpty
        ? product.titleAr
        : isEn
        ? product.titleEn
        : product.title;
    final String rawBadge = isEn
        ? (product.customBadgeEn ?? product.customBadge ?? '')
        : (product.customBadge ?? '');
    final String arBadge = product.customBadgeAr?.trim() ?? '';
    final String displayBadge = isAr
        ? _localizedBadge(arBadge.isNotEmpty ? arBadge : rawBadge, true)
        : rawBadge;

    final String buyLabel = context.t("shop.buy");
    final String addedToCartMsg = context.t("product.addedToCart");
    final String loginNeededMsg = context.t("shop.loginNeeded");

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
                        final languageProvider = Provider.of<LanguageProvider>(
                          context,
                        );
                        final bool isEn = languageProvider.isEn;
                        final bool isAr = languageProvider.isAr;

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
                            if (isAr) {
                              labelAffiche =
                                  ProductCard.tagTranslationsAr[tagFr
                                      .toLowerCase()
                                      .trim()] ??
                                  tagFr;
                            } else if (isEn) {
                              // On utilise le dictionnaire statique qu'on a défini à l'étape précédente
                              labelAffiche =
                                  ProductCard.tagTranslationsEn[tagFr
                                      .toLowerCase()
                                      .trim()] ??
                                  tagFr;
                            } else {
                              // En français, on gère proprement l'affichage de "tout_type"
                              if (tagFr == "tout_type") {
                                labelAffiche = "Tous Types";
                              }
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
                    AppText.formatPrice(
                      languageProvider.languageCode,
                      product.price,
                    ),
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
                            items[index]['title_ar'] = product.titleAr;
                            items[index]['title'] = product.title;
                          } else {
                            // Nouveau produit : on enregistre le titre FR ET le titre EN
                            items.add({
                              'cartItemId': cartItemId,
                              'productId': product.id,
                              'title': product.title,
                              'title_en': product.titleEn, // Parfait !
                              'title_ar': product.titleAr,
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
                      ? context.t("shop.outOfStockShort")
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
