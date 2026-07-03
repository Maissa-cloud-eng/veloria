import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  /// Vérifie si l'utilisateur actuel est administrateur
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        // Retourne la valeur du champ isAdmin, ou false s'il n'existe pas
        return doc.data()?['isAdmin'] ?? false;
      }
    } catch (e) {
      print("Erreur lors de la vérification admin : $e");
    }
    return false;
  }

  /// Gère la connexion anonyme et la synchronisation Firestore
  static Future<void> signInAnonymouslyIfNeeded() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      print("Utilisateur déjà connecté : ${user.uid}");
      return;
    }

    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      final uid = result.user!.uid;
      print("Connexion anonyme créée : $uid");

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();
      final prefs = await SharedPreferences.getInstance();

      if (!doc.exists) {
        // Création d'un nouvel utilisateur avec isAdmin par défaut à false
        await docRef.set({
          'name': prefs.getString('name') ?? '',
          'email': prefs.getString('email') ?? '',
          'phone': prefs.getString('phone') ?? '',
          'skinType': prefs.getString('skinType') ?? '',
          'hairTexture': prefs.getString('hairTexture') ?? '',
          'hairState': prefs.getString('hairState') ?? '',
          'orderHistory': [],
          'totalOrdersCount': 0,
          'isAdmin': false, // <--- Ajouté par défaut pour la sécurité
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Si le document existe déjà, on synchronise les préférences locales
        prefs.setString('skinType', doc.data()?['skinType'] ?? '');
        prefs.setString('hairTexture', doc.data()?['hairTexture'] ?? '');
        prefs.setString('hairState', doc.data()?['hairState'] ?? '');
      }
    } catch (e) {
      print("Erreur lors de la connexion/synchronisation : $e");
    }
  }
}
