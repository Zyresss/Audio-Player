import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:app_settings/app_settings.dart';
import 'package:just_audio/just_audio.dart';
import 'screens/login_screen.dart';
import 'package:just_audio_background/just_audio_background.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _authorized = 'Not Authenticated';

  @override
  void initState() {
    super.initState();
    _checkBiometricsAndAuthenticate();
  }

  Future<void> _checkBiometricsAndAuthenticate() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        // Rediriger vers les paramètres si aucune empreinte n'est configurée
        _showSettingsDialog();
        return;
      }

      // Proceed to authenticate
      _authenticate();

    } on PlatformException catch (e) {
      print(e);
    }
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      // We removed the 'options:' wrapper to match your installed package version
      authenticated = await auth.authenticate(
        localizedReason: 'Veuillez utiliser votre empreinte digitale pour accéder à l\'application',
        biometricOnly: true, // Force biometric (fingerprint/face) not PIN
      );
    } on PlatformException catch (e) {
      print(e);
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      setState(() {
        _authorized = 'Authentification Réussie !';
      });
      // Jouer le son de succès
      // Jouer le son de succès avec le tag requis par just_audio_background
      await _audioPlayer.setAudioSource(
        AudioSource.asset(
          'assets/sounds/success.mp3',
          tag: const MediaItem(
            id: 'success_sound',
            title: 'Authentification réussie',
          ),
        ),
      );
      await _audioPlayer.play();

      // TODO: Move to Firebase Auth Screen (Part 3)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      setState(() {
        _authorized = 'Échec de l\'authentification';
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sécurité requise'),
          content: const Text(
              'Aucune empreinte digitale n\'est configurée sur cet appareil. '
                  'Veuillez en configurer une dans les paramètres de votre système pour sécuriser l\'application.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Ouvrir les paramètres'),
              onPressed: () {
                Navigator.of(context).pop();
                AppSettings.openAppSettings(type: AppSettingsType.security);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 100, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(_authorized, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkBiometricsAndAuthenticate,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}