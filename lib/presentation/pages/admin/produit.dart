import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class CategoryCache {
  final String name;
  final String nameEn;
  final List<Map<String, String>> subCats;
  CategoryCache({
    required this.name,
    required this.nameEn,
    required this.subCats,
  });
}

class FlavorController {
  final TextEditingController name = TextEditingController();
  final TextEditingController nameEn = TextEditingController();
  final TextEditingController color = TextEditingController();
  final TextEditingController image = TextEditingController();

  void dispose() {
    name.dispose();
    nameEn.dispose();
    color.dispose();
    image.dispose();
  }
}

class _ProductAdminScreenState extends State<ProductAdminScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _isOutOfStock = false; // Pour le formulaire
  String _stockFilter = "Tous"; // Peut être "Tous" ou "Rupture"

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;
  String? _editingProductId;

  List<CategoryCache> _cachedCategories = [];

  // Contrôleurs
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _titleEnCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _descEnCtrl = TextEditingController();
  final TextEditingController _usageTipsCtrl = TextEditingController();
  final TextEditingController _usageTipsEnCtrl = TextEditingController();
  final TextEditingController _badgeCtrl = TextEditingController();
  final TextEditingController _badgeEnCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _categoryEnCtrl = TextEditingController();
  final TextEditingController _subCatCtrl = TextEditingController();
  final TextEditingController _subCatEnCtrl = TextEditingController();
  final TextEditingController _brandCtrl = TextEditingController();
  final TextEditingController _contentsCtrl =
      TextEditingController(); // Contenu (ex: 200ml)
  final TextEditingController _unitCtrl = TextEditingController();
  final TextEditingController _compositionCtrl =
      TextEditingController(); // NOUVEAU: Composition
  final TextEditingController _costPriceCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final TextEditingController _originCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _tagsCtrl = TextEditingController();
  final TextEditingController _searchHistoryCtrl = TextEditingController();

  List<FlavorController> _flavors = [];
  String _searchQuery = "";
  bool _isNewArrival = true;
  final Set<String> _selectedProductIds =
      {}; // Stocke les IDs des produits cochés

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _originCtrl.text = "Local";
    _searchHistoryCtrl.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchHistoryCtrl.text.toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    for (var f in _flavors) {
      f.dispose();
    }
    _titleCtrl.dispose();
    _titleEnCtrl.dispose();
    _descCtrl.dispose();
    _descEnCtrl.dispose();
    _usageTipsCtrl.dispose();
    _usageTipsEnCtrl.dispose();
    _badgeCtrl.dispose();
    _badgeEnCtrl.dispose();
    _categoryCtrl.dispose();
    _categoryEnCtrl.dispose();
    _subCatCtrl.dispose();
    _subCatEnCtrl.dispose();
    _brandCtrl.dispose();
    _contentsCtrl.dispose();
    _compositionCtrl.dispose(); // Dispose composition
    _costPriceCtrl.dispose();
    _imageCtrl.dispose();
    _originCtrl.dispose();
    _priceCtrl.dispose();
    _tagsCtrl.dispose();
    _unitCtrl.dispose();
    _searchHistoryCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _editProduct(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return;
    setState(() {
      _editingProductId = doc.id;
      _titleCtrl.text = data['title'] ?? '';
      _titleEnCtrl.text = data['title_en'] ?? '';
      _descCtrl.text = data['description'] ?? '';
      _descEnCtrl.text = data['description_en'] ?? '';
      _usageTipsCtrl.text = data['usageTips'] ?? '';
      _usageTipsEnCtrl.text = data['usageTips_en'] ?? '';
      _badgeCtrl.text = data['customBadge'] ?? '';
      _badgeEnCtrl.text = data['customBadge_en'] ?? '';
      _categoryCtrl.text = data['category'] ?? '';
      _categoryEnCtrl.text = data['category_en'] ?? '';
      _subCatCtrl.text = data['subCategory'] ?? '';
      _subCatEnCtrl.text = data['subCategory_en'] ?? '';
      _brandCtrl.text = data['brand'] ?? '';
      _contentsCtrl.text = data['contents'] ?? '';
      _unitCtrl.text = data['unit'] ?? 'ml';
      _compositionCtrl.text = data['composition'] ?? ''; // Load composition
      _costPriceCtrl.text = (data['costPrice'] ?? 0).toString();
      _imageCtrl.text = data['imageUrl'] ?? '';
      _originCtrl.text = data['origin'] ?? 'Local';
      _priceCtrl.text = data['price'] ?? '';
      _isNewArrival = data['isNewArrival'] ?? true;
      _tagsCtrl.text = (data['tags'] is List)
          ? (data['tags'] as List).join(', ')
          : '';
      // Ajoute ceci dans ton setState de _editProduct
      _isOutOfStock = data['isOutOfStock'] ?? false;

      _flavors.clear();
      if (data['flavorOptions'] != null) {
        for (var f in (data['flavorOptions'] as List)) {
          final nf = FlavorController();
          nf.name.text = f['name'] ?? '';
          nf.nameEn.text = f['name_en'] ?? '';
          nf.color.text = f['color'] ?? '';
          nf.image.text = f['imageUrl'] ?? '';
          _flavors.add(nf);
        }
      }
    });
    _tabController.animateTo(0);
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _editingProductId = null;
    _originCtrl.text = "Local";
    _compositionCtrl.clear();
    _contentsCtrl.clear();
    _unitCtrl.text = "ml";
    _flavors = [];
    setState(() {});
  }

  String _generateSlug(
    String title,
    String brand,
    String contents,
    String unit,
  ) {
    // On combine Titre + Marque + Quantité + Unité
    // Exemple: "Mousse Lactovit 200 ml"
    String text = "$title $brand $contents $unit".toLowerCase();

    return text
        .trim()
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        ) // Supprime caractères spéciaux sauf tirets/espaces
        .replaceAll(RegExp(r'\s+'), '-'); // Remplace les espaces par des tirets
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      List<String> tagsList = _tagsCtrl.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
      List<Map<String, String>> flavorData = _flavors
          .map(
            (f) => {
              'name': f.name.text.trim(),
              'name_en': f.nameEn.text.trim().isEmpty
                  ? f.name.text.trim()
                  : f.nameEn.text.trim(),
              'color': f.color.text.trim().isEmpty
                  ? "#000000"
                  : f.color.text.trim(),
              'imageUrl': f.image.text.trim(),
            },
          )
          .toList();
      // Remplace ton ancien appel par celui-ci :
      String slug = _generateSlug(
        _titleCtrl.text.trim(),
        _brandCtrl.text.trim(),
        _contentsCtrl.text.trim(),
        _unitCtrl.text.trim().isEmpty ? 'ml' : _unitCtrl.text.trim(),
      );
      Map<String, dynamic> pData = {
        'title': _titleCtrl.text.trim(), 'title_en': _titleEnCtrl.text.trim(),
        'slug': slug,
        'description': _descCtrl.text.trim(),
        'description_en': _descEnCtrl.text.trim(),
        'usageTips': _usageTipsCtrl.text.trim(),
        'usageTips_en': _usageTipsEnCtrl.text.trim(),
        'customBadge': _badgeCtrl.text.trim(),
        'customBadge_en': _badgeEnCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'category_en': _categoryEnCtrl.text.trim(),
        'subCategory': _subCatCtrl.text.trim(),
        'subCategory_en': _subCatEnCtrl.text.trim(),
        'brand': _brandCtrl.text.trim(),
        'contents': _contentsCtrl.text.trim(),
        'unit': _unitCtrl.text.trim().isEmpty ? 'ml' : _unitCtrl.text.trim(),
        'composition': _compositionCtrl.text.trim(), // Save composition
        'costPrice': double.tryParse(_costPriceCtrl.text) ?? 0.0,
        'imageUrl': _imageCtrl.text.trim(), 'isNewArrival': _isNewArrival,
        'origin': _originCtrl.text.trim(), 'price': _priceCtrl.text.trim(),
        'tags': tagsList,
        'flavorOptions': flavorData.isEmpty ? null : flavorData,
        'updatedAt': FieldValue.serverTimestamp(),
        'isOutOfStock': _isOutOfStock,
      };

      if (_editingProductId != null) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(_editingProductId)
            .update(pData);
      } else {
        pData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(pData);
      }
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produit enregistré avec succès !")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- AJOUTE CE BLOC JUSTE AVANT LE WIDGET BUILD ---
  Future<void> _bulkUpdateStock(bool outOfStock) async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (String id in _selectedProductIds) {
        DocumentReference ref = FirebaseFirestore.instance
            .collection('products')
            .doc(id);
        batch.update(ref, {
          'isOutOfStock': outOfStock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${_selectedProductIds.length} produit(s) mis à jour"),
        ),
      );
      setState(() => _selectedProductIds.clear());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Suppression individuelle avec confirmation

  // Suppression groupée (Bulk Delete)
  Future<void> _bulkDelete() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Suppression groupée"),
            content: Text(
              "Supprimer ${_selectedProductIds.length} produits définitivement ?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("ANNULER"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "TOUT SUPPRIMER",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      setState(() => _isLoading = true);
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var id in _selectedProductIds) {
        batch.delete(FirebaseFirestore.instance.collection('products').doc(id));
      }
      await batch.commit();
      setState(() {
        _selectedProductIds.clear();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _editingProductId != null ? "Modifier Produit" : "Nouveau Produit",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.pink,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Édition"),
            Tab(text: "Liste"),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('categories').snapshots(),
        builder: (context, catSnapshot) {
          if (catSnapshot.hasData) {
            _cachedCategories = catSnapshot.data!.docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final List<dynamic> rawSubCats = d['subCategories'] is List
                  ? d['subCategories']
                  : [];
              final List<Map<String, String>> subList = rawSubCats.map((s) {
                if (s is Map) {
                  return {
                    'name': (s['name'] ?? '').toString(),
                    'name_en': (s['name_en'] ?? '').toString(),
                  };
                }
                return {'name': s.toString(), 'name_en': s.toString()};
              }).toList();
              return CategoryCache(
                name: d['name'] ?? '',
                nameEn: d['name_en'] ?? '',
                subCats: subList,
              );
            }).toList();
          }
          return TabBarView(
            controller: _tabController,
            children: [_buildFormTab(), _buildHistoryTab()],
          );
        },
      ),
    );
  }

  Widget _buildFormTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    List<String> catOptions = _cachedCategories.map((c) => c.name).toList();
    var selectedCatObj = _cachedCategories
        .where((c) => c.name == _categoryCtrl.text)
        .firstOrNull;
    List<Map<String, String>> currentSubCats = selectedCatObj?.subCats ?? [];
    List<String> subOptions = currentSubCats.map((s) => s['name']!).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildField(_titleCtrl, "Titre FR"),
            _buildField(_titleEnCtrl, "Title EN"),
            Row(
              children: [
                Expanded(child: _buildField(_badgeCtrl, "Badge FR")),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_badgeEnCtrl, "Badge EN")),
              ],
            ),

            DropdownButtonFormField<String>(
              initialValue: _categoryCtrl.text.isEmpty
                  ? null
                  : _categoryCtrl.text,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Catégorie",
                border: OutlineInputBorder(),
              ),
              items: catOptions
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _categoryCtrl.text = val!;
                  _categoryEnCtrl.text = _cachedCategories
                      .firstWhere((c) => c.name == val)
                      .nameEn;
                  _subCatCtrl.clear();
                  _subCatEnCtrl.clear();
                });
              },
            ),
            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: _subCatCtrl.text.isEmpty ? null : _subCatCtrl.text,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: "Sous-Catégorie",
                border: OutlineInputBorder(),
              ),
              items: subOptions
                  .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  _subCatCtrl.text = val!;
                  _subCatEnCtrl.text = currentSubCats.firstWhere(
                    (s) => s['name'] == val,
                  )['name_en']!;
                });
              },
            ),
            const SizedBox(height: 15),

            _buildField(_brandCtrl, "Marque"),
            _buildField(_descCtrl, "Description FR", maxLines: 2),
            _buildField(_descEnCtrl, "Description EN", maxLines: 2),
            _buildField(
              _usageTipsCtrl,
              "Conseils d'utilisation FR",
              maxLines: 2,
            ),
            _buildField(_usageTipsEnCtrl, "Usage Tips EN", maxLines: 2),
            _buildField(
              _compositionCtrl,
              "Composition / Ingrédients",
              maxLines: 3,
            ), // Champ Composition ajouté

            Row(
              children: [
                Expanded(child: _buildField(_priceCtrl, "Prix")),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildField(_costPriceCtrl, "Coût", isNumber: true),
                ),
              ],
            ),

            Row(
              children: [
                // 1. Champ Quantité (ex: 85)
                Expanded(
                  flex: 1, // Plus large pour le chiffre
                  child: _buildField(_contentsCtrl, "Quantité", isNumber: true),
                ),
                const SizedBox(width: 8),

                // 2. Champ Unité (ex: ml, g, pcs)
                Expanded(
                  flex: 1, // Plus étroit
                  child: _buildField(_unitCtrl, "Unité"),
                ),
                const SizedBox(width: 8),

                // 3. Dropdown Origine
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _originCtrl.text.isEmpty
                        ? "Local"
                        : _originCtrl.text,
                    decoration: const InputDecoration(
                      labelText: "Origine",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 15,
                      ),
                    ),
                    items: ["Local", "Importation"]
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => _originCtrl.text = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            _buildField(_imageCtrl, "URL Image Principale"),
            _buildField(_tagsCtrl, "Tags (séparés par virgules)"),

            SwitchListTile(
              title: const Text("Nouveauté"),
              value: _isNewArrival,
              activeThumbColor: Colors.pink,
              onChanged: (v) => setState(() => _isNewArrival = v),
            ),
            // --- AJOUTE CE BLOC ICI ---
            SwitchListTile(
              title: const Text("Rupture de Stock"),
              subtitle: const Text("Le bouton Acheter sera désactivé"),
              value: _isOutOfStock,
              activeThumbColor: Colors.orange,
              onChanged: (v) => setState(() => _isOutOfStock = v),
            ),

            const Divider(thickness: 2),
            ...List.generate(_flavors.length, (i) => _buildFlavorItem(i)),

            TextButton.icon(
              onPressed: () => setState(() => _flavors.add(FlavorController())),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Ajouter une variante"),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: Text(
                _editingProductId != null
                    ? "MODIFIER LE PRODUIT"
                    : "CRÉER LE PRODUIT",
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

  Widget _buildFlavorItem(int i) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Variante #${i + 1}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => setState(() => _flavors.removeAt(i)),
              ),
            ],
          ),
          _buildField(_flavors[i].name, "Nom Variante FR"),
          _buildField(_flavors[i].nameEn, "Name Variant EN"),
          Row(
            children: [
              Expanded(
                child: _buildField(_flavors[i].color, "Code Couleur (#HEX)"),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildField(_flavors[i].image, "URL Image Variante"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // 1. Barre de recherche
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchHistoryCtrl,
            decoration: const InputDecoration(
              hintText: "Rechercher un produit...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),

        // 2. FILTRES DE STOCK ET COMPTEUR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .snapshots(),
            builder: (context, snapshot) {
              // On récupère le nombre total (brut) depuis Firestore
              int totalCount = snapshot.hasData
                  ? snapshot.data!.docs.length
                  : 0;

              return Row(
                children: [
                  // --- AFFICHAGE DU TOTAL ---
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$totalCount produits",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tes FilterChips existants
                  FilterChip(
                    label: const Text("Tous"),
                    selected: _stockFilter == "Tous",
                    selectedColor: Colors.pink.shade100,
                    onSelected: (bool selected) {
                      setState(() => _stockFilter = "Tous");
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("En Rupture"),
                    selected: _stockFilter == "Rupture",
                    selectedColor: Colors.orange.shade100,
                    checkmarkColor: Colors.orange,
                    onSelected: (bool selected) {
                      setState(() => _stockFilter = "Rupture");
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // 3. BARRE D'ACTION (Modifiée)
        if (_selectedProductIds.isNotEmpty)
          Container(
            width: double.infinity,
            color: Colors.pink.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Text("${_selectedProductIds.length} sélectionnés"),
                const Spacer(),
                TextButton(
                  onPressed: () => _bulkUpdateStock(true),
                  child: const Text("RUPTURE"),
                ),
                TextButton(
                  onPressed: () => _bulkUpdateStock(false),
                  child: const Text("STOCK"),
                ),
                // NOUVEAU BOUTON SUPPRIMER
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  onPressed: _bulkDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedProductIds.clear()),
                ),
              ],
            ),
          ),

        // 4. LISTE FILTRÉE
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('products')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // LOGIQUE DE FILTRAGE COMBINÉE (Recherche + Stock)
              final docs = snapshot.data!.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final bool matchesSearch = data['title']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery);
                final bool isOut = data['isOutOfStock'] ?? false;

                if (_stockFilter == "Rupture") {
                  return matchesSearch && isOut; // Ne montre que si rupture
                }
                return matchesSearch; // Montre tout
              }).toList();

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final String id = docs[i].id;
                  final bool isSelected = _selectedProductIds.contains(id);
                  final bool isOut = d['isOutOfStock'] ?? false;

                  return ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (val) => setState(() {
                            val == true
                                ? _selectedProductIds.add(id)
                                : _selectedProductIds.remove(id);
                          }),
                        ),
                        d['imageUrl'] != null
                            ? Image.network(d['imageUrl'], width: 40)
                            : const Icon(Icons.image),
                      ],
                    ),
                    title: Text(
                      d['title'] ?? 'Sans titre',
                      style: TextStyle(
                        decoration: isOut ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      isOut ? "RUPTURE" : d['category'],
                      style: TextStyle(color: isOut ? Colors.red : Colors.grey),
                    ),
                    onTap: () => _editProduct(docs[i]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (v) =>
            (v == null || v.isEmpty) &&
                !label.contains("EN") &&
                !label.contains("Badge") &&
                !label.contains("Composition") &&
                !label.contains("Conseils")
            ? "Requis"
            : null,
      ),
    );
  }
}
