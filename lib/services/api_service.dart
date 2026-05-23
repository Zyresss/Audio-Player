import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Récupère les sourates (Morceaux) en fonction du récitateur (Catégorie)
  Future<List<Map<String, dynamic>>> fetchSurahsByCategory(String reciterServerUrl) async {
    // Appel à une API publique pour obtenir la liste dynamique des sourates
    final url = Uri.parse('https://mp3quran.net/api/v3/suwar?language=ar');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> suwar = data['suwar'];

        List<Map<String, dynamic>> playlist = [];

        // On charge les 20 premières sourates pour que l'app reste rapide
        for (int i = 0; i < 114; i++) {
          var surah = suwar[i];

          // Le format audio exige 3 chiffres (ex: 001.mp3, 015.mp3)
          String surahNumber = surah['id'].toString().padLeft(3, '0');

          playlist.add({
            'id': surah['id'].toString(),
            'name': surah['name'], // Nom de la sourate venant de l'API
            // Lien MP3 dynamique = Serveur du récitateur + Numéro de la sourate
            'audioUrl': '$reciterServerUrl/$surahNumber.mp3',
            // Image générique du Coran
            'coverUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Quran_Kareem.svg/512px-Quran_Kareem.svg.png',
          });
        }
        return playlist;
      } else {
        throw Exception('Erreur de chargement des sourates');
      }
    } catch (e) {
      print("Erreur API: $e");
      return [];
    }
  }
}