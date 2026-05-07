import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/api_service.dart';
import '../services/favorite_service.dart';
import 'dart:async'; // Requis pour le chronomètre
import '../services/stats_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FavoriteService _favoriteService = FavoriteService();
  final StatsService _statsService = StatsService();
  Timer? _listeningTimer;

  // Nos Catégories (Récitateurs) et leurs serveurs API respectifs
  final Map<String, String> _categories = {
    'Mishary Alafasy': 'https://server8.mp3quran.net/afs',
    'Abdul Basit': 'https://server7.mp3quran.net/basit',
    'Yasser Al Dosari': 'https://server11.mp3quran.net/yasser',
  };

  String _selectedCategoryName = 'Mishary Alafasy';
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  int? _currentIndex;

  @override
  void initState() {
    super.initState();
    _loadTracks();

    // NOUVEAU : Écoute si le lecteur est en train de jouer ou est en pause
    _audioPlayer.playingStream.listen((isPlaying) {
      if (isPlaying) {
        // Démarrer le chronomètre (1 tick chaque minute)
        _listeningTimer ??= Timer.periodic(const Duration(minutes: 1), (timer) {
          _statsService.addListeningMinute();
        });
      } else {
        // Arrêter le chronomètre
        _listeningTimer?.cancel();
        _listeningTimer = null;
      }
    });
  }

  Future<void> _loadTracks() async {
    setState(() => _isLoading = true);

    // Récupérer le serveur du récitateur sélectionné
    String serverUrl = _categories[_selectedCategoryName]!;

    // Charger les morceaux depuis l'API
    final tracks = await _apiService.fetchSurahsByCategory(serverUrl);

    // Créer la playlist pour just_audio_background
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: tracks.map((track) {
        return AudioSource.uri(
          Uri.parse(track['audioUrl']), // Le lien MP3
          tag: MediaItem(
            id: track['id'],
            album: 'Coran',
            title: track['name'],
            artist: _selectedCategoryName, // Le nom du récitateur
            artUri: Uri.parse(track['coverUrl']),
          ),
        );
      }).toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);

    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  void _playTrack(int index) async {
    setState(() => _currentIndex = index);
    await _audioPlayer.seek(Duration.zero, index: index);
    _audioPlayer.play();
  }

  void _toggleRepeat() {
    if (_audioPlayer.loopMode == LoopMode.off) {
      _audioPlayer.setLoopMode(LoopMode.one);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Répétition activée")));
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Répétition désactivée")));
    }
    setState(() {});
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecteur Coranique'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // SÉLECTEUR DE CATÉGORIE (Récitateurs)
          Container(
            height: 60,
            color: Colors.indigo.withOpacity(0.1),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.keys.length,
              itemBuilder: (context, index) {
                final categoryName = _categories.keys.elementAt(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
                  child: ChoiceChip(
                    label: Text(categoryName),
                    selectedColor: Colors.indigo.withOpacity(0.4),
                    selected: _selectedCategoryName == categoryName,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategoryName = categoryName;
                          _currentIndex = null;
                        });
                        _loadTracks(); // Recharge la playlist API
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // LISTE DES MORCEAUX (Sourates)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final isPlaying = _currentIndex == index;

                return ListTile(
                  tileColor: isPlaying ? Colors.indigo.withOpacity(0.2) : null,
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(track['coverUrl']),
                    backgroundColor: Colors.transparent,
                  ),
                  title: Text(track['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_selectedCategoryName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () async {
                          await _favoriteService.addFavorite(track, _selectedCategoryName);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("${track['name']} ajouté aux favoris !"),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () => _playTrack(index),
                );
              },
            ),
          ),

          // CONTRÔLES DU LECTEUR EN BAS
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _audioPlayer.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                    color: _audioPlayer.loopMode == LoopMode.one ? Colors.indigo : Colors.black,
                  ),
                  onPressed: _toggleRepeat,
                  iconSize: 30,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => _audioPlayer.seekToPrevious(),
                  iconSize: 40,
                ),
                StreamBuilder<PlayerState>(
                  stream: _audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
                      return Container(margin: EdgeInsets.all(8.0), width: 40, height: 40, child: CircularProgressIndicator());
                    } else if (playing != true) {
                      return IconButton(
                        icon: const Icon(Icons.play_circle_fill),
                        iconSize: 60,
                        color: Colors.indigo,
                        onPressed: _audioPlayer.play,
                      );
                    } else {
                      return IconButton(
                        icon: const Icon(Icons.pause_circle_filled),
                        iconSize: 60,
                        color: Colors.indigo,
                        onPressed: _audioPlayer.pause,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => _audioPlayer.seekToNext(),
                  iconSize: 40,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}