import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import nécessaire pour le copier-coller

class ReviewsAdminPage extends StatefulWidget {
  const ReviewsAdminPage({super.key});

  @override
  State<ReviewsAdminPage> createState() => _ReviewsAdminPageState();
}

class _ReviewsAdminPageState extends State<ReviewsAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Analyses des Avis",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber.shade800,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          Map<String, Map<String, dynamic>> productData = {};
          Map<String, List<Map<String, dynamic>>> productReviews = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final items = data['items'] as List? ?? [];

            final shippingInfo = data['shippingInfo'] as Map<String, dynamic>?;
            final String clienteName = shippingInfo?['name'] ?? 'Cliente N/A';

            for (var item in items) {
              if (item['isRated'] == true && item['ratingStars'] != null) {
                String title = item['title'] ?? "Produit Inconnu";

                if (!productData.containsKey(title)) {
                  productData[title] = {'imageUrl': item['imageUrl'] ?? ''};
                  productReviews[title] = [];
                }

                productReviews[title]!.add({
                  'rating': item['ratingStars'],
                  'clientName': clienteName,
                  'clientId': data['userId'] ?? 'ID Inconnu',
                  'date': data['orderDate'],
                });
              }
            }
          }

          if (productReviews.isEmpty) {
            return const Center(
              child: Text("Aucun produit n'a encore été noté."),
            );
          }

          final productNames = productReviews.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productNames.length,
            itemBuilder: (context, index) {
              String name = productNames[index];
              List<Map<String, dynamic>> reviews = productReviews[name]!;
              String imgUrl = productData[name]?['imageUrl'] ?? '';

              double average =
                  reviews
                      .map((e) => e['rating'] as int)
                      .reduce((a, b) => a + b) /
                  reviews.length;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.shopping_bag,
                              color: Colors.amber,
                            ),
                          )
                        : const Icon(Icons.shopping_bag, color: Colors.amber),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      _buildStars(average, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${average.toStringAsFixed(1)} (${reviews.length} avis)",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _showReviewDetails(name, reviews),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showReviewDetails(
    String productName,
    List<Map<String, dynamic>> reviews,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Avis pour : $productName",
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 30),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: reviews.length,
                  itemBuilder: (context, i) {
                    final rev = reviews[i];
                    final String id = rev['clientId'];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Cliente : ${rev['clientName']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),

                                    // --- ID COPIABLE ICI ---
                                    GestureDetector(
                                      onLongPress: () {
                                        Clipboard.setData(
                                          ClipboardData(text: id),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("ID copié !"),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          SelectableText(
                                            "ID : $id",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Icon(
                                            Icons.copy,
                                            size: 10,
                                            color: Colors.grey.shade400,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildStars(rev['rating'].toDouble(), size: 14),
                            ],
                          ),
                          const Divider(),
                          Text(
                            "Date : ${_formatDate(rev['date'])}",
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: size,
        );
      }),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    return "";
  }
}
