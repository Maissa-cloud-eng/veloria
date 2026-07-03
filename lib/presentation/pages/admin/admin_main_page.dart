import 'package:flutter/material.dart';
import 'package:veloria/presentation/pages/admin/CategoriesAdminPage.dart';
import 'package:veloria/presentation/pages/admin/DeliveryFeePage.dart';
import 'package:veloria/presentation/pages/admin/ReviewsAdminPage.dart';
import 'package:veloria/presentation/pages/admin/admin_dashboard.dart';
import 'package:veloria/presentation/pages/admin/banner_manager_page.dart';
import 'package:veloria/presentation/pages/admin/clics.dart';
import 'package:veloria/presentation/pages/admin/clientsPage.dart';
import 'package:veloria/presentation/pages/admin/commandes.dart';
import 'package:veloria/presentation/pages/admin/produit.dart';
// Importe tes futures pages ici :
// import 'admin_products_page.dart';
// import 'admin_orders_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  // Liste des pages du Dashboard
  final List<Widget> _pages = [
    const AnalyticsPage(), // Index 0
    const AdminOrdersPage(), // Index 1
    const ProductAdminScreen(), // Index 2
    const AdminMoreMenu(), // Index 3 : Le reste (Clients, Banners, Promos)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed, // Nécessaire pour plus de 3 icônes
        selectedItemColor: Colors.pink,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: "Analyses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: "Commandes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Produits",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: "Plus",
          ),
        ],
      ),
    );
  }
}

// Un petit widget pour le menu "Plus" afin de gérer Clients, Banners, et Promos
class AdminMoreMenu extends StatelessWidget {
  const AdminMoreMenu({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion Supplémentaire")),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        children: [
          _moreMenuItem(context, "Clients", Icons.people, Colors.blue, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientsPage()),
            );
          }),
          _moreMenuItem(
            context,
            "Avis Clients",
            Icons.star_rate_rounded, // Icône d'étoile pour les avis
            Colors.amber.shade700,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewsAdminPage(),
                ),
              );
            },
          ),
          // --- REMPLACEMENT DE RÉGLAGES PAR ANALYSES CLICS ---
          _moreMenuItem(
            context,
            "Analyses Clics", // Le nom de ton bouton
            Icons.bar_chart_rounded, // Icône de statistiques
            Colors.purple, // Couleur violette pour différencier
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClicksPage()),
              );
            },
          ),
          // ===== NOUVEAU BOUTON : GESTION DES BANNIÈRES =====
          _moreMenuItem(
            context,
            "Bannières App",
            Icons.view_carousel_rounded, // Superbe icône de carrousel
            Colors.pink, // Couleur rose alignée avec la charte de Veloria
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BannerManagerPage(),
                ),
              );
            },
          ),
          _moreMenuItem(
            context,
            "Catégories",
            Icons.category_rounded,
            Colors.orange,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesAdminPage(),
                ),
              );
            },
          ),
          _moreMenuItem(
            context,
            "Frais de Livraison",
            Icons.local_shipping_rounded,
            Colors.indigo,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeliveryFeePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _moreMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
