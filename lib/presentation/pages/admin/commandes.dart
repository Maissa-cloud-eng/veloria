import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  // ... à l'intérieur de _AdminOrdersPageState

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    double totalCA = 0;
    final double commissionRate = 0.05; // 10%

    // Récupération des données détaillées pour les commandes sélectionnées
    List<Map<String, dynamic>> ordersData = [];

    for (String id in selectedOrderIds) {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(id)
          .get();
      final data = orderDoc.data() as Map<String, dynamic>;

      // Récupération des infos user pour avoir le tel et l'adresse précise
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['userId'])
          .get();
      final userData = userDoc.data();

      ordersData.add({'order': data, 'user': userData});

      // Calcul du CA (on utilise le total avec livraison)
      totalCA += (data['totalProducts'] ?? 0).toDouble();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                "Rapport de Commandes - Veloria",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            ...ordersData.map((item) {
              final order = item['order'];
              final user = item['user'];
              final String deliveryType =
                  order['deliveryType'] ?? 'domicile'; // Par défaut domicile
              final String? bureauName =
                  order['selectedBureau']?['name']; // Récupère le nom du bureau
              final products = order['items'] as List;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Divider(),
                  pw.Text(
                    "Client: ${user?['name'] ?? order['userName'] ?? 'N/A'}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text("Tel: ${user?['phone'] ?? 'N/A'}"),
                  // --- NOUVELLE SECTION LIVRAISON ---
                  pw.Row(
                    children: [
                      pw.Text(
                        "Mode de livraison: ",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        deliveryType == 'bureau'
                            ? "Retrait en Bureau"
                            : "Livraison à Domicile",
                      ),
                    ],
                  ),

                  if (deliveryType == 'bureau' && bureauName != null)
                    pw.Text(
                      "Bureau: $bureauName",
                      style: pw.TextStyle(color: PdfColors.blueGrey700),
                    )
                  else
                    pw.Text(
                      "Adresse: ${user?['addressLine'] ?? 'N/A'}, ${user?['city'] ?? ''}",
                    ),

                  // ----------------------------------
                  pw.SizedBox(height: 5),
                  pw.Text("Produits:"),
                  ...products.map(
                    (p) => pw.Bullet(
                      text:
                          "${p['title']} [${p['brand']}] (x${p['quantity']}) - ${p['price']} DA",
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
              );
            }).toList(),

            pw.Divider(thickness: 2),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "Total CA: ${totalCA.toStringAsFixed(2)} DA",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    "Commission (5%): ${(totalCA * commissionRate).toStringAsFixed(2)} DA",
                    style: pw.TextStyle(color: PdfColors.pink),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Set<String> selectedOrderIds = {};

  // --- LOGIQUE DE MISE À JOUR DU STATUT ---
  Future<void> _updateStatus(String newStatus) async {
    final batch = FirebaseFirestore.instance.batch();

    for (String id in selectedOrderIds) {
      DocumentReference ref = FirebaseFirestore.instance
          .collection('orders')
          .doc(id);

      // Préparation des données de base
      Map<String, dynamic> updateData = {
        'deliveryStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // CORRECTION : Si le statut est "delivered", on ajoute la date de livraison
      // C'est ce champ qui débloquera la notation dans le profil client après 7 jours
      if (newStatus == "delivered") {
        updateData['deliveryDate'] = FieldValue.serverTimestamp();
      }

      batch.update(ref, updateData);
    }

    await batch.commit();

    if (mounted) {
      setState(() => selectedOrderIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Statut mis à jour : $newStatus"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Gestion des Commandes",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (selectedOrderIds.isNotEmpty) ...[
            IconButton(
              tooltip: "Générer PDF",
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.orangeAccent,
              ),
              onPressed: _generatePdf, // Appel de la fonction créée ci-dessus
            ),
            IconButton(
              tooltip: "Annuler la commande",
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () {
                // On affiche une boîte de dialogue avant d'agir
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirmer l'annulation"),
                      content: Text(
                        "Voulez-vous vraiment annuler ${selectedOrderIds.length} commande(s) ?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(
                            context,
                          ), // On ferme sans rien faire
                          child: const Text("Retour"),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // On ferme la modale
                            _updateStatus(
                              "cancelled",
                            ); // On lance la mise à jour
                          },
                          child: const Text(
                            "Oui, annuler",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            IconButton(
              tooltip: "Marquer comme Expédiée",
              icon: const Icon(Icons.local_shipping, color: Colors.blueAccent),
              onPressed: () => _updateStatus("shipped"),
            ),
            IconButton(
              tooltip: "Marquer comme Livrée",
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () => _updateStatus("delivered"),
            ),
          ],
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Erreur de chargement"));
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          // Filtrage des IDs techniques
          List<QueryDocumentSnapshot> docs = snapshot.data!.docs.where((doc) {
            return doc.id != "OE0N2pbyQjXdqG69FQXa" &&
                doc.id != "uid" &&
                doc.id.isNotEmpty;
          }).toList();

          // Tri par date de mise à jour
          docs.sort((a, b) {
            Timestamp? tA = (a.data() as Map<String, dynamic>)['updatedAt'];
            Timestamp? tB = (b.data() as Map<String, dynamic>)['updatedAt'];
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

          if (docs.isEmpty) {
            return const Center(child: Text("Aucune commande en cours"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final bool isSelected = selectedOrderIds.contains(doc.id);
              final String userId = data['userId'] ?? '';

              String orderNumber =
                  "#${(docs.length - index).toString().padLeft(4, '0')}";

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  onTap: () => _showOrderDetails(data, doc.id),
                  leading: Checkbox(
                    activeColor: Colors.pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        val == true
                            ? selectedOrderIds.add(doc.id)
                            : selectedOrderIds.remove(doc.id);
                      });
                    },
                  ),
                  title: Text(
                    "Commande $orderNumber",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .get(),
                    builder: (context, userSnap) {
                      final userData =
                          userSnap.data?.data() as Map<String, dynamic>?;
                      String nameToShow =
                          userData?['name'] ?? data['userName'] ?? "Client N/A";
                      return Text(
                        nameToShow,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                  trailing: _buildStatusBadge(data['deliveryStatus']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.orange;
    String text = "En attente";
    if (status == 'shipped') {
      color = Colors.blue;
      text = "Expédiée";
    } else if (status == 'delivered') {
      color = Colors.green;
      text = "Livrée";
    } else if (status == 'cancelled') {
      color = Colors.red; // Couleur pour l'annulation
      text = "Annulée";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- MODALE DE DÉTAILS ---
  void _showOrderDetails(Map<String, dynamic> orderData, String orderId) {
    final String userId = orderData['userId']?.toString() ?? '';
    final List products =
        orderData['items'] ?? orderData['lastOrderItems'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
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
            const Text(
              "Détails Cliente",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
            const Divider(height: 30),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnap) {
                if (userSnap.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(color: Colors.pink);
                }
                final userData = userSnap.data?.data() as Map<String, dynamic>?;
                return Column(
                  children: [
                    _infoRow(
                      Icons.person,
                      "Nom Complet",
                      userData?['name'] ?? orderData['userName'] ?? "N/A",
                    ),
                    _infoRow(
                      Icons.phone,
                      "Téléphone",
                      userData?['phone'] ?? "N/A",
                    ),
                    _infoRow(
                      Icons.location_on,
                      "Adresse",
                      userData?['addressLine'] ?? "N/A",
                    ),
                    _infoRow(Icons.map, "Ville", userData?['city'] ?? "N/A"),
                  ],
                );
              },
            ),
            const SizedBox(height: 25),
            const Text(
              "Produits Commandés",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, i) {
                  final item = products[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item['imageUrl'] ?? '',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.shopping_bag, color: Colors.pink),
                      ),
                    ),
                    title: Text(
                      item['title'] ?? "Produit",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      "${item['quantity']} x ${item['price']}",
                      style: const TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Fermer",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.pink),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
