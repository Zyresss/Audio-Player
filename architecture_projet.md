# Architecture du Projet - Description des Fichiers

Afin d'avoir un code de qualité, facile à lire et à maintenir (comme recommandé en TP), j'ai adopté une architecture modulaire. J'ai séparé l'interface graphique (Dossier `screens`) de la logique métier et de la gestion des données (Dossier `services`).

Voici l'explication du rôle de chaque fichier de l'application.

## Fichiers de Configuration (Racine de `lib/`)

* **`main.dart`** : C'est le point d'entrée de l'application. Son rôle est primordial car il initialise tous les services critiques avant même le lancement de l'interface (Firebase, service audio en arrière-plan). Il configure le thème de l'application et redirige l'utilisateur vers le `BiometricScreen`.
* **`firebase_options.dart`** : Fichier généré automatiquement par le FlutterFire CLI. Il contient toutes les clés d'API et les identifiants nécessaires pour relier l'application Flutter au projet Firebase en ligne.

## Dossier `lib/screens/` (L'Interface Utilisateur - Vues)
Ce dossier contient tous les écrans visibles par l'utilisateur.

* **`biometric_screen.dart`** : Le premier écran affiché. Il vérifie si le téléphone dispose d'une empreinte digitale. Si oui, il demande l'empreinte, joue un petit son de succès, et navigue vers l'écran de connexion.
* **`login_screen.dart`** : Interface de connexion avec Email/Mot de passe. Comprend aussi la gestion de l'oubli de mot de passe.
* **`register_screen.dart`** : Écran d'inscription. Il contient une logique métier importante : un sélecteur de date de naissance complexe qui calcule l'âge exact de l'utilisateur pour vérifier la contrainte stricte d'être âgé de 13 ans ou plus.
* **`home_screen.dart`** : Le tableau de bord (Dashboard). Il récupère le Prénom et Nom depuis Firestore pour un accueil personnalisé. Il affiche les statistiques réelles (chronométrées) via `fl_chart` et gère la barre de progression par rapport à l'objectif localisé.
* **`player_screen.dart`** : Le cœur musical de l'application. Il affiche les catégories (Récitateurs) et les morceaux (Sourates) récupérés via l'API. Il inclut un mini-lecteur audio complet (Play, Pause, Suivant, Précédent, Répétition) et un bouton pour ajouter aux favoris.
* **`favorites_screen.dart`** : Affiche les morceaux sauvegardés sur Firebase. Cet écran fonctionne comme une playlist dynamique interactive. Il intègre surtout la sécurité exigée : lors du clic sur la corbeille de suppression, un pop-up natif d'empreinte digitale est déclenché.

## Dossier `lib/services/` (La Logique Métier - Contrôleurs)
Pour éviter d'avoir des fichiers UI gigantesques et illisibles, j'ai extrait toute la complexité des bases de données et des API dans ces fichiers "Services".

* **`auth_service.dart`** : Gère toutes les requêtes vers Firebase Authentication (SignIn, SignUp, SignOut). Lors de l'inscription, ce service s'occupe de créer le profil Auth, puis de pousser les données supplémentaires (Nom, Date de naissance) dans la base Firestore.
* **`api_service.dart`** : Gère la connexion vers le web. Il envoie la requête HTTP à l'API publique, parse la réponse JSON, construit les liens audio finaux, et retourne une liste propre et exploitable à l'interface.
* **`favorite_service.dart`** : S'occupe du C.R.U.D (Create, Read, Update, Delete) des favoris sur Cloud Firestore. Il utilise des `Stream` pour que l'interface utilisateur se mette à jour en temps réel dès qu'un favori est ajouté ou retiré.
* **`stats_service.dart`** : Le chronomètre intelligent de l'application. Il lit et écrit dans les `shared_preferences` pour incrémenter le temps d'écoute minute par minute (et jour par jour) de manière totalement locale, construisant ainsi les données du graphique de la page d'accueil.