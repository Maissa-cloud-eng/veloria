import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veloria/presentation/controllers/wishlist_controller.dart';
import 'package:veloria/presentation/pages/public/product_page.dart';
import 'package:veloria/presentation/states/language_provider.dart';
import '../../../domain/entities/product.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistController = context.watch<WishlistController>();
    final wishlist = wishlistController.items;

    // Récupération de la langue
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isEn = languageProvider.selectedLanguage == 'Anglais';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEn ? "My Wishlist" : "Mes favoris",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: wishlist.isEmpty
          ? Center(
              child: Text(
                isEn ? "No favorites yet 💗" : "Aucun favori pour le moment 💗",
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final Product product = wishlist[index];

                // --- LOGIQUE DE TRADUCTION CONSERVÉE ---
                final String displayTitle = isEn
                    ? (product.titleEn.trim().isNotEmpty
                          ? product.titleEn
                          : product.title)
                    : product.title;

                // --- AJOUT DU DISMISSIBLE POUR LE GLISSEMENT ---
                return Dismissible(
                  key: Key(product.id), // Clé unique obligatoire
                  direction: DismissDirection
                      .endToStart, // Glissement de droite à gauche
                  // Le fond rouge avec l'icône poubelle qui apparaît au glissement
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  // Action déclenchée après le glissement complet
                  onDismissed: (direction) {
                    wishlistController.toggleFavorite(product);

                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isEn
                              ? "Removed from favorites"
                              : "Retiré des favoris",
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },

                  // Ton design de carte actuel
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductPage(product: product),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.pink.shade100,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Image produit
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: (product.imageUrl.isNotEmpty)
                                  ? (product.imageUrl.startsWith('http')
                                        ? Image.network(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, _, __) =>
                                                const Icon(Icons.broken_image),
                                          )
                                        : Image.asset(
                                            product.imageUrl,
                                            fit: BoxFit.cover,
                                          ))
                                  : const Icon(Icons.image_not_supported),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Infos produit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.price.isNotEmpty
                                      ? "${product.price} DA"
                                      : "-",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.pink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Icône poubelle cliquable (on la garde pour doubler les options)
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 22,
                            ),
                            onPressed: () {
                              wishlistController.toggleFavorite(product);

                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEn
                                        ? "Removed from favorites"
                                        : "Retiré des favoris",
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
