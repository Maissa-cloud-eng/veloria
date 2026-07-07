import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Import ajouté
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/presentation/controllers/cart_controllers.dart';
import 'package:veloria/presentation/pages/admin/analytics_helper.dart';
import 'package:veloria/presentation/pages/public/checkout_page.dart';
import 'package:veloria/presentation/pages/public/product_page.dart';
import 'package:veloria/presentation/states/language_provider.dart'; // Import ajouté

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

  double _calculateTotal(List items) {
    double sum = 0;
    for (var item in items) {
      String priceRaw = item['price']?.toString() ?? '0';
      String priceCleaned = priceRaw.replaceAll(RegExp(r'[^0-9.]'), '');
      final price = double.tryParse(priceCleaned) ?? 0;
      final qty = item['quantity'] ?? 1;
      sum += price * qty;
    }
    return sum;
  }

  Future<void> _removeItem(List items, int index) async {
    items.removeAt(index);
    await FirebaseFirestore.instance.collection('carts').doc(userId).update({
      'items': items,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // --- MISE À JOUR DU BADGE ---
    _updateBadge(items);
  }

  Future<void> _updateQuantity(List items, int index, int delta) async {
    if (delta == -1 && items[index]['quantity'] <= 1) {
      await _removeItem(items, index);
    } else {
      items[index]['quantity'] += delta;
      await FirebaseFirestore.instance.collection('carts').doc(userId).update({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // --- MISE À JOUR DU BADGE ---
      _updateBadge(items);
    }
  }

  // Petite fonction utilitaire pour recalculer le total d'articles
  void _updateBadge(List items) {
    int totalItems = 0;
    for (var item in items) {
      totalItems += (item['quantity'] as int? ?? 0);
    }
    // On prévient le CartController
    Provider.of<CartController>(context, listen: false).setCount(totalItems);
  }

  @override
  Widget build(BuildContext context) {
    // RÉCUPÉRATION DE LA LANGUE
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.isEn;
    final bool isAr = languageProvider.isAr;

    // TEXTES TRADUITS
    final String appBarTitle = context.t("cart.title");

    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(appBarTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildEmptyState();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List items = data['items'] ?? [];
          final String status = data['status'] ?? '';

          if (status == 'ordered' || items.isEmpty) {
            return _buildEmptyState();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Dismissible(
                        key: Key(item['productId'] ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) =>
                            _removeItem(List.from(items), index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _buildCartCard(item, items, index, isEn, isAr),
                      );
                    },
                  ),
                ),
                _buildSummary(items, isEn, isAr),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.pink.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            context.t("cart.empty"),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartCard(
    Map<String, dynamic> item,
    List allItems,
    int index,
    bool isEn,
    bool isAr,
  ) {
    String displayPrice = item['price'].toString();
    displayPrice = AppText.formatPrice(
      isAr ? 'ar' : (isEn ? 'en' : 'fr'),
      displayPrice.toUpperCase().contains('DA')
          ? displayPrice.replaceAll(RegExp(r'\s*DA', caseSensitive: false), '')
          : displayPrice,
    );

    // GESTION DU TITRE BILINGUE DANS LA CARTE
    final String displayTitle = isAr
        ? (item['title_ar'] ?? item['titleAr'] ?? item['title'] ?? 'Produit')
        : isEn
        ? (item['title_en'] ??
              item['titleEn'] ??
              item['nameEn'] ??
              item['title'] ??
              'Product')
        : (item['title'] ?? 'Produit');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        children: [
          // ➔ AJOUT DU GESTURE DETECTOR AUTOUR DU CONTENU CLIQUABLE
          GestureDetector(
            onTap: () async {
              final String? productId = item['productId'] ?? item['id'];
              if (productId != null && productId.isNotEmpty) {
                // 1. On affiche un petit indicateur de chargement ou on va chercher directement le produit complet
                final doc = await FirebaseFirestore.instance
                    .collection('products')
                    .doc(productId)
                    .get();

                if (doc.exists) {
                  // 2. On crée le PRODUIT COMPLET depuis la vraie collection 'products' !
                  final Product completeProduct = Product.fromFirestore(doc);

                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductPage(product: completeProduct),
                      ),
                    );
                  }
                }
              }
            },
            behavior: HitTestBehavior
                .opaque, // Rend toute la zone de la ligne cliquable
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item['imageUrl'] ?? '',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          displayPrice,
                          style: const TextStyle(
                            color: Colors.pink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ➔ NOTE : Les boutons +/- de quantité ont leur propre InkWell,
                        // ils ne déclencheront donc pas le clic vers la page produit.
                        Row(
                          children: [
                            _qtyBtn(
                              Icons.remove,
                              () => _updateQuantity(
                                List.from(allItems),
                                index,
                                -1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Text(
                                "${item['quantity']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _qtyBtn(
                              Icons.add,
                              () => _updateQuantity(
                                List.from(allItems),
                                index,
                                1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Petit espace à droite pour ne pas chevaucher l'icône poubelle du Stack
                  const SizedBox(width: 30),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              onPressed: () => _removeItem(List.from(allItems), index),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade300,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.pink.shade50,
        ),
        child: Icon(icon, size: 20, color: Colors.pink),
      ),
    );
  }

  Widget _buildSummary(List items, bool isEn, bool isAr) {
    final double totalAmount = _calculateTotal(items);
    return Container(
      padding: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.pink.shade100, width: 1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.t("cart.total"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                AppText.formatPrice(
                  isAr ? 'ar' : (isEn ? 'en' : 'fr'),
                  totalAmount.toStringAsFixed(2),
                ),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: items.isEmpty
                  ? null
                  : () async {
                      final user = FirebaseAuth.instance.currentUser;

                      await logEvent('reached_checkout');

                      if (user != null) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('carts')
                              .doc(user.uid)
                              .update({
                                'status': 'reached_checkout',
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                        } catch (e) {
                          debugPrint("Erreur update status checkout: $e");
                        }
                      }

                      if (!mounted) return;

                      // PRÉPARATION DES ITEMS AVEC TITRE ANGLAIS POUR LE CHECKOUT
                      final List<Map<String, dynamic>>
                      itemsForCheckout = items.map((item) {
                        return {
                          'productId': item['productId'] ?? item['id'] ?? '',
                          'title': item['title'] ?? 'Produit',
                          'title_en':
                              item['title_en'] ??
                              item['titleEn'] ??
                              item['title'],
                          'title_ar':
                              item['title_ar'] ??
                              item['titleAr'] ??
                              item['title'],
                          'brand':
                              item['brand'] ?? context.t("cart.unknownBrand"),
                          'price': item['price'] ?? 0,
                          'quantity': item['quantity'] ?? 1,
                          'costPrice': item['costPrice'] ?? 0,
                          'imageUrl': item['imageUrl'] ?? '',
                          'variantName': item['variantName'],
                        };
                      }).toList();

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CheckoutPage(
                              cartItems: itemsForCheckout,
                              total: totalAmount,
                            ),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Text(
                context.t("cart.checkout"),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
