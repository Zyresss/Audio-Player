# Choix Techniques et Packages - Projet Mobile ING 3 SEC

## Introduction
Dans le cadre de ce projet de développement mobile, j'ai dû concevoir une application sécurisée intégrant de l'audio en arrière-plan et des bases de données. En tant qu'étudiant découvrant Flutter, j'ai cherché à structurer mon projet de manière logique et à utiliser des packages communautaires fiables pour répondre aux exigences complexes du cahier des charges (comme la biométrie et l'audio).

Voici l'explication de mes choix techniques.

## Les Packages Utilisés et Leurs Rôles

### 1. L'Écosystème Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`)
* **Pourquoi :** Firebase a été imposé par le cahier des charges, mais c'est aussi l'outil le plus accessible pour un développeur junior pour mettre en place un backend sécurisé.
* **Mon utilisation :**
    * `firebase_auth` gère la connexion, l'inscription et la réinitialisation des mots de passe.
    * `cloud_firestore` (la base de données NoSQL) est utilisé car Firebase Auth ne stocke par défaut que l'email et le mot de passe. J'avais besoin de Firestore pour stocker le Nom, Prénom, la Date de naissance de l'utilisateur, ainsi que sa liste de favoris (pour qu'elle soit synchronisée en ligne).

### 2. La Sécurité Biométrique (`local_auth`)
* **Pourquoi :** Le projet exigeait une vérification d'empreinte digitale au lancement et lors de la suppression d'un favori.
* **Mon utilisation :** J'ai utilisé ce package car il permet de faire le pont entre Flutter et les capteurs natifs d'Android. Il m'a demandé de modifier certains fichiers Kotlin (`MainActivity.kt`), ce qui m'a appris comment Flutter interagit avec le code natif de l'OS.

### 3. La Gestion Audio (`just_audio`, `just_audio_background`)
* **Pourquoi :** Il fallait un lecteur audio capable de continuer la lecture en arrière-plan (quand l'application est réduite).
* **Mon utilisation :** `just_audio` est l'un des packages les plus robustes. L'extension `just_audio_background` m'a permis de lier le lecteur audio aux contrôles médias du téléphone (sur l'écran de verrouillage). C'était la partie la plus difficile du projet car elle demandait de gérer les services Android natifs et les conflits avec la biométrie !

### 4. La Consommation d'API (`http`)
* **Pourquoi :** L'application devait récupérer une playlist dynamique organisée par catégories via une API externe.
* **Mon utilisation :** J'utilise le package `http` pour envoyer des requêtes GET à l'API publique (mp3quran.net). J'utilise `dart:convert` pour décoder le JSON reçu et transformer les données brutes en listes affichables dans mon application.

### 5. Le Stockage Local (`shared_preferences`)
* **Pourquoi :** Le projet demandait de sauvegarder l'objectif mensuel d'heures d'écoute localement.
* **Mon utilisation :** Plutôt que de faire des appels réseau coûteux vers Firebase pour un simple chiffre (20 heures), `shared_preferences` permet d'écrire directement dans la mémoire cache du téléphone de façon très simple et instantanée. Je l'ai aussi utilisé pour stocker le chronomètre des statistiques journalières.

### 6. Les Graphiques (`fl_chart`)
* **Pourquoi :** Il fallait afficher un histogramme du temps d'écoute des 7 derniers jours.
* **Mon utilisation :** C'est la bibliothèque la plus populaire pour les graphiques sur Flutter. Elle me permet de lier dynamiquement les données calculées par mon `StatsService` à un rendu visuel clair et interactif.