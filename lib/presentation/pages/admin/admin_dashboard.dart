import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:veloria/presentation/pages/admin/AdminSuggestionsPage.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 1)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    final DateTime filterEnd = DateTime(
      _selectedDateRange.end.year,
      _selectedDateRange.end.month,
      _selectedDateRange.end.day,
      23,
      59,
      59,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        title: const Text(
          "Analyses Business",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            icon: const Icon(
              Icons.calendar_today,
              size: 18,
              color: Colors.pink,
            ),
            label: Text(
              "${DateFormat('dd MMM').format(_selectedDateRange.start)} - ${DateFormat('dd MMM').format(_selectedDateRange.end)}",
              style: const TextStyle(color: Colors.pink),
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime.now().add(const Duration(days: 1)),
                initialDateRange: _selectedDateRange,
              );
              if (picked != null) setState(() => _selectedDateRange = picked);
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, orderSnapshot) {
          if (!orderSnapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          // AJOUT DU STREAM CARTS POUR LE FUNNEL
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('carts').snapshots(),
            builder: (context, cartSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('visits')
                    .snapshots(),
                builder: (context, visitSnapshot) {
                  double totalCA = 0;
                  double totalProfit = 0;
                  int orderedCount = 0;
                  int totalVisits = 0;

                  // Variables pour le Funnel
                  int initiatedInCarts = 0;
                  int reachedInCarts = 0;

                  Map<String, int> productSales = {};
                  Map<String, int> userOrderCount = {};

                  final orderDocs = orderSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final dynamic ts = data['orderDate'];
                    if (ts == null || ts is! Timestamp) return false;
                    DateTime date = ts.toDate();
                    return date.isAfter(_selectedDateRange.start) &&
                        date.isBefore(filterEnd) &&
                        doc.id != "OE0N2pbyQjXdqG69FQXa";
                  }).toList();

                  int uniqueVisitsCount = 0;

                  if (visitSnapshot.hasData) {
                    final Map<String, bool> dailyUniqueMap = {};

                    for (var doc in visitSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final dynamic ts = data['timestamp'];
                      if (ts == null || ts is! Timestamp) continue;

                      DateTime date = ts.toDate();

                      if (date.isAfter(_selectedDateRange.start) &&
                          date.isBefore(filterEnd)) {
                        totalVisits++; // On garde le total des clics pour info

                        // --- CORRECTION ICI ---
                        // On essaye de trouver un identifiant stable pour l'invité
                        // Si tu n'as pas encore de 'deviceId' dans ta DB, utilise au moins le 'userId'
                        // S'il n'y a rien, on met 'guest' au lieu de 'anonymous_${doc.id}'
                        String visitorId =
                            data['userId'] ?? data['deviceId'] ?? 'GUEST';

                        // Clé unique par utilisateur ET par jour
                        String dayKey =
                            "${visitorId}_${date.year}${date.month}${date.day}";
                        dailyUniqueMap[dayKey] = true;
                      }
                    }

                    // Ici on a le vrai nombre d'humains uniques par jour cumulés
                    uniqueVisitsCount = dailyUniqueMap.length;
                  }
                  // 1. CALCUL DES DONNÉES DE COMMANDES RÉUSSIES
                  for (var doc in orderDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String status = data['deliveryStatus'] ?? '';

                    // --- AJOUT DE LA CONDITION DE FILTRAGE ---
                    if (status == 'cancelled') continue;
                    // ------------------------------------------

                    orderedCount++; // On ne compte que les commandes non annulées
                    String userId = data['userId'] ?? 'guest';
                    userOrderCount[userId] = (userOrderCount[userId] ?? 0) + 1;

                    double amount =
                        double.tryParse(
                          data['totalProducts']?.toString() ?? '0',
                        ) ??
                        0;
                    totalCA += amount;

                    final List items = data['items'] ?? [];
                    for (var item in items) {
                      double price =
                          double.tryParse(
                            item['price'].toString().replaceAll(
                              RegExp(r'[^0-9.]'),
                              '',
                            ),
                          ) ??
                          0;
                      double cost =
                          double.tryParse(
                            item['costPrice']?.toString() ?? '0',
                          ) ??
                          0;
                      int qty =
                          int.tryParse(item['quantity']?.toString() ?? '1') ??
                          1;
                      if (cost > 0) totalProfit += (price - cost) * qty;
                      productSales["${item['title']}|${item['brand']}"] =
                          (productSales["${item['title']}|${item['brand']}"] ??
                              0) +
                          qty;
                    }
                  }

                  // 2. CALCUL DES STATUTS DANS LA TABLE CARTS (FILTRÉS PAR DATE)
                  if (cartSnapshot.hasData) {
                    for (var doc in cartSnapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      // --- AJOUT DU FILTRE DE DATE ---
                      final dynamic ts =
                          data['updatedAt']; // Utilise le timestamp de ton choix
                      if (ts == null || ts is! Timestamp) continue;

                      DateTime date = ts.toDate();
                      // On vérifie si la date du panier est dans la plage sélectionnée
                      if (date.isAfter(_selectedDateRange.start) &&
                          date.isBefore(filterEnd)) {
                        final String status = data['status'] ?? '';
                        if (status == 'initiated') initiatedInCarts++;
                        if (status == 'reached_checkout') reachedInCarts++;
                      }
                      // -------------------------------
                    }
                  }

                  // LOGIQUE DU FUNNEL CUMULATIF
                  // Initiated = Ceux en cours dans carts + Ceux qui ont fini (orders)
                  int funnelInitiated =
                      initiatedInCarts + reachedInCarts + orderedCount;
                  // Reached = Ceux qui sont au checkout dans carts + Ceux qui ont fini (orders)
                  int funnelReached = reachedInCarts + orderedCount;
                  // Ordered = Uniquement ceux qui ont fini
                  int funnelOrdered = orderedCount;

                  double conversionRate = uniqueVisitsCount > 0
                      ? (orderedCount / uniqueVisitsCount) * 100
                      : 0;
                  double panierMoyen = orderedCount > 0
                      ? totalCA / orderedCount
                      : 0;
                  int repeatCustomers = userOrderCount.values
                      .where((count) => count > 1)
                      .length;
                  double repeatRate = userOrderCount.isNotEmpty
                      ? (repeatCustomers / userOrderCount.length) * 100
                      : 0;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildSmallStatCard(
                                "Commandes",
                                orderedCount.toString(),
                                Icons.shopping_bag,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildSmallStatCard(
                                "Visiteurs (Uniques)",
                                uniqueVisitsCount.toString(),
                                Icons.visibility,
                                subtitle:
                                    "$totalVisits sessions", // On ajoute le total ici
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildShopifyCard(
                          "Chiffre d'Affaires",
                          "${totalCA.toStringAsFixed(0)} DA",
                          "Bénéfice Net: ${totalProfit.toStringAsFixed(0)} DA",
                        ),
                        const SizedBox(height: 12),
                        _buildShopifyCard(
                          "Performance",
                          "Panier Moyen: ${panierMoyen.toStringAsFixed(0)} DA",
                          "Fidélité (Repeat): ${repeatRate.toStringAsFixed(1)}%",
                        ),
                        const SizedBox(height: 12),

                        // APPEL DU FUNNEL CORRIGÉ AVEC LES NOUVELLES VARIABLES
                        _buildConversionFunnel(
                          totalVisits,
                          funnelInitiated,
                          funnelReached,
                          funnelOrdered,
                          conversionRate,
                        ),

                        const SizedBox(height: 24),
                        const Text(
                          "🔥 Top Produits",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildTopProducts(productSales),
                        const SizedBox(height: 24),
                        const Text(
                          "💡 Suggestions Clients",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _buildSuggestedProducts(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGETS DE SUPPORT ---

  Widget _buildSmallStatCard(
    String title,
    String value,
    IconData icon, {
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.pink, size: 18),
              if (subtitle != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShopifyCard(String title, String value, String subValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            subValue,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversionFunnel(
    int visits,
    int init,
    int check,
    int ord,
    double rate,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Conversion",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${rate.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _funnelStep("Paniers initiés", init, Colors.blue.shade300),
          _funnelStep("Reached Checkout", check, Colors.orange.shade200),
          _funnelStep("Ventes confirmées", ord, Colors.green.shade300),
        ],
      ),
    );
  }

  Widget _funnelStep(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(label),
          const Spacer(),
          Text(
            value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(Map<String, int> sales) {
    if (sales.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Aucune vente"),
      );
    }
    var sorted = sales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.take(3).map((e) {
        List<String> parts = e.key.split('|');
        String productName = parts[0];
        String brandName = parts.length > 1 ? parts[1] : 'Marque inconnue';

        return Card(
          margin: const EdgeInsets.only(top: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.star, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        brandName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    "${e.value} unités",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSuggestedProducts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('product_submissions')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("Aucune suggestion.");
        }
        final suggestions = snapshot.data!.docs
            .where((doc) => doc.id != "rxnFN0Eoxsu1zQ5BaRKo")
            .take(5)
            .toList();

        return Column(
          children: [
            ...suggestions.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dynamic rawTs = data['createdAt'];
              DateTime date = (rawTs != null && rawTs is Timestamp)
                  ? rawTs.toDate()
                  : DateTime.now();
              return Card(
                margin: const EdgeInsets.only(top: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.lightbulb, color: Colors.blue),
                  ),
                  title: Text(
                    data['productName'] ?? "Produit",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Marque : ${data['brandName'] ?? 'N/A'} • ${DateFormat('dd/MM').format(date)}",
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 16),
                ),
              );
            }),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuggestionsPage(),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Voir toutes les suggestions",
                    style: TextStyle(color: Colors.pink),
                  ),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.pink),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
