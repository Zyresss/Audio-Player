import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Obtenir la référence de la collection des favoris de l'utilisateur actuel
  CollectionReference get _userFavorites {
    final userId = _auth.currentUser!.uid;
    return _firestore.collection('users').doc(userId).collection('favorites');
  }

  // Ajouter un favori
  Future<void> addFavorite(Map<String, dynamic> track, String reciterName) async {
    await _userFavorites.doc(track['id'].toString()).set({
      'id': track['id'],
      'name': track['name'],
      'reciter': reciterName,
      'audioUrl': track['audioUrl'],
      'coverUrl': track['coverUrl'],
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  // Récupérer les favoris (sous forme de flux pour mise à jour en temps réel)
  Stream<QuerySnapshot> getFavoritesStream() {
    return _userFavorites.orderBy('addedAt', descending: true).snapshots();
  }

  // Supprimer un favori
  Future<void> removeFavorite(String trackId) async {
    await _userFavorites.doc(trackId).delete();
  }
}