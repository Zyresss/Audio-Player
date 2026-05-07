import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/stats_service.dart';
import 'login_screen.dart';
import 'player_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final StatsService _statsService = StatsService(); // NOUVEAU

  String _fullName = "Chargement...";
  int _monthlyGoalHours = 20;

  // Remplacé par de vraies variables dynamiques
  int _totalMinutesListened = 0;
  List<double> _dailyListeningData = [0, 0, 0, 0, 0, 0, 0];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStatsAndGoal(); // Modifié
  }

  // NOUVEAU : Charge l'objectif ET les statistiques réelles
  Future<void> _loadStatsAndGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    int realTotalMinutes = await _statsService.getTotalMinutes();
    List<double> realDailyData = await _statsService.getLast7DaysStats();

    setState(() {
      _monthlyGoalHours = prefs.getInt('monthly_goal') ?? 20;
      _totalMinutesListened = realTotalMinutes;
      _dailyListeningData = realDailyData;
    });
  }

  // 1. Fetch Name from Firestore
  Future<void> _loadUserData() async {
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _fullName = "${data['prenom']} ${data['nom']}";
          });
        }
      } catch (e) {
        print("Erreur de chargement des données: $e");
      }
    }
  }

  // 2. Load Goal from SharedPreferences
  Future<void> _loadGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _monthlyGoalHours = prefs.getInt('monthly_goal') ?? 20;
    });
  }

  // 3. Save Goal to SharedPreferences
  Future<void> _saveGoal(int newGoal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('monthly_goal', newGoal);
    setState(() {
      _monthlyGoalHours = newGoal;
    });
  }

  // Logout Function
  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    int totalHours = _totalMinutesListened ~/ 60;
    int remainingMinutes = _totalMinutesListened % 60;
    double progress = totalHours / _monthlyGoalHours;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            onPressed: () async {
              // On AWAIT (attend) que l'utilisateur revienne de cet écran
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
              // Quand il revient, on met à jour l'écran !
              _loadStatsAndGoal();
            },
            tooltip: 'Mes Favoris',
          ),
          IconButton(
            icon: const Icon(Icons.music_note),
            onPressed: () async {
              // On AWAIT (attend) que l'utilisateur revienne du lecteur
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
              // Quand il revient, on met à jour l'écran !
              _loadStatsAndGoal();
            },
            tooltip: 'Lecteur Audio',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MESSAGE DE BIENVENUE ---
            Text.rich(
              TextSpan(
                text: 'Bienvenue, ',
                style: const TextStyle(fontSize: 22),
                children: [
                  TextSpan(
                    text: _fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- TEMPS TOTAL D'ÉCOUTE ---
            Card(
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.headset, size: 40, color: Colors.blue),
                title: const Text("Temps total d'écoute"),
                subtitle: Text(
                  "$totalHours heures et $remainingMinutes minutes",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- OBJECTIF MENSUEL (Barre de progression) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Objectif mensuel:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<int>(
                  value: _monthlyGoalHours,
                  items: [10, 20, 30, 40, 50, 100].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text("$value Heures"),
                    );
                  }).toList(),
                  onChanged: (int? newValue) {
                    if (newValue != null) _saveGoal(newValue);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: progress >= 1.0 ? Colors.green : Colors.blue,
            ),
            const SizedBox(height: 5),
            Text("${(progress * 100).toStringAsFixed(1)}% de l'objectif atteint"),
            const SizedBox(height: 30),

            // --- GRAPHIQUE HISTOGRAMME ---
            const Text("Écoute par jour (7 derniers jours)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 150,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(fontSize: 12);
                          String text = 'J${value.toInt() + 1}'; // J1, J2, J3...
                          return SideTitleWidget(meta: meta, child: Text(text, style: style));
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: const SideTitles(showTitles: true, reservedSize: 30),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(
                    _dailyListeningData.length,
                        (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _dailyListeningData[index],
                          color: Colors.blue,
                          width: 15,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}