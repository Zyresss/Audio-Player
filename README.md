# 🎧 Audio Player App - Projet (Développement Mobile)

L'objectif de ce projet est de concevoir un lecteur audio interactif intégrant des mesures de sécurité strictes (biométrie), une authentification cloud, et une gestion avancée de l'audio en arrière-plan.

---

## 🛠️ Technologies et Packages Utilisés

L'application repose sur le framework **Flutter** et utilise plusieurs packages pour répondre aux exigences du cahier des charges :

### 1. Sécurité et Authentification
* **`firebase_core` & `firebase_auth`** : Gestion de l'authentification backend (Création de compte, Connexion, Mot de passe oublié).
* **`cloud_firestore`** : Base de données NoSQL pour stocker les profils utilisateurs (Nom, Prénom, Date de Naissance) et la liste des favoris de manière synchronisée.
* **`local_auth`** : Permet l'authentification biométrique (Empreinte digitale/FaceID) native. Utilisé au lancement de l'application et pour la suppression sécurisée d'un favori.
* **`app_settings`** : Redirige l'utilisateur vers les paramètres de son téléphone s'il n'a pas configuré d'empreinte digitale.

### 2. Gestion Audio
* **`just_audio`** : Le moteur principal du lecteur audio (Play, Pause, Précédent, Suivant, Répétition).
* **`just_audio_background`** : Permet à l'audio de continuer à jouer quand l'application est réduite, et affiche un contrôleur multimédia sur l'écran de verrouillage du téléphone.

### 3. Données et Interface
* **`http`** : Pour effectuer des requêtes vers l'API externe (mp3quran.net) afin de récupérer la playlist dynamique.
* **`shared_preferences`** : Stockage local (cache) pour sauvegarder l'objectif mensuel d'heures d'écoute et les données du chronomètre d'utilisation.
* **`fl_chart`** : Bibliothèque pour tracer l'histogramme des 7 derniers jours sur le tableau de bord.

---

## 📂 Architecture du Projet (Dossier `lib/`)

```text
lib/
│
├── main.dart                  # Point d'entrée de l'application
├── firebase_options.dart      # Configuration générée par FlutterFire
├── biometric_screen.dart  # Écran de vérification de l'empreinte au lancement
├── screens/                   # Vues de l'application (Interface Graphique)
│   ├── login_screen.dart      # Écran de connexion Firebase
│   ├── register_screen.dart   # Écran d'inscription avec validation de l'âge
│   ├── home_screen.dart       # Tableau de bord (Statistiques, Graphique, Objectif)
│   ├── player_screen.dart     # Lecteur audio principal et parcours de l'API
│   └── favorites_screen.dart  # Playlist des favoris et suppression sécurisée
│
└── services/                  # Logique métier et accès aux données
    ├── api_service.dart       # Requêtes HTTP vers l'API externe
    ├── auth_service.dart      # Logique de connexion et création Firestore
    ├── favorite_service.dart  # CRUD Firestore pour les morceaux favoris
    └── stats_service.dart     # Chronomètre local et historique d'écoute
```

# Explication Détaillée des Fichiers et de leurs Fonctions

Ce document détaille le rôle et les fonctionnalités de chaque fichier composant l'application **Secure Audio App**.

## 📁 Les Fichiers Racines

### `main.dart`
* **main()** : Fonction asynchrone qui s'assure que les widgets sont initialisés, lance le service `JustAudioBackground.init` (requis pour l'audio en arrière-plan) AVANT d'initialiser Firebase, puis lance l'application.
* **MyApp** : Widget principal configurant le thème visuel (Colors.teal, Colors.indigo, etc.) et définissant BiometricScreen comme première route.
---

## 📁 Dossier `lib/screens/` (Interface Utilisateur)

### `biometric_screen.dart`
* **_checkBiometricsAndAuthenticate()** : Vérifie si le téléphone supporte la biométrie et si une empreinte est enregistrée. Si non, appelle _showSettingsDialog()**.
* **_authenticate()** : Lance la modale système de scan d'empreinte. En cas de succès, joue le fichier success.mp3 en y attachant un MediaItem (requis par just_audio_background), puis navigue vers LoginScreen.
* **_showSettingsDialog()** : Affiche une alerte forçant l'utilisateur à ouvrir les paramètres de son téléphone via le package app_settings.

