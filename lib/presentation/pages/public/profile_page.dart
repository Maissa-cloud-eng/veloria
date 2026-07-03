import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:veloria/main.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/pages/public/type_quiz.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';

const List<Map<String, String>> wilayasAlgerie = [
  {'id': 'adrar', 'name': '01 - Adrar'},
  {'id': 'chlef', 'name': '02 - Chlef'},
  {'id': 'laghouat', 'name': '03 - Laghouat'},
  {'id': 'oum el bouaghi', 'name': '04 - Oum El Bouaghi'},
  {'id': 'batna', 'name': '05 - Batna'},
  {'id': 'bejaia', 'name': '06 - Béjaïa'},
  {'id': 'biskra', 'name': '07 - Biskra'},
  {'id': 'bechar', 'name': '08 - Béchar'},
  {'id': 'blida', 'name': '09 - Blida'},
  {'id': 'bouira', 'name': '10 - Bouira'},
  {'id': 'tamanrasset', 'name': '11 - Tamanrasset'},
  {'id': 'tebessa', 'name': '12 - Tébessa'},
  {'id': 'tlemcen', 'name': '13 - Tlemcen'},
  {'id': 'tiaret', 'name': '14 - Tiaret'},
  {'id': 'tizi ouzou', 'name': '15 - Tizi Ouzou'},
  {'id': 'alger', 'name': '16 - Alger'},
  {'id': 'djelfa', 'name': '17 - Djelfa'},
  {'id': 'jijel', 'name': '18 - Jijel'},
  {'id': 'setif', 'name': '19 - Sétif'},
  {'id': 'saida', 'name': '20 - Saïda'},
  {'id': 'skikda', 'name': '21 - Skikda'},
  {'id': 'sidi bel abbes', 'name': '22 - Sidi Bel Abbès'},
  {'id': 'annaba', 'name': '23 - Annaba'},
  {'id': 'guelma', 'name': '24 - Guelma'},
  {'id': 'constantine', 'name': '25 - Constantine'},
  {'id': 'medea', 'name': '26 - Médéa'},
  {'id': 'mostaganem', 'name': '27 - Mostaganem'},
  {'id': 'msila', 'name': '28 - M\'Sila'},
  {'id': 'mascara', 'name': '29 - Mascara'},
  {'id': 'ouargla', 'name': '30 - Ouargla'},
  {'id': 'oran', 'name': '31 - Oran'},
  {'id': 'el bayadh', 'name': '32 - El Bayadh'},
  {'id': 'illizi', 'name': '33 - Illizi'},
  {'id': 'bordj bou arreridj', 'name': '34 - Bordj Bou Arreridj'},
  {'id': 'boumerdes', 'name': '35 - Boumerdès'},
  {'id': 'el tarf', 'name': '36 - El Tarf'},
  {'id': 'tindouf', 'name': '37 - Tindouf'},
  {'id': 'tissemsilt', 'name': '38 - Tissemsilt'},
  {'id': 'el oued', 'name': '39 - El Oued'},
  {'id': 'khenchela', 'name': '40 - Khenchela'},
  {'id': 'souk ahras', 'name': '41 - Souk Ahras'},
  {'id': 'tipaza', 'name': '42 - Tipaza'},
  {'id': 'mila', 'name': '43 - Mila'},
  {'id': 'ain defla', 'name': '44 - Aïn Defla'},
  {'id': 'naama', 'name': '45 - Naâma'},
  {'id': 'ain temouchent', 'name': '46 - Aïn Témouchent'},
  {'id': 'ghardaia', 'name': '47 - Ghardaïa'},
  {'id': 'relizane', 'name': '48 - Relizane'},
  {'id': 'timimoun', 'name': '49 - Timimoun'},
  {'id': 'bordj badji mokhtar', 'name': '50 - Bordj Badji Mokhtar'},
  {'id': 'ouled djellal', 'name': '51 - Ouled Djellal'},
  {'id': 'beni abbes', 'name': '52 - Béni Abbès'},
  {'id': 'in salah', 'name': '53 - In Salah'},
  {'id': 'in guezzam', 'name': '54 - In Guezzam'},
  {'id': 'touggourt', 'name': '55 - Touggourt'},
  {'id': 'djanet', 'name': '56 - Djanet'},
  {'id': 'el m\'ghair', 'name': '57 - El M\'Ghair'},
  {'id': 'el meniaa', 'name': '58 - El Meniaâ'},
];
final Map<String, Map<String, dynamic>> chipExplanations = {
  // ==========================================
  // TYPE DE PEAU (skinOptions)
  // ==========================================
  "Normale": {
    "title": {"fr": "Peau Normale", "en": "Normal Skin"},
    "desc": {
      "fr":
          "Peau équilibrée, ni trop grasse ni trop sèche. Elle est confortable, douce et sans imperfections majeures.",
      "en":
          "Balanced skin, neither too oily nor too dry. It feels comfortable, soft, and has no major imperfections.",
    },
    "image": "assets/puces/skin_normal.png",
  },
  "Sèche": {
    "title": {"fr": "Peau Sèche", "en": "Dry Skin"},
    "desc": {
      "fr":
          "Peau qui manque d'hydratation et de gras. Elle tiraille (surtout après le lavage), peut peler et manque de souplesse.",
      "en":
          "Skin that lacks moisture and oil. It feels tight (especially after washing), can flake, and lacks elasticity.",
    },
    "image": "assets/puces/skin_dry.png",
  },
  "Grasse": {
    "title": {"fr": "Peau Grasse", "en": "Oily Skin"},
    "desc": {
      "fr":
          "Peau qui produit trop de sébum. Elle brille sur tout le visage, les pores sont visibles et elle est sujette aux boutons.",
      "en":
          "Skin that produces too much sebum. It looks shiny all over, has visible pores, and is prone to breakouts.",
    },
    "image": "assets/puces/skin_oily.png",
  },
  "Mixte": {
    "title": {"fr": "Peau Mixte", "en": "Combination Skin"},
    "desc": {
      "fr":
          "Peau grasse et brillante sur la zone T (front, nez, menton) mais normale ou sèche sur les joues.",
      "en":
          "Oily and shiny skin on the T-zone (forehead, nose, chin) but normal or dry on the cheeks.",
    },
    "image": "assets/puces/skin_combination.png",
  },

  // ==========================================
  // TEXTURE DE CHEVEUX (hairTextures)
  // ==========================================
  "Lisses": {
    "title": {"fr": "Cheveux Lisses", "en": "Straight Hair"},
    "desc": {
      "fr":
          "Cheveux sans aucune ondulation. Ils tombent tout droit et ont tendance à briller et à regraisser plus vite.",
      "en":
          "Hair with no curl or wave. It falls completely straight and tends to look shiny and get oily faster.",
    },
    "image": "assets/puces/hair_straight.png",
  },
  "Ondulés": {
    "title": {"fr": "Cheveux Ondulés", "en": "Wavy Hair"},
    "desc": {
      "fr":
          "Cheveux qui forment des vagues légères ou des ondulations en forme de 'S' sans faire de vraies boucles.",
      "en":
          "Hair that forms loose waves or 'S' shapes without making tight, defined curls.",
    },
    "image": "assets/puces/hair_wavy.png",
  },
  "Bouclés": {
    "title": {"fr": "Cheveux Bouclés", "en": "Curly Hair"},
    "desc": {
      "fr":
          "Cheveux qui forment de vraies boucles bien définies et élastiques (comme des ressorts en spirale).",
      "en":
          "Hair that forms distinct, well-defined, and bouncy curls (like spiral springs).",
    },
    "image": "assets/puces/hair_curly.png",
  },
  "Frisés": {
    "title": {"fr": "Cheveux Frisés", "en": "Coily Hair"},
    "desc": {
      "fr":
          "Boucles très petites, serrées et denses. Les cheveux ont beaucoup de volume et rétrécissent beaucoup au séchage.",
      "en":
          "Very small, tight, and dense curls. The hair has a lot of volume and experiences significant shrinkage when dry.",
    },
    "image": "assets/puces/hair_coily.png",
  },
  "Crépus": {
    "title": {"fr": "Cheveux Crépus", "en": "Kinky Hair"},
    "desc": {
      "fr":
          "Cheveux très serrés en forme de 'Z' ou sans forme de boucle définie. Ils sont naturellement très volumineux et fragiles.",
      "en":
          "Tightly packed hair forming 'Z' patterns or with no defined curl. It is naturally very voluminous and delicate.",
    },
    "image": "assets/puces/hair_kinky.png",
  },

  // ==========================================
  // ÉTAT DU CHEVEU (hairStates)
  // ==========================================
  "Secs": {
    "title": {"fr": "Cheveux Secs", "en": "Dry Hair"},
    "desc": {
      "fr":
          "Cheveux rêches au toucher, ternes, difficiles à démêler et qui cassent facilement ou forment des fourches.",
      "en":
          "Hair that feels rough, looks dull, is hard to detangle, and breaks easily or gets split ends.",
    },
    "image": "assets/puces/hair_dry.png",
  },
  "Normaux": {
    "title": {"fr": "Cheveux Normaux", "en": "Normal Hair"},
    "desc": {
      "fr":
          "Cheveux sains, doux et brillants. Ils ne sont ni trop secs ni trop gras et se coiffent facilement.",
      "en":
          "Healthy, soft, and shiny hair. It is neither too dry nor too oily and is easy to style.",
    },
    "image": "assets/puces/hair_normal.png",
  },
  "Gras": {
    "title": {"fr": "Cheveux Gras", "en": "Oily Hair"},
    "desc": {
      "fr":
          "Cheveux qui saturent vite de sébum. Ils deviennent lourds, luisants et plats seulement un ou deux jours après le lavage.",
      "en":
          "Hair that quickly buildup sebum. It feels heavy, looks shiny, and goes flat just one or two days after washing.",
    },
    "image": "assets/puces/hair_oily.png",
  },
  "Mixtes": {
    "title": {"fr": "Cheveux Mixtes", "en": "Combination Hair"},
    "desc": {
      "fr":
          "Le cuir chevelu régraisse vite (racines grasses), mais les longueurs et les pointes restent sèches et abîmées.",
      "en":
          "The scalp gets oily quickly (oily roots), but the lengths and ends remain dry and damaged.",
    },
    "image": "assets/puces/hair_combination.png",
  },
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressLineController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  String cityType = '';

  bool _isLinkingGoogle = false;
  bool _isLinkingApple = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _ratingKey = GlobalKey();

  final ImagePicker _picker = ImagePicker();
  String? profileImageUrl;
  bool _showAllOrders = false;

  final Map<String, bool> _showSavedCheck = {};
  final Set<String> _showMerciFor = {};

  final List<String> languages = const ['Français', 'Anglais'];

  // Valeurs techniques (Firebase)
  final List<String> skinOptions = const [
    "Normale",
    "Sèche",
    "Grasse",
    "Mixte",
  ];
  final List<String> hairTextures = const [
    "Lisses",
    "Ondulés",
    "Bouclés",
    "Frisés",
    "Crépus",
  ];
  final List<String> hairStates = const ["Secs", "Normaux", "Gras", "Mixtes"];
  String skinType = '';
  String hairTexture = '';
  String hairState = '';
  String selectedLanguage = 'Français';

  Map<String, dynamic>? userData; // Ajoute cette ligne
  List<DocumentSnapshot> orderHistoryDocs = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupInitialChecks();
    _initProfile();
  }

  void _scrollToRatings() {
    // On ajoute un petit délai (300ms) pour laisser l'onglet Profil
    // s'afficher et calculer la position de ses éléments.
    Future.delayed(const Duration(milliseconds: 300), () {
      final context = _ratingKey.currentContext;

      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(
            seconds: 1,
          ), // 1 seconde pour un scroll bien fluide
          curve: Curves.easeInOut,
        );
      } else {
        // PLAN B : Si le context est encore nul, on force le scroll tout en bas
        // car le carrousel de notation est généralement en fin de page.
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _setupInitialChecks() {
    for (var key in [
      'name',
      'email',
      'phone',
      'addressLine',
      'city',
      'postalCode',
      'skinType',
      'hairTexture',
      'hairState',
      'selectedLanguage',
    ]) {
      _showSavedCheck[key] = false;
    }
  }

  Future<void> _initProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    userId = firebaseUser.uid;

    _firestore.collection('users').doc(userId).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          userData = data;
          nameController.text = data['name'] ?? '';
          emailController.text = data['email'] ?? '';
          phoneController.text = data['phone'] ?? '';
          addressLineController.text = data['addressLine'] ?? '';
          cityController.text = data['city'] ?? '';
          cityType = data['city'] ?? '';
          postalCodeController.text = data['postalCode'] ?? '';

          // ➔ CORRECTION : Sécurisation complète contre les valeurs nulles
          skinType = data['skinType'] ?? '';
          hairTexture = data['hairTexture'] ?? '';
          hairState = data['hairState'] ?? '';

          profileImageUrl = data['profileImageUrl'];
          selectedLanguage = data['selectedLanguage'] ?? 'Français';
        });
      }
    });
    _listenOrders();
  }

  void _listenOrders() {
    _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((snap) {
          if (mounted) setState(() => orderHistoryDocs = snap.docs);
        });
  }

  List<Map<String, dynamic>> _getUniqueProductsToRate() {
    final Map<String, Map<String, dynamic>> globalUniqueProducts = {};
    final List alreadyRatedGlobally = userData?['ratedProducts'] ?? [];

    for (var doc in orderHistoryDocs) {
      final data = doc.data() as Map<String, dynamic>;

      // ÉTAPE A : Le Statut
      String status = (data['deliveryStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();

      // ÉTAPE B : Les Items
      final items = data['items'] as List?;
      if (items != null) {
        for (var item in items) {
          final String pId = (item['productId'] ?? '').toString();

          bool isCurrentlyThanking = _showMerciFor.contains(pId);
          bool isRatedInThisOrder = item['isRated'] == true;
          bool isRatedGlobally = alreadyRatedGlobally.contains(pId);

          // --- LE TEST DE DIAGNOSTIC ---
          // Si ça ne s'affiche pas, c'est que l'une de ces conditions est fausse :
          bool isDelivered = (status == 'delivered' || status == 'livré');
          bool notYetRated = (!isRatedInThisOrder && !isRatedGlobally);

          if (isDelivered && notYetRated || isCurrentlyThanking) {
            if (pId.isNotEmpty && !globalUniqueProducts.containsKey(pId)) {
              globalUniqueProducts[pId] = {
                'docId': doc.id,
                'item': item,
                'allOrderItems': items,
              };
            }
          } else {
            // Ce print va te dire EXACTEMENT pourquoi l'item est caché
            print(
              "ID: $pId | Livré: $isDelivered | Pas encore noté: $notYetRated | Merci: $isCurrentlyThanking",
            );
          }
        }
      }
    }
    return globalUniqueProducts.values.toList();
  }

  void _showAuthSuccess(bool isEn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn ? "Welcome back!" : "Bon retour parmi nous !",
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFB76E79),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        width: 250,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  void _showAuthError(bool isEn) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEn ? "Authentication failed" : "Échec de l'authentification",
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        width: 250,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
    );
  }

  Future<void> _linkWithGoogle() async {
    final isEn =
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).selectedLanguage ==
        'Anglais';

    setState(() => _isLinkingGoogle = true);

    try {
      final googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? user;

      try {
        final result = await FirebaseAuth.instance.currentUser
            ?.linkWithCredential(credential);

        user = result?.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          final result = await FirebaseAuth.instance.signInWithCredential(
            credential,
          );

          user = result.user;
        } else {
          rethrow;
        }
      }

      if (user != null) {
        userId = user.uid;

        await _saveAuthUser(
          uid: user.uid,
          email: user.email,
          name: user.displayName,
        );

        await _initProfile();

        if (mounted) {
          _showAuthSuccess(isEn);
        }
      }
    } catch (e) {
      if (mounted) {
        _showAuthError(isEn);
      }
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
  }

  Future<void> _saveAuthUser({
    required String uid,
    String? email,
    String? name,
  }) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(uid).set({
        'name': name ?? '',
        'email': email ?? '',
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'isAnonymous': false,
      });
    }
  }

  Future<void> _linkWithApple() async {
    final isEn =
        Provider.of<LanguageProvider>(
          context,
          listen: false,
        ).selectedLanguage ==
        'Anglais';

    setState(() => _isLinkingApple = true);

    try {
      // 1. Génération nonce
      final rawNonce = List.generate(32, (_) {
        const charset =
            '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';
        return charset[Random.secure().nextInt(charset.length)];
      }).join();

      final sha256Nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      // 2. Connexion Apple
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: sha256Nonce,
      );

      // 3. Récupération email depuis token Apple
      String? extractedEmail;

      try {
        final token = appleCredential.identityToken ?? '';

        if (token.isNotEmpty) {
          final parts = token.split('.');

          if (parts.length == 3) {
            final payload = utf8.decode(
              base64Url.decode(base64Url.normalize(parts[1])),
            );

            final data = jsonDecode(payload);

            extractedEmail = data['email'];
          }
        }
      } catch (e) {
        print("Erreur extraction Apple email : $e");
      }

      // 4. Credential Firebase
      final credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken ?? '',
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // 5. Connexion Firebase
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = result.user;

      if (user != null) {
        userId = user.uid;

        // récupération nom Apple
        String? appleName;

        if (appleCredential.givenName != null ||
            appleCredential.familyName != null) {
          appleName =
              '${appleCredential.givenName ?? ''} '
                      '${appleCredential.familyName ?? ''}'
                  .trim();
        }

        final finalEmail =
            appleCredential.email ?? extractedEmail ?? user.email;

        // 6. Sauvegarde commune Firestore
        await _saveAuthUser(
          uid: user.uid,
          email: finalEmail,
          name: appleName ?? "Utilisateur Apple",
        );

        // 7. Mise à jour immédiate interface

        if (finalEmail != null && finalEmail.isNotEmpty) {
          emailController.text = finalEmail;
        }

        if (appleName != null && appleName.isNotEmpty) {
          nameController.text = appleName;
        }

        // 8. Recharge profil
        await _initProfile();

        if (mounted) {
          _showAuthSuccess(isEn);
        }
      }
    } catch (e, stack) {
      print("Erreur Apple : $e");
      print(stack);

      if (mounted) {
        _showAuthError(isEn);
      }
    } finally {
      if (mounted) {
        setState(() => _isLinkingApple = false);
      }
    }
  }

  // 1. Pop-up de confirmation de suppression
  Future<bool> _showDeleteAccountConfirmDialog(
    BuildContext context,
    bool isEn,
  ) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isEn ? "Delete Account?" : "Supprimer le compte ?"),
            content: Text(
              isEn
                  ? "Are you sure you want to permanently delete your account? This action is irreversible and all your data will be lost."
                  : "Êtes-vous sûr de vouloir supprimer définitivement votre compte ? Cette action est irréversible et toutes vos données seront perdues.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  isEn ? "Cancel" : "Annuler",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  isEn ? "Delete" : "Supprimer",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 2. Pop-up de sécurité si la session est trop ancienne (Exigence Firebase)
  void _showReauthDialog(BuildContext context, bool isEn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEn ? "Security Action Required" : "Action de sécurité requise",
        ),
        content: Text(
          isEn
              ? "For security reasons, please log out and log back in before deleting your account."
              : "Pour des raisons de sécurité, veuillez vous déconnecter puis vous reconnecter avant de pouvoir supprimer votre compte.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<bool> _showLogoutConfirmDialog(bool isEn) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(isEn ? "Logout" : "Déconnexion"),
            content: Text(
              isEn
                  ? "Are you sure you want to log out?"
                  : "Êtes-vous sûr de vouloir vous déconnecter ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  isEn ? "Cancel" : "Annuler",
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  isEn ? "Log Out" : "Se déconnecter",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // --- CE BLOC ICI EST MAGIQUE ---
    if (shouldJumpToRatings) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToRatings();
        shouldJumpToRatings =
            false; // On reset pour éviter les boucles infinies
      });
    }
    final productsToRate = _getUniqueProductsToRate().toList();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.selectedLanguage == 'Anglais';

    // Traductions
    final String titleApp = isEn ? 'Profile' : 'Profil';
    final String labelName = isEn ? 'Full Name' : 'Nom';
    final String labelPhone = isEn ? 'Phone Number' : 'Téléphone';
    final String labelHistory = isEn
        ? 'Order History'
        : 'Historique des commandes';
    final String labelSkin = isEn ? 'Skin Type' : 'Type de peau';
    final String labelHair = isEn ? 'Hair' : 'Cheveux';
    final String labelAddressSec = isEn
        ? 'Delivery Address'
        : 'Adresse de livraison';
    final String labelLang = isEn ? 'Language' : 'Langue';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(titleApp, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfilePhoto(),
              const SizedBox(height: 20),

              // --- BLOC IDENTITÉ (Conditionnel) ---
              // On vérifie si l'utilisateur est anonyme ET n'a pas encore lié son compte via Google
              if ((FirebaseAuth.instance.currentUser?.isAnonymous ?? true) &&
                  (userData == null ||
                      (userData!['email'] == null || userData!['email'] == "")))
                Column(
                  children: [
                    Text(
                      isEn ? "Secure your account" : "Sécurisez votre compte",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    // --- BOUTON GOOGLE ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        // Désactive le bouton si un chargement est en cours
                        onPressed: _isLinkingGoogle ? null : _linkWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 1,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // La roue ne tourne ICI que si on lie avec Google (à vérifier dans ta fonction _linkWithGoogle)
                            _isLinkingGoogle
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.pink,
                                    ),
                                  )
                                : SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Center(
                                      child: Image.asset(
                                        'assets/google_icon.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              isEn
                                  ? "Continue with Google"
                                  : "Continuer avec Google",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- BOUTON APPLE (Uniquement sur iOS) ---
                    if (Platform.isIOS) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          // BIEN METTRE null ICI pour désactiver le bouton pendant le chargement
                          onPressed: _isLinkingApple ? null : _linkWithApple,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // Fond noir officiel
                            foregroundColor: Colors.white,
                            elevation: 1,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // --- ROUE OU LOGO APPLE ---
                              _isLinkingApple
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors
                                            .white, // Roue blanche sur fond noir, très propre !
                                      ),
                                    )
                                  : SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Center(
                                        child: Image.asset(
                                          'assets/apple_icon.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                              const SizedBox(width: 10),
                              Text(
                                isEn
                                    ? "Continue with Apple"
                                    : "Continuer avec Apple",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),
                    Text(
                      isEn
                          ? "To access your account anywhere"
                          : "Pour retrouver votre compte partout",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                )
              else ...[
                // Apparaît uniquement APRES la connexion Google ou Apple
                _buildTextField(labelName, nameController, 'name'),
                const SizedBox(height: 10),
                _buildTextField('Email', emailController, 'email'),
                const SizedBox(height: 10),
                _buildTextField(labelPhone, phoneController, 'phone'),
              ],

              // --- BLOC ADRESSE ET RESTE (Toujours visibles) ---
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              _buildAddressSection(isEn, labelAddressSec), // Toujours là
              const SizedBox(height: 30),
              _buildSkinSection(isEn, labelSkin), // Toujours là
              const SizedBox(height: 15),
              _buildHairSection(isEn, labelHair), // Toujours là
              const SizedBox(height: 15),
              _buildLanguageSection(labelLang), // Toujours là
              const SizedBox(height: 30),

              if (productsToRate.isNotEmpty)
                Container(
                  key: _ratingKey,
                  child: _buildRatingCarousel(productsToRate, isEn),
                ),

              Text(
                labelHistory,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildVerticalHistory(isEn),

              // --- DÉBUT DU BLOC CONDITIONNEL ---
              // On vérifie que l'utilisateur existe ET qu'il n'est pas anonyme
              if (FirebaseAuth.instance.currentUser != null &&
                  !FirebaseAuth.instance.currentUser!.isAnonymous) ...[
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                // 1. BOUTON SE DÉCONNECTER
                Center(
                  child: InkWell(
                    onTap: () async {
                      bool confirm = await _showLogoutConfirmDialog(isEn);
                      if (confirm) {
                        try {
                          Provider.of<CartController>(
                            context,
                            listen: false,
                          ).clear();
                        } catch (e) {
                          print("Erreur lors du nettoyage du panier: $e");
                        }

                        await FirebaseAuth.instance.signOut();
                        await GoogleSignIn().signOut();

                        if (mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const MainWrapper(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.logout,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? "Log Out" : "Se déconnecter",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2. BOUTON SUPPRIMER LE COMPTE (Exigence Apple Guideline 5.1.1(v))
                Center(
                  child: InkWell(
                    onTap: () async {
                      bool confirm = await _showDeleteAccountConfirmDialog(
                        context,
                        isEn,
                      );
                      if (confirm) {
                        try {
                          // Nettoyage du panier avant suppression
                          try {
                            Provider.of<CartController>(
                              context,
                              listen: false,
                            ).clear();
                          } catch (e) {
                            print("Erreur nettoyage panier: $e");
                          }

                          // Optionnel : Tu peux supprimer le document de l'utilisateur dans Firestore ici si nécessaire
                          // String? uid = FirebaseAuth.instance.currentUser?.uid;
                          // await FirebaseFirestore.instance.collection('users').doc(uid).delete();

                          // Suppression définitive du compte dans Firebase Auth
                          await FirebaseAuth.instance.currentUser?.delete();
                          await GoogleSignIn().signOut();

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEn
                                      ? "Account permanently deleted."
                                      : "Compte supprimé définitivement.",
                                ),
                              ),
                            );
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const MainWrapper(),
                              ),
                              (route) => false,
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          if (e.code == 'requires-recent-login') {
                            if (mounted) {
                              _showReauthDialog(context, isEn);
                            }
                          } else {
                            print("Erreur lors de la suppression: $e");
                          }
                        } catch (e) {
                          print("Erreur générique suppression: $e");
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delete_forever,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isEn ? "Delete Account" : "Supprimer le compte",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              // --- FIN DU BLOC CONDITIONNEL ---
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingCarousel(
    List<Map<String, dynamic>> productsToRate,
    bool isEn,
  ) {
    if (productsToRate.isEmpty) return const SizedBox.shrink();

    final String labelRate = isEn
        ? 'Rate your purchases 🛍️'
        : 'Notez vos achats 🛍️';
    final String labelMerci = isEn ? 'Thank you' : 'Merci';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            labelRate,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: productsToRate.length,
            itemBuilder: (context, index) {
              if (index >= productsToRate.length) {
                return const SizedBox.shrink();
              }

              final data = productsToRate[index];
              final item = data['item'];
              if (item == null) return const SizedBox.shrink();

              // 🔎 LE PETIT DÉTECTIVE : On inspecte ce que contient vraiment l'item reçu
              debugPrint("📦 [VELORIA INSPECT] Contenu de l'item : $item");

              final String pId = (item['productId'] ?? '').toString();

              // On vérifie ce que renvoient exactement les clés
              final String? titleFr = item['title']?.toString();
              final String? titleEnField = item['title_en']?.toString();

              final String title = isEn
                  ? ((titleEnField != null && titleEnField.isNotEmpty)
                        ? titleEnField
                        : (titleFr ?? 'Product'))
                  : (titleFr ?? 'Produit');

              bool isShowingMerci = _showMerciFor.contains(pId);

              return Card(
                key: ValueKey("card_$pId"),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: isShowingMerci
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite,
                                color: Colors.pink,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                labelMerci,
                                style: TextStyle(
                                  color: Colors.pink,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            if (item['imageUrl'] != null &&
                                item['imageUrl'] != "")
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['imageUrl'],
                                  height: 80,
                                  width: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) =>
                                      Icon(Icons.image_not_supported),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  StarRating(
                                    onRated: (stars) async {
                                      setState(() {
                                        _showMerciFor.add(pId);
                                      });

                                      _firestore
                                          .collection('users')
                                          .doc(userId)
                                          .update({
                                            'ratedProducts':
                                                FieldValue.arrayUnion([pId]),
                                          })
                                          .catchError((e) => print(e));

                                      Future.delayed(Duration(seconds: 2), () {
                                        if (mounted) {
                                          setState(() {
                                            _showMerciFor.remove(pId);

                                            productsToRate.removeWhere(
                                              (element) =>
                                                  element['item']['productId']
                                                      .toString() ==
                                                  pId,
                                            );
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),
      ],
    );
  }

  Widget _buildVerticalHistory(bool isEn) {
    if (orderHistoryDocs.isEmpty) {
      return Text(isEn ? "No orders" : "Aucune commande");
    }
    final displayedOrders = _showAllOrders
        ? orderHistoryDocs
        : orderHistoryDocs.take(3).toList();

    return Column(
      children: [
        ...displayedOrders.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final items = data['items'] as List?;

          final String firstItemTitle = isEn
              ? (items?[0]['title_en'] ??
                    items?[0]['name_en'] ??
                    items?[0]['title'] ??
                    'Order')
              : (items?[0]['title'] ?? 'Commande');

          // --- LOGIQUE DE STATUT TRADUIT ET COLORÉ ---
          final rawStatus = (data['deliveryStatus'] ?? 'pending')
              .toString()
              .toLowerCase();

          String displayStatus;
          Color statusColor;

          if (rawStatus == 'shipped') {
            displayStatus = isEn ? "Shipped" : "Expédiée";
            statusColor = Colors.blue;
          } else if (rawStatus == 'delivered') {
            displayStatus = isEn ? "Delivered" : "Livrée";
            statusColor = Colors.green;
          } else if (rawStatus == 'cancelled') {
            displayStatus = isEn ? "Cancelled" : "Annulée";
            statusColor = Colors.red;
          } else {
            displayStatus = isEn ? "In progress" : "En cours";
            statusColor = Colors.orange;
          }

          final DateTime date = (data['orderDate'] as Timestamp).toDate();

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () => _showOrderDetails(data, isEn),
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.pink.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag, color: Colors.pink),
              ),
              title: Text(
                "$firstItemTitle...",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                "${DateFormat('dd/MM/yyyy').format(date)} • ${displayStatus.toUpperCase()}",
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor, // La couleur change selon le statut
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
            ),
          );
        }),
        if (orderHistoryDocs.length > 3)
          TextButton(
            onPressed: () => setState(() => _showAllOrders = !_showAllOrders),
            child: Text(
              _showAllOrders
                  ? (isEn ? "Show less" : "Voir moins")
                  : (isEn
                        ? "Show all (${orderHistoryDocs.length})"
                        : "Voir tout (${orderHistoryDocs.length})"),
              style: const TextStyle(
                color: Colors.pink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _showOrderDetails(Map<String, dynamic> data, bool isEn) {
    // Traduction rapide du statut pour la modale
    final rawStatus = data['deliveryStatus'].toString().toLowerCase();
    String displayStatus;
    if (rawStatus == 'shipped') {
      displayStatus = isEn ? "SHIPPED" : "EXPÉDIÉE";
    } else if (rawStatus == 'delivered')
      displayStatus = isEn ? "DELIVERED" : "LIVRÉE";
    else if (rawStatus == 'cancelled')
      displayStatus = isEn ? "CANCELLED" : "ANNULÉE";
    else
      displayStatus = isEn ? "IN PROGRESS" : "EN COURS";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                isEn ? "Order Details" : "Détails de la commande",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Divider(height: 30),
              _detailRow(
                isEn ? "Status" : "Statut",
                displayStatus, // On utilise la version traduite ici
              ),
              _detailRow(
                "Date",
                DateFormat(
                  'dd MMMM yyyy HH:mm',
                  isEn ? 'en_US' : 'fr_FR',
                ).format((data['orderDate'] as Timestamp).toDate()),
              ),
              const SizedBox(height: 20),
              Text(
                isEn ? "Items" : "Articles",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (data['items'] != null)
                ...(data['items'] as List).map((it) {
                  final String itemTitle = isEn
                      ? (it['title_en'] ??
                            it['name_en'] ??
                            it['title'] ??
                            'Product')
                      : (it['title'] ?? 'Produit');

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: (it['imageUrl'] != null && it['imageUrl'] != "")
                        ? Image.network(it['imageUrl'], width: 40)
                        : const Icon(Icons.image),
                    title: Text(itemTitle),
                    subtitle: Text(
                      "${isEn ? 'Quantity' : 'Quantité'}: ${it['quantity']}",
                    ),
                    trailing: Text("${it['price']} DA"),
                  );
                }),
              const Divider(),
              _detailRow(
                isEn ? "Products Total" : "Total Produits",
                "${data['totalProducts']} DA",
              ),
              _detailRow(
                isEn ? "Delivery Fee" : "Frais livraison",
                "${data['deliveryFee']} DA",
              ),
              _detailRow(
                "TOTAL",
                "${data['totalWithDelivery']} DA",
                isBold: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.pink : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() => Center(
    child: GestureDetector(
      onTap: _pickProfileImage,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.pinkAccent.shade100,
            backgroundImage: profileImageUrl != null
                ? MemoryImage(base64Decode(profileImageUrl!))
                : null,
            child: profileImageUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 50)
                : null,
          ),
          const Positioned(
            bottom: 0,
            right: 4,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.pink,
              child: Icon(Icons.edit, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String key,
  ) {
    bool isReadOnly = (key == 'email');

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,

            readOnly: isReadOnly,

            keyboardType: key == 'phone'
                ? TextInputType.phone
                : TextInputType.text,

            inputFormatters: key == 'phone'
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ]
                : null,

            decoration: _inputDecoration(label).copyWith(enabled: !isReadOnly),

            style: TextStyle(color: isReadOnly ? Colors.grey : Colors.black),

            onChanged: (v) {
              if (!isReadOnly) {
                _saveField(key, v);
              }
            },

            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Champ requis";
              }

              // Validation téléphone algérien
              if (key == 'phone') {
                if (!RegExp(r'^0[567]\d{8}$').hasMatch(value)) {
                  return "Numéro invalide";
                }
              }

              // Validation adresse : commence par un numéro
              if (key == 'addressLine') {
                if (!RegExp(r'^\d+\s+.+').hasMatch(value)) {
                  return "L'adresse doit commencer par un numéro";
                }
              }

              return null;
            },
          ),
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 24,
          child: isReadOnly
              ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
              : AnimatedOpacity(
                  opacity: _showSavedCheck[key] == true ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAddressSection(bool isEn, String sectionTitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sectionTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextFormField(
          controller: addressLineController,
          decoration: _inputDecoration(isEn ? 'Address' : 'Adresse'),
          onChanged: (v) => _saveField('addressLine', v),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: cityType.isEmpty ? null : cityType,
                decoration: _inputDecoration(isEn ? 'Wilaya' : 'Wilaya'),
                items: wilayasAlgerie
                    .map(
                      (wilaya) => DropdownMenuItem<String>(
                        value: wilaya['id'],
                        child: Text(wilaya['name']!),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => cityType = value);
                    _saveField('city', value);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkinSection(bool isEn, String title) {
    final List<String> displaySkinOptions = isEn
        ? ["Normal", "Dry", "Oily", "Combination"]
        : skinOptions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildChoiceChipsBilingual(
          displaySkinOptions,
          skinOptions,
          skinType,
          isEn, // 💡 1. On passe la langue ici en 4ème position
          (v) {
            // 💡 2. Plus de "as bool", on laisse la fonction normale
            setState(() => skinType = v);
            _saveField('skinType', v);
          },
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 8,
            left: 4,
          ), // Légèrement augmenté le top pour respirer
          child: InkWell(
            onTap: () async {
              final String? result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SkinQuizPage()),
              );
              if (result != null && mounted) {
                setState(() => skinType = result);
                _saveField('skinType', result);
              }
            },
            child: Text(
              isEn
                  ? "Don't know your skin type? Click here"
                  : "Tu ne connais pas ton type de peau ? Clique ici",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.pink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    ); // N'oublie pas de fermer la Column si ce n'était pas fait dans ton copier-coller
  }

  Widget _buildHairSection(bool isEn, String title) {
    final List<String> dispTextures = isEn
        ? ["Straight", "Wavy", "Curly", "Coily", "Kinky"]
        : hairTextures;
    final List<String> dispStates = isEn
        ? ["Dry", "Normal", "Oily", "Mixed"]
        : hairStates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(
          isEn ? 'Hair Structure' : 'Structure du cheveu',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        _buildChoiceChipsBilingual(
          dispTextures,
          hairTextures,
          hairTexture,
          isEn, // 💡 1. On passe la langue ici
          (v) {
            // 💡 2. Plus de "as bool", la fonction est propre
            setState(() => hairTexture = v);
            _saveField('hairTexture', v);
          },
        ),
        const SizedBox(
          height: 15,
        ), // Légèrement augmenté pour espacer les deux sous-sections
        Text(
          isEn ? 'Hair Condition' : 'État du cheveu',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        _buildChoiceChipsBilingual(
          dispStates,
          hairStates,
          hairState,
          isEn, // 💡 1. On passe la langue ici aussi
          (v) {
            // 💡 2. Plus de "as bool" ici non plus
            setState(() => hairState = v);
            _saveField('hairState', v);
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection(String label) => DropdownButtonFormField<String>(
    initialValue: selectedLanguage,
    items: languages.map((l) {
      // On définit ce qui sera affiché à l'écran
      String displayName = l;
      if (l == 'Anglais') {
        displayName = 'English';
      }

      return DropdownMenuItem<String>(
        value: l, // Garde "Anglais" pour la logique interne et Firebase
        child: Text(displayName), // Affiche "English" à l'utilisateur
      );
    }).toList(),
    onChanged: (v) {
      if (v != null) {
        setState(() => selectedLanguage = v);
        _saveField('selectedLanguage', v);
        Provider.of<LanguageProvider>(context, listen: false).setLanguage(v);
      }
    },
    decoration: _inputDecoration(label),
  );

  Widget _buildChoiceChipsBilingual(
    List<String> displayLabels,
    List<String> technicalValues,
    String?
    selectedValue, // 🟢 MODIFIÉ : Devient String? pour accepter le null de Firestore
    bool isEn, // 💡 NOUVEAU : Reçoit la langue pour la BottomSheet
    Function(String) onSelected,
  ) {
    return Wrap(
      spacing: 8,
      children: List.generate(displayLabels.length, (index) {
        final label = displayLabels[index];
        final techVal = technicalValues[index];

        // 🟢 SÉCURITÉ : Nettoyage des chaînes (minuscules et sans espaces) pour éviter le piège des casses
        final isSelected =
            selectedValue != null &&
            selectedValue.toLowerCase().trim() == techVal.toLowerCase().trim();

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          selectedColor: Colors.pink,
          backgroundColor: Colors.pink.shade50,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.pink,
            fontWeight: FontWeight.bold,
          ),
          onSelected: (bool selected) {
            // 1. On applique le changement d'état classique (qui sauvegarde en FR dans Firebase)
            onSelected(techVal);

            // 2. Si la puce est sélectionnée, on affiche l'explication
            if (selected) {
              _showChipExplanation(context, techVal, isEn);
            }
          },
        );
      }),
    );
  }

  void _showChipExplanation(BuildContext context, String chipValue, bool isEn) {
    final info = chipExplanations[chipValue];
    if (info == null)
      return; // Si aucune explication n'est configurée pour cette puce

    final lang = isEn ? "en" : "fr";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Petite barre visuelle pour indiquer qu'on peut glisser vers le bas pour fermer
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Titre de l'explication
              Text(
                info["title"][lang],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Image illustrative (Optionnelle)
              if (info["image"] != null)
                Image.asset(info["image"], height: 120, fit: BoxFit.contain),
              const SizedBox(height: 15),

              // Texte descriptif
              Text(
                info["desc"][lang],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.pink.shade50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  Future<void> _saveField(String key, dynamic value) async {
    // 1. Sauvegarde locale immédiate (pour la rapidité)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);

    // 2. Feedback visuel (le petit check vert)
    _showTemporaryCheck(key);

    // 3. Sauvegarde distante (Firestore)
    if (userId.isNotEmpty) {
      await _firestore.collection('users').doc(userId).set({
        key: value,
      }, SetOptions(merge: true));
    }
  }

  // Petite fonction utilitaire pour le check vert si tu ne l'as pas déjà
  void _showTemporaryCheck(String key) {
    setState(() => _showSavedCheck[key] = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSavedCheck[key] = false);
    });
  }

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 250,
      maxHeight: 250,
      imageQuality: 60,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _saveField('profileImageUrl', base64Encode(bytes));
  }
}

class AnimatedMerci extends StatelessWidget {
  final String text;
  const AnimatedMerci({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 40),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.pink,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StarRating extends StatefulWidget {
  final Function(int) onRated;
  const StarRating({super.key, required this.onRated});

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return TweenAnimationBuilder<double>(
          // Délai progressif pour chaque étoile (effet cascade)
          duration: Duration(milliseconds: 400 + (index * 150)),
          curve: Curves.easeOutBack,
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: () {
                  if (_selectedRating == 0) {
                    // Empêche de voter deux fois
                    setState(() => _selectedRating = index + 1);
                    // On attend la fin de l'animation visuelle avant de callback
                    Future.delayed(const Duration(milliseconds: 700), () {
                      widget.onRated(index + 1);
                    });
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    index < _selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
