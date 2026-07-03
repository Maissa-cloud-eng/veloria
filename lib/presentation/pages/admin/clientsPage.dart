import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  bool filterOnlyWithOrders = false;
  // --- NOUVEAU : Contrôleur pour la recherche ---
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Répertoire Clients",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(
              filterOnlyWithOrders ? Icons.filter_alt : Icons.filter_alt_off,
              color: Colors.white,
            ),
            onPressed: () =>
                setState(() => filterOnlyWithOrders = !filterOnlyWithOrders),
            tooltip: "Filtrer les clientes sans commandes",
          ),
        ],
      ),
      body: Column(
        children: [
          // --- BARRE DE RECHERCHE ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blue,
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase().trim()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Rechercher par nom ou ID...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
              ),
            ),
          ),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Erreur : ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // 1. Convertir et exclure l'Admin
              List<QueryDocumentSnapshot> docs = snapshot.data!.docs
                  .where((doc) => doc.id != "uid")
                  .toList();

              // 2. FILTRE RECHERCHE (Nom ou ID)
              if (_searchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String name = (data['name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final String id = doc.id.toLowerCase();
                  return name.contains(_searchQuery) ||
                      id.contains(_searchQuery);
                }).toList();
              }

              // 3. Filtrage Commandes > 0
              if (filterOnlyWithOrders) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return (data['totalOrdersCount'] ?? 0) > 0;
                }).toList();
              }

              // 4. TRI
              docs.sort((a, b) {
                final countA =
                    (a.data() as Map<String, dynamic>)['totalOrdersCount'] ?? 0;
                final countB =
                    (b.data() as Map<String, dynamic>)['totalOrdersCount'] ?? 0;
                return countB.compareTo(countA);
              });

              return Expanded(
                child: Column(
                  children: [
                    _buildHeader(docs.length),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final int orderCount = data['totalOrdersCount'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 2,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: orderCount > 0
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100,
                                child: Text(
                                  (data['name'] ?? 'U')[0].toUpperCase(),
                                  style: TextStyle(
                                    color: orderCount > 0
                                        ? Colors.green
                                        : Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                data['name'] ?? "Utilisatrice Anonyme",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text("Commandes : $orderCount"),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // AFFICHAGE DE L'ID CLIENT
                                      _buildInfoRow(
                                        Icons.fingerprint,
                                        "ID Client",
                                        doc.id,
                                        isSelectable: true,
                                      ),
                                      const Divider(),
                                      _buildInfoRow(
                                        Icons.shopping_basket,
                                        "Total Commandes",
                                        "$orderCount",
                                      ),
                                      _buildInfoRow(
                                        Icons.phone,
                                        "Téléphone",
                                        data['phone'] ?? "N/A",
                                      ),
                                      _buildInfoRow(
                                        Icons.location_on,
                                        "Wilaya",
                                        data['city'] ?? "N/A",
                                      ),
                                      const Divider(),
                                      _buildInfoRow(
                                        Icons.face,
                                        "Type de peau",
                                        data['skinType'] ?? "N/A",
                                      ),
                                      _buildInfoRow(
                                        Icons.waves,
                                        "Cheveux",
                                        "${data['hairTexture'] ?? 'N/A'} (${data['hairState'] ?? 'N/A'})",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.blue.shade50),
      child: Column(
        children: [
          Text(
            total.toString(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            filterOnlyWithOrders
                ? "Clientes avec commandes"
                : "Clientes trouvées",
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isSelectable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade300),
          const SizedBox(width: 10),
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: isSelectable
                ? SelectableText(
                    value,
                    style: TextStyle(
                      color: isSelectable ? Colors.blue.shade800 : Colors.black,
                      fontSize: 13,
                      fontWeight: isSelectable
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  )
                : Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