### `login_screen.dart`
* **_login()** : Vérifie que les champs ne sont pas vides, appelle AuthService.signIn()**, et redirige vers HomeScreen si les identifiants sont corrects.
* **_resetPassword()** : Envoie un email de réinitialisation via AuthService.

### `register_screen.dart`
* **_selectDate()** : Ouvre un showDatePicker positionné par défaut 13 ans dans le passé pour faciliter la sélection.
* **_isOldEnough(DateTime)** : Algorithme critique qui calcule l'âge exact en années (en tenant compte des jours et mois) pour garantir que l'utilisateur a >= 13 ans.
* **_register()** : Vérifie tous les champs, valide l'âge, et appelle AuthService. signUp()** pour créer le compte et sauvegarder les données dans Firestore.

### `home_screen.dart`
* **_loadStatsAndGoal()** : Lit les shared_preferences au chargement de la page pour récupérer les statistiques réelles d'écoute via StatsService.
* **_loadUserData()** : Fait une requête Firestore pour récupérer le Prénom et le Nom de l'utilisateur afin de les afficher en gras dans le message de bienvenue.
* **_saveGoal()** : Sauvegarde la valeur du menu déroulant (objectif mensuel) dans la mémoire locale.

### `player_screen.dart`
* **initState()** : Charge la playlist de l'API et lance un chronomètre (Timer.periodic) qui écoute le flux audio. Si l'audio joue, il ajoute 1 minute aux statistiques via StatsService toutes les 60 secondes.
* **_loadTracks()** : Appelle ApiService pour la catégorie sélectionnée, puis convertit la liste JSON en ConcatenatingAudioSource pour just_audio.
* **_playTrack(index)** : Fait sauter le lecteur à l'index sélectionné et lance la musique.
* **_toggleRepeat()** : Bascule entre LoopMode.off et LoopMode.one (Répéter le morceau actuel).

### `favorites_screen.dart`
* **_playFavoritesPlaylist()** : Convertit les documents Firestore affichés à l'écran en une véritable playlist audio jouable, permettant de faire "Suivant" pour écouter tous ses favoris d'un coup.
* **_secureDelete()** : La fonction de sécurité la plus importante du projet. Avant d'autoriser la suppression d'un favori, elle appelle auth.authenticate()**. Si l'empreinte échoue, l'action est annulée.

---

## 📁 Dossier `lib/services/` (Logique Métier)

### `auth_service.dart`
* **signIn()** : Wrapper pour FirebaseAuth.instance.signInWithEmailAndPassword.
* **signUp()** : Créé l'utilisateur, puis utilise l'UID généré pour créer un document dans la collection users de Firestore contenant le nom, le prénom, et la date de naissance.
* **signOut()** / resetPassword()** : Wrappers pour la déconnexion et la récupération de mot de passe.

### `api_service.dart`
* **fetchSurahsByCategory(url)** : Effectue un http.get vers mp3quran.net. Décode le JSON, limite le retour aux 20 premiers éléments pour l'optimisation, et formate manuellement les URLs audio (ex: 001.mp3) en fonction du serveur du récitateur.

### `favorite_service.dart`
* **get _userFavorites** : Propriété privée retournant la référence exacte de la sous-collection Firestore (users/{uid}/favorites).
* **addFavorite()** : Crée un document contenant les métadonnées de la chanson (ID, nom, URL audio, URL image).
* **getFavoritesStream()** : Renvoie un Stream<QuerySnapshot> permettant au StreamBuilder du FavoritesScreen de se mettre à jour en temps réel.
* **removeFavorite(trackId)** : Supprime le document spécifié.

### `stats_service.dart`
* **addListeningMinute()** : Récupère le dictionnaire JSON des statistiques journalières dans les shared_preferences, incrémente la date d'aujourd'hui (+1), incrémente le total global (+1), et sauvegarde.
* **getTotalMinutes()** : Renvoie simplement le total global pour le formater en Heures/Minutes.
* **getLast7DaysStats()** : Génère les 7 derniers jours (y compris aujourd'hui), cherche leurs valeurs dans les préférences locales, et retourne une List<double> prête à être injectée dans le graphique fl_chart.