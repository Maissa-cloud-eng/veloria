import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart'; // Import ajouté
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/presentation/pages/admin/analytics_helper.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/states/language_provider.dart'; // Import ajouté
import 'package:veloria/presentation/pages/public/profile_page.dart';

const Color _kPrimaryPink = Colors.pink;
final Color _kLightPinkBackground = Colors.pink.shade50;

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double total;

  const CheckoutPage({super.key, required this.cartItems, required this.total});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();

  String _priceLabel(Object? value) {
    final languageCode = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;
    return AppText.formatPrice(languageCode, value);
  }

  String _tr(String key) {
    final languageCode = Provider.of<LanguageProvider>(
      context,
      listen: false,
    ).languageCode;
    return AppText.t(languageCode, key);
  }

  final Map<String, TextEditingController> _controllers = {
    'name': TextEditingController(),
    'email': TextEditingController(),
    'phone': TextEditingController(),
    'city': TextEditingController(),
    'addressLine': TextEditingController(),
    'postalCode': TextEditingController(),
  };

  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool useExistingData = false;

  String? deliveryType;
  Map<String, dynamic>? selectedBureau;
  double deliveryFee = 0;
  Map<String, dynamic>? wilayaData;
  bool _isLinkingGoogle = false;
  bool _isLinkingApple = false;

  void _showAuthSuccess(bool isEn) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tr("checkout.authSuccess"),
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

  Future<void> _linkWithGoogle() async {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEn;

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
          user = (await FirebaseAuth.instance.signInWithCredential(
            credential,
          )).user;
        } else {
          rethrow;
        }
      }

      if (user != null) {
        await _loadUserData(explicitUid: user.uid);

        if (mounted) {
          setState(() {});
          _showAuthSuccess(isEn);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr("checkout.authFailed")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
  }

  Future<void> _linkWithApple() async {
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEn;

    setState(() => _isLinkingApple = true);

    try {
      final rawNonce = List.generate(32, (_) {
        const chars =
            '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';

        return chars[Random.secure().nextInt(chars.length)];
      }).join();

      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final credential = OAuthProvider("apple.com").credential(
        idToken: apple.identityToken ?? '',
        rawNonce: rawNonce,
        accessToken: apple.authorizationCode,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user == null) return;

      String? appleName;

      if (apple.givenName != null || apple.familyName != null) {
        appleName = '${apple.givenName ?? ''} ${apple.familyName ?? ''}'.trim();
      }

      String? email = apple.email ?? user.email;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (!doc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': appleName ?? "Utilisateur Apple",
          'email': email ?? '',
          'isAnonymous': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'isAnonymous': false,

              if ((data?['email'] ?? '').toString().isEmpty)
                'email': email ?? '',

              if ((data?['name'] ?? '').toString().isEmpty)
                'name': appleName ?? '',
            });
      }

      if (email != null && email.isNotEmpty) {
        _controllers['email']!.text = email;
      }

      if (appleName != null && appleName.isNotEmpty) {
        _controllers['name']!.text = appleName;
      }

      await _loadUserData(explicitUid: user.uid);

      if (mounted) {
        setState(() {
          if (_controllers['city']!.text.isNotEmpty) {
            useExistingData = true;
          }
        });

        _showAuthSuccess(isEn);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr("checkout.authFailed")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLinkingApple = false;
          isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    print("🚨 CHECKOUT DISPOSE");

    for (var controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  Future<void> _loadUserData({String? explicitUid}) async {
    // Et remplace les deux premières lignes par ça :
    final uid = explicitUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Reste de ta fonction inchangé (tu remplaces juste user.uid par uid)...
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid) // ➔ Utilise uid ici
        .get();

    if (doc.exists) {
      userData = doc.data();

      // On remplit les contrôleurs
      _controllers['name']!.text = userData?['name'] ?? '';
      _controllers['email']!.text = userData?['email'] ?? '';
      _controllers['phone']!.text = userData?['phone'] ?? '';
      _controllers['city']!.text = userData?['city'] ?? '';
      _controllers['addressLine']!.text = userData?['addressLine'] ?? '';
      _controllers['postalCode']!.text = userData?['postalCode'] ?? '';

      // RÉPARATION ICI :
      // Si la ville venant du profil n'est pas vide, on appelle la fonction de livraison tout de suite
      if (_controllers['city']!.text.isNotEmpty &&
          _controllers['addressLine']!.text.isNotEmpty) {
        useExistingData = true;

        await _loadDeliveryData(_controllers['city']!.text);
      } else {
        useExistingData = false;
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDeliveryData(String wilayaId) async {
    final formattedId = wilayaId.trim().toLowerCase();
    if (formattedId.isEmpty) return;

    final doc = await FirebaseFirestore.instance
        .collection('delivery_fees')
        .doc(formattedId)
        .get();

    if (doc.exists) {
      setState(() {
        wilayaData = doc.data();
        deliveryType = null;
        deliveryFee = 0;
        selectedBureau = null;
      });
    }
  }

  void _showLoginRequiredDialog(bool isEn) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(_tr("checkout.loginRequired"), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _tr("checkout.loginRequiredBody"),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // --- 1. BOUTON APPLE COPIÉ DU PROFIL (POP-UP) ---
            if (Platform.isIOS) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLinkingApple ? null : _linkWithApple,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _isLinkingApple
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
                        isEn ? "Continue with Apple" : "Continuer avec Apple",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // --- 2. BOUTON GOOGLE ---
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Ferme la pop-up
                _linkWithGoogle(); // Lance la connexion Google
              },
              icon: Image.asset('assets/google_icon.png', height: 18),
              label: Text(_tr("checkout.continueGoogle")),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(
                  double.infinity,
                  45,
                ), // Légèrement ajusté pour matcher le bouton Apple
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    final isEn = Provider.of<LanguageProvider>(context, listen: false).isEn;

    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(isEn);
      return;
    }
    // ------------------------------------------------

    // La suite de ton code actuel (Validation du formulaire, frais de port, etc.)
    if (!useExistingData && !_formKey.currentState!.validate()) return;

    if (deliveryType == null ||
        (deliveryType == "bureau" && selectedBureau == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_tr("checkout.selectDelivery"))));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.pink)),
    );

    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}

      final timestamp = FieldValue.serverTimestamp();
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final userSnap = await userRef.get();

      // --- RÉCUPÉRATION DE L'HISTORIQUE DE NOTATION ---

      // --- LOGIQUE ANTI-DOUBLON DE NOTATION (Même commande + Historique) ---
      Set<String> alreadyInThisOrder = {};

      final List<Map<String, dynamic>> itemsWithBrand = widget.cartItems.map((
        item,
      ) {
        final String pId = item['productId'] ?? '';

        // Un produit est marqué comme "Déjà noté" si :
        // 1. Il est déjà dans l'historique du compte (ratedProducts)
        // 2. OU il a déjà été croisé plus haut dans cette même liste d'articles

        // On ajoute l'ID au Set pour le prochain tour de boucle (gestion doublons même commande)
        if (pId.isNotEmpty) alreadyInThisOrder.add(pId);

        return {
          'productId': pId,
          'title': item['title'] ?? 'Produit',
          'title_en': item['title_en'] ?? item['titleEn'] ?? item['title'],
          'title_ar': item['title_ar'] ?? item['titleAr'] ?? item['title'],
          'brand': item['brand'] ?? _tr("cart.unknownBrand"),
          'price': double.tryParse(item['price'].toString()) ?? 0.0,
          'quantity': int.tryParse(item['quantity'].toString()) ?? 1,
          'costPrice':
              double.tryParse(item['costPrice']?.toString() ?? '0') ?? 0.0,
          'imageUrl': item['imageUrl'] ?? '',
          'variantName': item['variantName'],
          // 'isRated': shouldBeMarkedAsRated, // LA LOGIQUE EST ICI
          'isRated': false,
        };
      }).toList();

      final double finalTotalWithShipping = widget.total + deliveryFee;
      final analyticsContext = await getAnalyticsContext();
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Mise à jour Profil
      Map<String, dynamic> userUpdateData = {
        'name': _controllers['name']!.text.trim(),
        'email': _controllers['email']!.text.trim(),
        'phone': _controllers['phone']!.text.trim(),
        'addressLine': _controllers['addressLine']!.text.trim(),
        'city': _controllers['city']!.text.trim(),
        'postalCode': _controllers['postalCode']!.text.trim(),
        'totalOrdersCount': FieldValue.increment(1),
        'lastOrderDate': timestamp,
      };

      if (userSnap.exists && !userSnap.data()!.containsKey('firstPurchaseAt')) {
        userUpdateData['firstPurchaseAt'] = timestamp;
        userUpdateData['ratingPopupShown'] = false;
      }

      batch.set(userRef, userUpdateData, SetOptions(merge: true));

      // Création Commande
      DocumentReference orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc();
      batch.set(orderRef, {
        'userId': user.uid,
        'items': itemsWithBrand,
        'deliveryType': deliveryType,
        'selectedBureau': selectedBureau,
        'deliveryFee': deliveryFee,
        'totalProducts': widget.total,
        'totalWithDelivery': finalTotalWithShipping,
        'deliveryStatus': 'pending',
        'fcmToken': fcmToken,
        'status': 'ordered',
        'orderDate': timestamp,
        'analyticsSessionId': analyticsContext['sessionId'],
        'analyticsDeviceId': analyticsContext['deviceId'],
        'shippingInfo': {
          'name': _controllers['name']!.text.trim(),
          'phone': _controllers['phone']!.text.trim(),
          'city': _controllers['city']!.text.trim(),
        },
      });

      // Vider Panier
      DocumentReference cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid);
      batch.set(cartRef, {
        'items': [],
        'lastOrderItems': itemsWithBrand,
        'status': 'ordered',
        'updatedAt': timestamp,
      }, SetOptions(merge: true));

      await batch.commit();
      await logEvent(
        'purchase_completed',
        extra: {
          'orderId': orderRef.id,
          'totalProducts': widget.total,
          'totalWithDelivery': finalTotalWithShipping,
        },
      );
      if (!mounted) return;
      // C'est cette ligne qui tue le badge "1" définitivement après l'achat
      Provider.of<CartController>(context, listen: false).setCount(0);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tr("checkout.orderConfirmed")),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.isEn;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.pink)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tr("checkout.title"),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // On simplifie ici :
          // Si on a déjà les données (user connecté et profil chargé), on montre la carte.
          // Sinon, on montre le formulaire (qui contiendra le bouton Google ET les champs ville/adresse).
          if (useExistingData && FirebaseAuth.instance.currentUser != null)
            _buildUserCard(isEn)
          else
            _buildForm(isEn),

          const Divider(height: 40),
          if (wilayaData != null)
            _buildDeliverySelector(wilayaData!, isEn)
          else if (_controllers['city']!.text.isNotEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            ),
          const SizedBox(height: 20),
          _buildCartSummary(isEn),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _confirmOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: Text(
              _tr("checkout.confirmOrder"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildForm(bool isEn) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isRealUser = currentUser != null && !currentUser.isAnonymous;

    // --- LOGIQUE DU LABEL DYNAMIQUE (REMISE ICI) ---
    String addressLabel = _tr("checkout.exactAddress");
    if (deliveryType == "bureau") {
      addressLabel += " (${_tr("checkout.optional")})";
    }
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // <-- LE CROCHET DOIT ÊTRE ICI
          // --- BLOC IDENTITÉ (CONDITIONNEL) ---
          if (!isRealUser) ...[
            _buildLoginPrompt(isEn),
            const SizedBox(height: 10),
          ] else ...[
            _buildTextField('name', _tr("checkout.fullName"), isEn),
            _buildTextField('email', _tr("checkout.email"), isEn),
            _buildTextField('phone', _tr("checkout.phone"), isEn),
          ],

          const SizedBox(height: 10),

          // --- PARTIE TOUJOURS VISIBLE ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _controllers['city']!.text.isEmpty
                  ? null
                  : _controllers['city']!.text,
              decoration: InputDecoration(
                labelText: _tr("checkout.city"),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: wilayasAlgerie.map((wilaya) {
                return DropdownMenuItem<String>(
                  value: wilaya['id'],
                  child: Text(wilaya['name']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _controllers['city']!.text = value);
                  _loadDeliveryData(value);
                }
              },
              validator: (value) => (value == null || value.isEmpty)
                  ? _tr("checkout.chooseWilaya")
                  : null,
            ),
          ),
          _buildTextField(
            'addressLine',
            addressLabel,
            isEn,
            customValidator: (value) {
              if (deliveryType == "domicile" &&
                  (value == null || value.isEmpty)) {
                return _tr("checkout.addressRequired");
              }
              return null;
            },
          ),
        ], // <-- ON FERME LA COLUMN ICI
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label,
    bool isEn, {
    String? Function(String?)? customValidator,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    final bool isReadOnly =
        key == 'email' &&
        (user != null && user.email != null && user.email!.isNotEmpty);

    TextInputType keyboardType = TextInputType.text;

    List<TextInputFormatter>? inputFormatters;

    if (key == 'phone') {
      keyboardType = TextInputType.phone;

      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[key],
        readOnly: isReadOnly,

        keyboardType: keyboardType,
        inputFormatters: inputFormatters,

        style: TextStyle(
          color: isReadOnly ? Colors.grey.shade600 : Colors.black,
        ),

        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isReadOnly ? Colors.grey.shade200 : Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isReadOnly ? Colors.grey.shade300 : Colors.grey.shade400,
            ),
          ),

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),

        validator:
            customValidator ??
            (value) {
              if (value == null || value.trim().isEmpty) {
                return _tr("checkout.requiredField");
              }

              // Validation téléphone
              if (key == 'phone') {
                if (!RegExp(r'^0[567]\d{8}$').hasMatch(value)) {
                  return _tr("checkout.invalidPhone");
                }
              }

              // Validation adresse
              if (key == 'addressLine') {
                if (!RegExp(r'^\d+\s+.+').hasMatch(value)) {
                  return _tr("checkout.addressMustStartNumber");
                }
              }

              return null;
            },
      ),
    );
  }

  Widget _buildUserCard(bool isEn) {
    return Card(
      color: Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _tr("checkout.shippingInfo"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => useExistingData = false),
                  child: Text(
                    _tr("checkout.edit"),
                    style: const TextStyle(color: Colors.pink),
                  ),
                ),
              ],
            ),
            Text(
              _controllers['name']?.text ?? "",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(_controllers['phone']?.text ?? ""),
            Text(
              "${_controllers['addressLine']?.text ?? ""}, ${_controllers['city']?.text ?? ""}",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySelector(Map<String, dynamic> data, bool isEn) {
    final bureaux = List<Map<String, dynamic>>.from(data['bureaux'] ?? []);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tr("checkout.deliveryOption"),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              RadioListTile<String>(
                title: Text(
                  "${_tr("checkout.homeDelivery")} (${_priceLabel(data['domicile'])})",
                ),
                value: "domicile",
                groupValue: deliveryType,
                activeColor: Colors.pink,
                onChanged: (val) => setState(() {
                  deliveryType = val;
                  deliveryFee = (data['domicile'] as num).toDouble();
                  selectedBureau = null;
                }),
              ),
              if (bureaux.isNotEmpty) ...[
                const Divider(height: 1),
                RadioListTile<String>(
                  title: Text(_tr("checkout.pickupPoint")),
                  value: "bureau",
                  groupValue: deliveryType,
                  activeColor: Colors.pink,
                  onChanged: (val) => setState(() {
                    deliveryType = val;
                    deliveryFee = 0;
                  }),
                ),
              ],
            ],
          ),
        ),
        if (deliveryType == "bureau" && bureaux.isNotEmpty) ...[
          // Gestion automatique du prix fixe (inchangée)
          (() {
            final defaultBureau = bureaux.first;
            if (selectedBureau != defaultBureau) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  selectedBureau = defaultBureau;
                  deliveryFee = (defaultBureau['price'] as num).toDouble();
                });
              });
            }
            return const SizedBox.shrink();
          })(),

          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kLightPinkBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kPrimaryPink.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Icône Camion
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: _kPrimaryPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Contenu texte textuel
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PETIT BADGE DE CONTEXTE
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: _kPrimaryPink.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _tr("checkout.officialCarrier"),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _kPrimaryPink,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),

                        Text(
                          _tr("checkout.pickupDelivery"),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // TEXTE AVEC LE NOM MIS EN VALEUR
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontFamily: 'Sans-Serif',
                            ), // Aligne sur ta font globale
                            children: [
                              TextSpan(text: _tr("checkout.collectPrefix")),
                              const TextSpan(
                                text: "Packers Dz",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors
                                      .orange, // Plus sombre pour ressortir du reste du texte
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Prix fixe
                  Text(
                    _priceLabel(bureaux.first['price']),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _kPrimaryPink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCartSummary(bool isEn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_tr("checkout.subtotal")),
              Text(
                _priceLabel(widget.total.toStringAsFixed(2)),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_tr("checkout.shippingFees")),
              Text(
                _priceLabel(deliveryFee.toStringAsFixed(2)),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _tr("checkout.total"),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                _priceLabel((widget.total + deliveryFee).toStringAsFixed(2)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(bool isEn) {
    return Card(
      color: Colors.pink.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.account_circle, size: 40, color: Colors.pink.shade300),
            const SizedBox(height: 10),
            Text(
              _tr("checkout.identificationRequired"),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 15),

            if (_isLinkingGoogle)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(color: Colors.pink),
                ),
              )
            else ...[
              if (Platform.isIOS) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLinkingApple ? null : _linkWithApple,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: const Size(double.infinity, 45),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _isLinkingApple
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
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
                          _tr("checkout.continueApple"),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // --- 2. BOUTON CONTINUER AVEC GOOGLE ---
              ElevatedButton.icon(
                onPressed: _linkWithGoogle,
                icon: Image.asset('assets/google_icon.png', height: 20),
                label: Text(
                  _tr("checkout.continueGoogle"),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  minimumSize: const Size(double.infinity, 45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
