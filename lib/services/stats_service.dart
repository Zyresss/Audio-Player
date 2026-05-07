import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StatsService {
  // Clés pour la base de données locale
  static const String _totalMinutesKey = 'total_listening_minutes';
  static const String _dailyStatsKey = 'daily_listening_stats';

  // 1. Ajouter UNE minute d'écoute (sera appelé par nos lecteurs audio)
  Future<void> addListeningMinute() async {
    final prefs = await SharedPreferences.getInstance();

    // A. Mettre à jour le total global
    int total = prefs.getInt(_totalMinutesKey) ?? 0;
    await prefs.setInt(_totalMinutesKey, total + 1);

    // B. Mettre à jour les statistiques d'aujourd'hui
    String today = DateTime.now().toIso8601String().split('T')[0]; // Format "2026-05-07"

    String? dailyStatsJson = prefs.getString(_dailyStatsKey);
    Map<String, dynamic> dailyStats = dailyStatsJson != null ? jsonDecode(dailyStatsJson) : {};

    int todayMinutes = (dailyStats[today] ?? 0) as int;
    dailyStats[today] = todayMinutes + 1;

    await prefs.setString(_dailyStatsKey, jsonEncode(dailyStats));
    print("Statistiques : 1 minute ajoutée. Total aujourd'hui : ${todayMinutes + 1} min");
  }

  // 2. Récupérer le total des minutes (pour l'affichage en heures/minutes)
  Future<int> getTotalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalMinutesKey) ?? 0;
  }

  // 3. Récupérer les données des 7 derniers jours (pour le graphique)
  Future<List<double>> getLast7DaysStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? dailyStatsJson = prefs.getString(_dailyStatsKey);
    Map<String, dynamic> dailyStats = dailyStatsJson != null ? jsonDecode(dailyStatsJson) : {};

    List<double> last7Days = [];

    // On recule de 6 jours jusqu'à aujourd'hui pour construire le graphique
    for (int i = 6; i >= 0; i--) {
      DateTime day = DateTime.now().subtract(Duration(days: i));
      String dateString = day.toIso8601String().split('T')[0];

      int minutes = (dailyStats[dateString] ?? 0) as int;
      last7Days.add(minutes.toDouble());
    }
    return last7Days;
  }
}