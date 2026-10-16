Auteur / maintenance actuelle : CloudNine_Ex
Merci à LizardBerry pour le travail sur le projet de base.

TriviaBot-TurtleWoW 2.0.0-alpha6 — Core FR

Cette archive contient le Core et la banque française intégrée des 1 027 questions WoW originales.
- /trivia qlist wowen : banque originale en anglais
- /trivia qlist wowfr : banque française intégrée au Core, sans extension requise
- /trivia qlist mixed : banques anglaise et française de base, plus les extensions facultatives si installées
- Les banques supplémentaires restent dans l’addon TriviaBot-TurtleWoW-Questions, facultatif.

Installation : sauvegardez votre dossier existant, remplacez TriviaBot-TurtleWow par le dossier de cette archive, puis /reload.

Vérifications effectuées : XML valide, 1 027 index français présents sans trous, fichier de questions inclus dans le XML du Core, alias de réponses anglaises conservés et plusieurs alias français ajoutés.

Important : vérification statique uniquement. L’archive n’a pas été testée dans un client Turtle WoW en direct. Certaines traductions de noms de contenu spécifique doivent encore être validées en jeu / sur la base de données Turtle WoW.


Alpha7 : les banques de questions sont désormais chargées explicitement par le fichier .toc avant l'interface. Après installation, /reload puis /trivia qlist wowfr doit afficher la banque française intégrée.

Alpha8 : correction du comptage des banques comportant des index manquants. La banque française ne doit plus être tronquée par table.getn().

Alpha10 : correction d'une erreur de syntaxe Lua dans le commentaire du correctif d'indexation, qui empêchait le chargement du fichier principal et l'enregistrement des commandes.


Payments are handled manually between players and the organizer.


Alpha26: restored the visible Leaderboard toggle button in the main TriviaBot UI.


Alpha27 : bouton « Start + annonce » démarre le quiz et annonce les contributions, la fenêtre de mise de 30 secondes et les règles de départage. Les paiements restent manuels par échange direct ; aucune commande !bet.
