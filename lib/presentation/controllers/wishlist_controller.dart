import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/product.dart';

class WishlistController extends ChangeNotifier {
  final List<Product> _items = [];

  List<Product> get items => _items;

  // --- INITIALISATION : sync avec Firestore ---
  void syncFromFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('wishlists')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data();
            final productList = List<Map<String, dynamic>>.from(
              data?['items'] ?? [],
            );

            _items.clear();
            for (var map in productList) {
              // On utilise le factory fromMap que tu as déjà créé dans ton entité !
              // C'est beaucoup plus sûr car il gère déjà les title_en, description_en, etc.
              _items.add(Product.fromMap(map));
            }
            notifyListeners();
          } else {
            _items.clear();
            notifyListeners();
          }
        });
  }

  bool isFavorite(Product product) {
    return _items.any((p) => p.id == product.id);
  }

  // --- AJOUT / RETRAIT ---
  void toggleFavorite(Product product) {
    final exists = isFavorite(product);

    if (exists) {
      _items.removeWhere((p) => p.id == product.id);
    } else {
      // On ajoute l'objet product COMPLET (avec toutes ses traductions)
      _items.add(product);
    }
    notifyListeners();
    _updateFirestore();
  }

  // --- SYNCHRO : On utilise ta méthode toMap() de l'entité ---
  Future<void> _updateFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ici on utilise p.toMap() pour être sûr de sauvegarder tous les champs
    // y compris title_en, description_en, composition, etc.
    final data = _items.map((p) => p.toMap()).toList();

    await FirebaseFirestore.instance.collection('wishlists').doc(user.uid).set({
      'items': data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
