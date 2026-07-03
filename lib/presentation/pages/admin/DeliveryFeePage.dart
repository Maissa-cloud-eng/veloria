import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DeliveryFeePage extends StatefulWidget {
  const DeliveryFeePage({super.key});

  @override
  State<DeliveryFeePage> createState() => _DeliveryFeePageState();
}

class _DeliveryFeePageState extends State<DeliveryFeePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  final TextEditingController _regionIdCtrl = TextEditingController();
  final TextEditingController _domicilePriceCtrl = TextEditingController();
  final List<Map<String, TextEditingController>> _bureauControllers = [];

  bool _isLoading = false;
  bool _isDataTransitioning = false; // Sécurité anti-flash
  String? _editingRegionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _addBureauField();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _regionIdCtrl.dispose();
    _domicilePriceCtrl.dispose();
    _clearBureauControllers();
    super.dispose();
  }

  void _clearBureauControllers() {
    for (var b in _bureauControllers) {
      b['name']?.dispose();
      b['price']?.dispose();
    }
    _bureauControllers.clear();
  }

  void _addBureauField({String? name, String? price}) {
    setState(() {
      _bureauControllers.add({
        'name': TextEditingController(text: name),
        'price': TextEditingController(text: price),
      });
    });
  }

  void _removeBureauField(int index) {
    setState(() {
      _bureauControllers[index]['name']?.dispose();
      _bureauControllers[index]['price']?.dispose();
      _bureauControllers.removeAt(index);
      if (_bureauControllers.isEmpty) _addBureauField();
    });
  }

  // --- CHARGER UNE RÉGION (CORRECTION DÉFINITIVE DE L'ERREUR FLASH) ---
  void _editRegion(DocumentSnapshot doc) async {
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _isDataTransitioning = true; // On "coupe" l'affichage du formulaire
    });

    // On prépare les données
    final String region = data['region'] ?? doc.id;
    final String domicile = (data['domicile'] ?? 0).toString();
    final List bureauxData = data['bureaux'] ?? [];

    // On attend un micro-délai pour laisser le moteur Flutter respirer
    await Future.delayed(const Duration(milliseconds: 50));

    setState(() {
      _editingRegionId = doc.id;
      _regionIdCtrl.text = region;
      _domicilePriceCtrl.text = domicile;

      _clearBureauControllers();

      if (bureauxData.isNotEmpty) {
        for (var b in bureauxData) {
          _bureauControllers.add({
            'name': TextEditingController(text: b['name']?.toString() ?? ''),
            'price': TextEditingController(text: b['price']?.toString() ?? '0'),
          });
        }
      } else {
        _addBureauField();
      }
      _isDataTransitioning = false; // On rétablit l'affichage
    });

    _tabController.animateTo(0);
  }

  void _resetForm() {
    setState(() {
      _editingRegionId = null;
      _regionIdCtrl.clear();
      _domicilePriceCtrl.clear();
      _clearBureauControllers();
      _addBureauField();
    });
  }

  Future<void> _deleteRegion(String docId) async {
    await FirebaseFirestore.instance
        .collection('delivery_fees')
        .doc(docId)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$docId supprimé"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _saveDeliveryFees() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> bureauxList = _bureauControllers
          .where((b) => b['name']!.text.trim().isNotEmpty)
          .map(
            (b) => {
              'name': b['name']!.text.trim(),
              'price': double.tryParse(b['price']!.text) ?? 0.0,
            },
          )
          .toList();

      await FirebaseFirestore.instance
          .collection('delivery_fees')
          .doc(_regionIdCtrl.text.trim())
          .set({
            'region': _regionIdCtrl.text.trim(),
            'domicile': double.tryParse(_domicilePriceCtrl.text) ?? 0.0,
            'bureaux': bureauxList,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enregistré avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _editingRegionId != null ? "Modifier Région" : "Frais de Livraison",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.indigo,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Configuration", icon: Icon(Icons.edit)),
            Tab(text: "Liste des frais", icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Si on est en train de charger les données, on affiche un loader
          // pour éviter l'erreur de rendu des champs
          _isDataTransitioning
              ? const Center(child: CircularProgressIndicator())
              : _buildFormTab(),
          _buildListTab(),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.indigo),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_editingRegionId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ActionChip(
                  label: const Text("Mode Nouvel Ajout"),
                  onPressed: _resetForm,
                  avatar: const Icon(Icons.add, size: 18),
                  backgroundColor: Colors.indigo.shade50,
                ),
              ),
            _buildField(
              _regionIdCtrl,
              "Nom de la Région / Wilaya (ID)",
              isRequired: true,
              readOnly: _editingRegionId != null,
            ),
            _buildField(
              _domicilePriceCtrl,
              "Prix Domicile (DA)",
              isNumber: true,
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Bureaux / Points Relais",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.indigo,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addBureauField(),
                  icon: const Icon(Icons.add),
                  label: const Text("Ajouter"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(
              _bureauControllers.length,
              (index) => _buildBureauItem(index),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveDeliveryFees,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _editingRegionId != null ? "METTRE À JOUR" : "ENREGISTRER",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('delivery_fees')
          .orderBy('updatedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Supprimer ?"),
                    content: Text(
                      "Voulez-vous supprimer les frais de ${doc.id} ?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("ANNULER"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "SUPPRIMER",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (direction) => _deleteRegion(doc.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.map, color: Colors.white),
                  ),
                  title: Text(
                    data['region'] ?? doc.id,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Domicile: ${data['domicile']} DA | Bureaux: ${(data['bureaux'] as List).length}",
                  ),
                  trailing: const Icon(Icons.edit_note, color: Colors.indigo),
                  onTap: () => _editRegion(doc),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBureauItem(int index) {
    if (index >= _bureauControllers.length) return const SizedBox(); // Sécurité
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildField(
              _bureauControllers[index]['name']!,
              "Nom bureau",
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildField(
              _bureauControllers[index]['price']!,
              "Prix",
              isNumber: true,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.remove_circle_outline,
              color: Colors.redAccent,
            ),
            onPressed: () => _removeBureauField(index),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    bool isNumber = false,
    bool isRequired = false,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) =>
            isRequired && (value == null || value.trim().isEmpty)
            ? "Obligatoire"
            : null,
      ),
    );
  }
}
