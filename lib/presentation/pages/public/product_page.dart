import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/pages/admin/analytics_helper.dart';
import 'package:veloria/presentation/pages/public/cart_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import 'package:veloria/presentation/widgets/gamme_product.dart';

import '../../controllers/wishlist_controller.dart';
import '../../../domain/entities/product.dart';

class ProductPage extends StatefulWidget {
  final Product product;

  const ProductPage({required this.product, super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  FlavorOption? selectedFlavor;
  late Future<List<Product>> _similarProductsFuture;
  late Future<List<Product>> _rangeProductsFuture;

  void _handleAddToCart(Product p, {FlavorOption? flavor}) async {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    final bool isEn = languageProvider.selectedLanguage == "Anglais";

    logEvent('add_to_cart');
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
                ? "Connect to add to cart"
                : "Connectez-vous pour ajouter au panier",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // --- LOGIQUE NOM & VARIANTE ---
    final String variantName = flavor != null
        ? (isEn ? flavor.nameEn : flavor.name)
        : "";
    final String displayTitle = isEn ? p.titleEn : p.title;
    final String finalTitle = variantName.isNotEmpty
        ? "$displayTitle ($variantName)"
        : displayTitle;
    final String cartItemId = flavor != null ? "${p.id}_${flavor.name}" : p.id;

    context.read<CartController>().increment();

    // --- SNACKBAR TACTILE ---
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
                  "$finalTitle ${isEn ? 'added' : 'ajouté'}",
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

    // --- FIRESTORE ---
    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid);
    try {
      final cartDoc = await cartRef.get();
      List<Map<String, dynamic>> items = [];
      String currentStatus = '';

      if (cartDoc.exists) {
        final data = cartDoc.data();
        items = List<Map<String, dynamic>>.from(data?['items'] ?? []);
        currentStatus = data?['status'] ?? '';
      }

      final index = items.indexWhere((i) => i['cartItemId'] == cartItemId);

      if (index >= 0) {
        items[index]['quantity'] += 1;
      } else {
        items.add({
          'cartItemId': cartItemId,
          'productId': p.id,
          'title': p.title,
          'title_en': p.titleEn,
          'brand': p.brand,
          'price': p.price,
          'costPrice': p.costPrice,
          'quantity': 1,
          'imageUrl': flavor?.imageUrl ?? p.imageUrl,
          'variantName': flavor?.name,
          'variantNameEn': flavor?.nameEn,
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
      debugPrint("Erreur panier: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.product.flavorOptions != null &&
        widget.product.flavorOptions!.isNotEmpty) {
      selectedFlavor = widget.product.flavorOptions!.first;
    }
    _similarProductsFuture = fetchSimilarProducts();
    _rangeProductsFuture = fetchRangeProducts();
  }

  @override
  void dispose() {
    logEvent('last_seen_product');
    super.dispose();
  }

  Future<List<Product>> fetchRangeProducts() async {
    // 1. On cherche le tag qui commence par "gamme_"
    // On utilise .firstWhereOrNull si tu as importé collection, sinon un simple try/catch ou une boucle
    String? rangeTag;

    for (var tag in widget.product.tags) {
      if (tag.toLowerCase().trim().startsWith("gamme_")) {
        rangeTag = tag;
        break;
      }
    }

    // Si le produit n'a pas de tag de gamme, on arrête là
    if (rangeTag == null) return [];

    // 2. On récupère les autres produits qui ont EXACTEMENT ce tag
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('tags', arrayContains: rangeTag)
        .limit(10)
        .get();

    // 3. On transforme en liste de produits en excluant le produit actuel
    return snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .where((p) => p.id != widget.product.id)
        .toList();
  }

  Future<List<Product>> fetchSimilarProducts() async {
    print("--- DEBUG SIMILARITÉ ---");
    print("Produit actuel : ${widget.product.title}");
    print(
      "Sous-catégorie : ${widget.product.subCategory} | Origine : ${widget.product.origin}",
    );

    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('category', isEqualTo: widget.product.category)
        .limit(25) // On élargit un peu pour avoir plus de choix à trier
        .get();

    List<Product> allCandidates = snapshot.docs
        .map((doc) => Product.fromFirestore(doc))
        .where((p) => p.id != widget.product.id)
        .toList();

    final currentTags = widget.product.tags
        .map((t) => t.toLowerCase().trim())
        .toSet();

    // Création d'une Map pour stocker les détails du score (pour le debug)
    Map<String, String> debugScores = {};

    allCandidates.sort((a, b) {
      int scoreA = 0;
      int scoreB = 0;

      // --- Calcul Score A ---
      int subCatA = (a.subCategory == widget.product.subCategory) ? 10 : 0;
      int originA = (a.origin == widget.product.origin) ? 5 : 0;
      var tagsA = a.tags.map((t) => t.toLowerCase().trim()).toSet();
      int commonTagsA = tagsA.intersection(currentTags).length;
      scoreA = subCatA + originA + (commonTagsA * 2);

      debugScores[a.id] =
          "Score: $scoreA (SubCat: +$subCatA, Origin: +$originA, Tags: +${commonTagsA * 2})";

      // --- Calcul Score B ---
      int subCatB = (b.subCategory == widget.product.subCategory) ? 10 : 0;
      int originB = (b.origin == widget.product.origin) ? 5 : 0;
      var tagsB = b.tags.map((t) => t.toLowerCase().trim()).toSet();
      int commonTagsB = tagsB.intersection(currentTags).length;
      scoreB = subCatB + originB + (commonTagsB * 2);

      debugScores[b.id] =
          "Score: $scoreB (SubCat: +$subCatB, Origin: +$originB, Tags: +${commonTagsB * 2})";

      return scoreB.compareTo(scoreA);
    });

    // --- AFFICHAGE DU DEBUG DANS LA CONSOLE ---
    for (var i = 0; i < allCandidates.length && i < 6; i++) {
      var p = allCandidates[i];
      print("Top ${i + 1}: ${p.title} | ${debugScores[p.id]}");
    }
    print("------------------------");

    return allCandidates.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    // --- LOGIQUE BILINGUE ---
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.selectedLanguage == "Anglais";

    final String displayTitle = isEn
        ? widget.product.titleEn
        : widget.product.title;
    final String displayDesc = isEn
        ? widget.product.descriptionEn
        : widget.product.description;
    final String? displayTips = isEn
        ? widget.product.usageTipsEn
        : widget.product.usageTips;

    // Labels statiques
    final String variantLabel = isEn ? "Variants:" : "Variantes :";
    final String buyLabel = isEn ? "Buy" : "Acheter";
    final String tipsLabel = isEn ? "Usage Tips" : "Conseils d'utilisation";
    final String compoLabel = isEn ? "Composition" : "Composition";
    final String similarLabel = isEn
        ? "Similar Products"
        : "Produits similaires";
    final String noSimilarLabel = isEn
        ? "No similar products."
        : "Aucun produit similaire.";
    final String addedToCartMsg = isEn ? "added to cart" : "ajouté au panier";
    final String loginNeededMsg = isEn
        ? "Connect to add to cart"
        : "Connectez-vous pour ajouter au panier";

    final wishlist = context.watch<WishlistController>();
    final mainImage = selectedFlavor?.imageUrl ?? widget.product.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------- IMAGE PRINCIPALE AVEC ZOOM --------
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                // Pour éviter que l'image ne dépasse du cadre lors du zoom
                child: InteractiveViewer(
                  clipBehavior: Clip.none,
                  maxScale:
                      1.4, // Limite le zoom à 40% (1.0 = 100%, 1.4 = 140%)
                  minScale:
                      1.0, // Empêche de dézoomer plus petit que la taille initiale
                  child: mainImage.startsWith("http")
                      ? Image.network(
                          mainImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Image.asset(
                          mainImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- TITRE + FAVORI --------
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TITRE
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing:
                                    -0.5, // Donne un aspect plus "éditorial"
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 6),

                            // LIGNE D'INFOS SECONDAIRES (Marque • Contenu)
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (widget.product.brand != null &&
                                    widget.product.brand!.isNotEmpty)
                                  Text(
                                    widget.product.brand!,
                                    style: const TextStyle(
                                      fontSize: 16,

                                      fontWeight: FontWeight.bold,

                                      color: Colors.black54,
                                    ),
                                  ),

                                // Séparateur et Contenu (ex: 200ml)
                                if (widget.product.contents != null &&
                                    widget.product.contents!.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      "•",
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    // On vérifie si une unité spécifique existe, sinon on met ml
                                    "${widget.product.contents} ${widget.product.unit ?? 'ml'}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // FAVORI (Le cœur)
                      GestureDetector(
                        onTap: () => wishlist.toggleFavorite(widget.product),
                        child: Icon(
                          wishlist.isFavorite(widget.product)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: wishlist.isFavorite(widget.product)
                              ? Colors.red
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 20,
                  ), // Un peu plus d'espace avant la suite pour aérer
                  // -------- VARIANTES --------
                  if (widget.product.flavorOptions != null &&
                      widget.product.flavorOptions!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          variantLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: widget.product.flavorOptions!.map((
                              flavor,
                            ) {
                              final isSelected = flavor == selectedFlavor;
                              final String displayFlavorName = isEn
                                  ? flavor.nameEn
                                  : flavor.name;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedFlavor = flavor),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: flavor.color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? Colors.pink
                                                : Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayFlavorName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected
                                              ? Colors.pink
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),

                  // -------- PRIX --------
                  Text(
                    "${widget.product.price} DA",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -------- BOUTON ACHETER --------
                  SizedBox(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        disabledBackgroundColor:
                            Colors.grey.shade400, // Couleur grise
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: widget.product.isOutOfStock
                          ? null
                          : () async {
                              logEvent('add_to_cart');
                              final user = FirebaseAuth.instance.currentUser;

                              if (user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(loginNeededMsg),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              // --- PRÉPARATION DES NOMS BILINGUES POUR LA SNACKBAR ---
                              final String variantName = selectedFlavor != null
                                  ? (isEn
                                        ? selectedFlavor!.nameEn
                                        : selectedFlavor!.name)
                                  : "";
                              final String finalTitle = variantName.isNotEmpty
                                  ? "$displayTitle ($variantName)"
                                  : displayTitle;

                              // ID unique pour différencier les variantes dans le panier
                              final String cartItemId = selectedFlavor != null
                                  ? "${widget.product.id}_${selectedFlavor!.name}"
                                  : widget.product.id;

                              // Mise à jour du contrôleur
                              context.read<CartController>().increment();

                              // Affichage de la SnackBar tactile
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: InkWell(
                                    onTap: () {
                                      // On ferme la barre et on fonce au panier
                                      ScaffoldMessenger.of(
                                        context,
                                      ).hideCurrentSnackBar();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const CartPage(),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "$finalTitle $addedToCartMsg",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        // Un petit indicateur visuel pour montrer que c'est cliquable
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

                                // --- LOGIQUE ANTI-DOUBLON (Basée sur cartItemId) ---
                                final index = items.indexWhere(
                                  (i) => i['cartItemId'] == cartItemId,
                                );

                                if (index >= 0) {
                                  // Si la variante existe déjà, on augmente la quantité
                                  items[index]['quantity'] += 1;
                                } else {
                                  // Nouveau produit ou nouvelle variante : on stocke TOUT en bilingue
                                  items.add({
                                    'cartItemId': cartItemId,
                                    'productId': widget.product.id,
                                    'title': widget.product.title, // Français
                                    'title_en': widget
                                        .product
                                        .titleEn, // Anglais (Ajouté)
                                    'brand': widget.product.brand,
                                    'price': widget.product.price,
                                    'costPrice': widget.product.costPrice,
                                    'quantity': 1,
                                    'imageUrl':
                                        selectedFlavor?.imageUrl ??
                                        widget.product.imageUrl,
                                    'variantName':
                                        selectedFlavor?.name, // Français
                                    'variantNameEn': selectedFlavor
                                        ?.nameEn, // Anglais (Ajouté)
                                  });
                                }

                                // --- MISE À JOUR FIRESTORE ---
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
                                debugPrint("Erreur panier: $e");
                              }
                            },
                      // --- CHANGEMENT ICI : ICONE ---
                      icon: Icon(
                        widget.product.isOutOfStock
                            ? Icons.not_interested
                            : Icons.shopping_cart,
                        color: Colors.white,
                      ),
                      // --- CHANGEMENT ICI : TEXTE ---
                      label: Text(
                        widget.product.isOutOfStock
                            ? (isEn ? "OUT OF STOCK" : "RUPTURE DE STOCK")
                            : buyLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // -------- SECTION DESCRIPTION DYNAMIQUE --------
                  if (displayDesc.isNotEmpty)
                    MarkdownBody(
                      data: displayDesc,
                      styleSheet: MarkdownStyleSheet(
                        // Style pour le titre principal (#)
                        h1: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.4,
                        ),
                        // Style pour le corps de texte
                        p: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(
                            0xFF424242,
                          ), // Un gris très foncé pour le confort visuel
                        ),
                        // Style pour les listes et le gras (**)
                        strong: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        blockSpacing: 16.0, // Espace entre les paragraphes
                      ),
                    )
                  else
                    const Text("..."),

                  // -------- SECTION GAMME (COMPLÉTER LA ROUTINE) --------
                  FutureBuilder<List<Product>>(
                    future: _rangeProductsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        // ON APPELLE LA CLASSE RangeSection AU LIEU DE LA MÉTHODE
                        return RangeSection(
                          products: snapshot.data!,
                          isEn: isEn,
                          onAddToCart: (p) {
                            // Ici, tu appelles ta logique d'ajout au panier
                            _handleAddToCart(p);
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 34),
                  // -------- CONSEILS D'UTILISATION --------
                  if (displayTips != null && displayTips.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        tipsLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            displayTips,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                  // -------- COMPOSITION --------
                  if (widget.product.composition != null &&
                      widget.product.composition!.isNotEmpty)
                    ExpansionTile(
                      title: Text(
                        compoLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            widget.product.composition!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // -------- PRODUITS SIMILAIRES --------
                  Text(
                    similarLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  FutureBuilder<List<Product>>(
                    future: _similarProductsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final similar = snapshot.data ?? [];
                      if (similar.isEmpty) return Text(noSimilarLabel);

                      return SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similar.length,
                          itemBuilder: (_, index) {
                            final p = similar[index];
                            final String pTitle = isEn ? p.titleEn : p.title;
                            return GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductPage(product: p),
                                ),
                              ),
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.only(right: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        p.imageUrl,
                                        height: 110,
                                        width: 130,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      pTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${p.price} DA",
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.pink,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
