import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veloria/core/i18n/app_text.dart';
import 'package:veloria/domain/entities/product.dart';
import 'package:veloria/presentation/pages/public/product_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';

class RangeSection extends StatelessWidget {
  final List<Product> products;
  final bool isEn;
  final Function(Product) onAddToCart;

  const RangeSection({
    super.key,
    required this.products,
    required this.isEn,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isAr = languageProvider.isAr;
    final displayProducts = products.take(2).toList();
    if (displayProducts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // On réduit l'espace ici au strict minimum
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: Divider(thickness: 0.5, color: Color(0xFFEEEEEE)),
        ),
        Text(
          context.t("product.sameRange"),
          style: const TextStyle(
            fontSize: 18, // Légèrement plus petit pour faire moins "gros titre"
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(
          height: 2,
        ), // Très peu d'espace entre titre et sous-titre
        Text(
          context.t("product.completeRoutine"),
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 16),
        // ... la suite de ton Row avec les produits
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          // MainAxisAlignment.spaceBetween permet de pousser les produits vers les bords
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayProducts.map((p) {
            return Container(
              // On calcule la largeur pour qu'elle soit dynamique :
              // On prend la largeur totale, on enlève les paddings extérieurs de ta page (32)
              // et l'espace entre les deux produits (12), puis on divise par 2.
              width: (MediaQuery.of(context).size.width - 44) / 2,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductPage(product: p)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            p.imageUrl,
                            height:
                                160, // Tu peux baisser à 150 si tu trouves ça trop haut
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: InkWell(
                            onTap: p.isOutOfStock ? null : () => onAddToCart(p),
                            child: Container(
                              padding: const EdgeInsets.all(
                                6,
                              ), // Un peu plus petit pour gagner de la place
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: p.isOutOfStock
                                    ? Colors.grey
                                    : Colors.pink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr && p.titleAr.trim().isNotEmpty
                          ? p.titleAr
                          : isEn
                          ? p.titleEn
                          : p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize:
                            12, // On baisse à 12 pour éviter que le texte ne prenne trop de place
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppText.formatPrice(
                        Provider.of<LanguageProvider>(
                          context,
                          listen: false,
                        ).languageCode,
                        p.price,
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
