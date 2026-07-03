import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SuggestionsPage extends StatelessWidget {
  const SuggestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Suggestions des clients",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.pink,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('product_submissions')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.pink),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Filtrage de l'ID spécifique
          final filteredDocs = snapshot.data!.docs.where((doc) {
            return doc.id != "rxnFN0Eoxsu1zQ5BaRKo";
          }).toList();

          if (filteredDocs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 100,
            ), // Ajout de l'espace en bas
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data() as Map<String, dynamic>;
              return _buildSubmissionCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> data) {
    String dateStr = "Date inconnue";
    if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
      DateTime dt = (data['createdAt'] as Timestamp).toDate();
      dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(dt);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data['productName'] ?? 'Produit sans nom',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                    ),
                    softWrap: true, // Évite que le titre soit coupé
                  ),
                ),
                const Icon(
                  Icons.lightbulb_circle,
                  color: Colors.amber,
                  size: 28,
                ),
              ],
            ),
            const Divider(height: 20),

            _buildInfoRow(
              Icons.branding_watermark_outlined,
              "Marque",
              data['brandName'] ?? "Non précisée",
            ),
            const SizedBox(height: 10),

            _buildInfoRow(
              Icons.person_outline,
              "Suggéré par",
              data['submittedBy'] ?? "Client anonyme",
            ),

            const SizedBox(height: 10),
            _buildInfoRow(Icons.calendar_today_outlined, "Le", dateStr),

            if (data['comment'] != null &&
                data['comment'].toString().trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Commentaire :",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['comment'],
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- CORRECTION MAJEURE ICI ---
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Aligne l'icône en haut
      children: [
        Icon(icon, size: 18, color: Colors.pink.shade300),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            softWrap: true,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: "$label : ",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_motion_outlined,
            size: 80,
            color: Colors.pink.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucune suggestion client pour le moment.",
            style: TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
