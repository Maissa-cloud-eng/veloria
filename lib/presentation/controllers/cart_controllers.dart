import 'package:flutter/material.dart';

class CartController extends ChangeNotifier {
  int _count = 0;
  List<Map<String, dynamic>> _items = [];

  // ===== Getters =====
  int get count => _count;
  List<Map<String, dynamic>> get items => _items;

  // ===== Setters =====
  void setCount(int value) {
    _count = value;
    notifyListeners();
  }

  void setItems(List<Map<String, dynamic>> value) {
    _items = value;
    _count = _calculateTotalCount(value);
    notifyListeners();
  }

  // ===== Méthodes classiques =====
  void increment() {
    _count += 1;
    notifyListeners();
  }

  void decrement() {
    if (_count > 0) {
      _count -= 1;
      notifyListeners();
    }
  }

  // ===== Gestion des items =====
  void addItem(Map<String, dynamic> item) {
    // IMPORTANT: L'objet 'item' reçu doit contenir :
    // productId, title, price, costPrice, quantity, image

    final index = _items.indexWhere((i) => i['productId'] == item['productId']);

    if (index >= 0) {
      _items[index]['quantity'] += item['quantity'] ?? 1;
    } else {
      // On s'assure que costPrice est présent, sinon on met 0 pour éviter les crashs
      if (!item.containsKey('costPrice')) {
        item['costPrice'] = 0;
      }
      _items.add(item);
    }

    _count = _calculateTotalCount(_items);
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item['productId'] == productId);
    _count = _calculateTotalCount(_items);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _count = 0;
    notifyListeners();
  }

  // ===== Synchronisation depuis Firestore =====
  void syncFromFirestore(List<Map<String, dynamic>> firestoreItems) {
    _items = firestoreItems;
    _count = _calculateTotalCount(firestoreItems);
    notifyListeners();
  }

  // Méthode utilitaire pour éviter la répétition du calcul
  int _calculateTotalCount(List<Map<String, dynamic>> itemsList) {
    return itemsList.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int? ?? 0),
    );
  }
}
