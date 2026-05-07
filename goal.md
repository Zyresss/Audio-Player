Université des sciences et des technologies Houari Boumediene
Département Informatique
ING 3 SEC / Développement Mobile
2025/2026
Enoncé du Projet  
Projet
La sécurité des systèmes informatiques, et en particulier des applications mobiles, est aujourd’hui
indispensable. Dans ce contexte, il est demandé de concevoir et développer une application
mobile audio, réalisée avec Flutter et intégrant Firebase. L’application devra inclure un mécanisme
d’authentification biométrique par empreinte digitale lors du premier lancement (MainActivity),
l’utilisateur devra obligatoirement utiliser son empreinte digitale pour vérifier son identité. Si
aucune empreinte n’est enregistrée sur l’appareil, il sera redirigé vers les paramètres du système
afin d’en configurer une et sécuriser ainsi son smartphone.
Une fois l’authentification biométrique validée (un son de succès doit être émis), l’utilisateur
devra accéder à un système d’authentification basé sur Firebase, s’il n’est pas déjà connecté. Ce
système permettra à l’utilisateur de créer un compte, de se connecter ou encore de réinitialiser
son mot de passe en cas d’oubli. Lors de l’inscription, certains champs seront obligatoires,
notamment le nom, le prénom et la date de naissance. L’utilisateur devra avoir un âge supérieur
ou égal à 13 ans. Les champs supplémentaires ajoutés afin d’enrichir l’application sont les
bienvenues.
Après authentification, l’utilisateur accèdera à une interface principale affichant les statistiques
d’utilisation. Cette page de statistiques présentera un message de bienvenue incluant le nom
complet de l’utilisateur (affiché en gras). Elle affichera également le nombre total d’heures et de
minutes passées en écoute, ainsi qu’un graphique (histogramme) illustrant le nombre de minutes
écoutées par jour durant le mois en cours. De plus, une liste des morceaux les plus écoutés sera
affichée. Une barre de progression permettra de visualiser l’avancement vers un objectif mensuel
d’heures d’écoute. Cet objectif pourra être défini par l’utilisateur à l’aide d’un menu déroulant,
avec une valeur par défaut fixée à 20 heures, et sera sauvegardé localement.
L’application comportera également une autre page dédiée à la sélection et à la lecture des
morceaux audio. Ce lecteur devra permettre la lecture des morceaux en arrière-plan. La playlist
devra être dynamique, organisée par catégories puis par morceaux, en utilisant une API externe,
comme par exemple https://quran.yousefheiba.com/en .Le lecteur devra proposer les
fonctionnalités de base telles que la lecture, la pause et la répétition du morceau en cours.
1
Université des sciences et des technologies Houari Boumediene
Département Informatique
ING 3 SEC / Développement Mobile
2025/2026
L’application devra également permettre à l’utilisateur d’ajouter des morceaux à une liste de
favoris. Ces favoris devront être sauvegardés en ligne via Firebase, afin de garantir leur
disponibilité même en cas de changement d’appareil. Pour renforcer la sécurité, toute
suppression d’un morceau de la liste des favoris devra nécessiter une authentification via
l’empreinte digitale.
Évaluation du projet - -
Le projet peut être réalisé en binôme.
Une présentation finale de l’application sera organisée à la fin du semestre et avant l’arrêt
de cours (à partir du 26 avril). Les éléments suivants seront évalués :
o Les fonctionnalités demandées .
o Le nom et l’identité et l’interface utilisateur de l’application.
o Les choix techniques des packages et la qualité du code comme vu dans le TP.