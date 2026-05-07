import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/favorite_service.dart';
import 'dart:async';
import '../services/stats_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final StatsService _statsService = StatsService();
  final LocalAuthentication auth = LocalAuthentication();
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _currentIndex;
  Timer? _listeningTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer.playingStream.listen((isPlaying) {
      if (isPlaying) {
        _listeningTimer ??= Timer.periodic(const Duration(minutes: 1), (timer) {
          _statsService.addListeningMinute();
        });
      } else {
        _listeningTimer?.cancel();
        _listeningTimer = null;
      }
    });
  }

  @override
  void dispose() {
    _listeningTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playFavoritesPlaylist(List<QueryDocumentSnapshot> favoriteDocs, int startIndex) async {
    setState(() => _currentIndex = startIndex);

    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: true,
      children: favoriteDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AudioSource.uri(
          Uri.parse(data['audioUrl']),
          tag: MediaItem(
            id: 'fav_${data['id']}',
            album: 'Mes Favoris',
            title: data['name'],
            artist: data['reciter'],
            artUri: Uri.parse(data['coverUrl']),
          ),
        );
      }).toList(),
    );

    await _audioPlayer.setAudioSource(playlist, initialIndex: startIndex, initialPosition: Duration.zero);
    _audioPlayer.play();
  }

  // NOUVEAU : Fonction pour la répétition (identique au lecteur principal)
  void _toggleRepeat() {
    if (_audioPlayer.loopMode == LoopMode.off) {
      _audioPlayer.setLoopMode(LoopMode.one);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Répétition activée"),
            duration: Duration(seconds: 1), // Moved outside the Text widget
          )
      );
    } else {
      _audioPlayer.setLoopMode(LoopMode.off);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Répétition désactivée"),
            duration: Duration(seconds: 1), // Moved outside the Text widget
          )
      );
    }
    setState(() {});
  }

  Future<void> _secureDelete(String trackId, String trackName) async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Empreinte requise pour supprimer "$trackName"',
        biometricOnly: true,
      );
    } on PlatformException catch (e) {
      print(e);
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      await _favoriteService.removeFavorite(trackId);
      // Optionnel : si on supprime la chanson en cours, on peut l'arrêter
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Favori supprimé avec succès"), backgroundColor: Colors.orange),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Suppression annulée"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Playlist Favoris'),
        backgroundColor: Colors.indigo, // Changé pour correspondre au thème
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _favoriteService.getFavoritesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Vous n'avez pas encore de favoris.", style: TextStyle(fontSize: 18)),
                  );
                }

                final favorites = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    var favorite = favorites[index].data() as Map<String, dynamic>;
                    bool isPlaying = _currentIndex == index;

                    return ListTile(
                      // Design harmonisé avec player_screen
                      tileColor: isPlaying ? Colors.indigo.withOpacity(0.2) : null,
                      leading: isPlaying
                          ? const Icon(Icons.volume_up, color: Colors.indigo)
                          : CircleAvatar(
                        backgroundImage: NetworkImage(favorite['coverUrl']),
                        backgroundColor: Colors.transparent,
                      ),
                      title: Text(favorite['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(favorite['reciter']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red), // La corbeille reste rouge pour signaler une suppression
                        onPressed: () => _secureDelete(favorite['id'].toString(), favorite['name']),
                      ),
                      onTap: () => _playFavoritesPlaylist(favorites, index),
                    );
                  },
                );
              },
            ),
          ),

          // LECTEUR HARMONISÉ
          if (_currentIndex != null)
            Container(
              padding: const EdgeInsets.all(20), // Padding ajusté pour correspondre
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