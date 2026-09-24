# Reconstruction complète de Bujumbura Bitcoin Builders

## Résultat attendu
- Reprendre fidèlement l’application fournie : identité visuelle, contenus bilingues, navigation et affichage mobile.
- Restaurer toutes les pages publiques : accueil, programme, agenda, formateurs, projets, participants, contact et projet d’équipe.
- Restaurer les inscriptions au bootcamp avec choix de l’édition, validation et confirmation.
- Restaurer l’espace privé : connexion administrateur, tableau de suivi, candidatures, cohortes, agenda, intervenants, projets, messages et réglages.
- Reprendre les éditions Bujumbura et Gitega, avec leurs dates, contenus et journées propres.
- Restaurer l’installation mobile de l’application et les médias fournis.

## Données et sécurité
- Recréer dans Lovable Cloud les tables, fonctions, règles d’accès et données initiales présentes dans les migrations fournies.
- Conserver les données publiques accessibles sans compte, tout en limitant la gestion aux administrateurs authentifiés.
- Activer la connexion par e-mail pour l’espace de gestion et préserver les contrôles d’accès côté serveur.

## Vérification
- Vérifier toutes les pages et tous les liens sur ordinateur et mobile.
- Tester le changement d’édition et de langue, l’inscription, le formulaire de contact et la consultation des contenus publics.
- Tester la connexion et les fonctions principales du tableau de suivi.
- Corriger toute erreur de compilation, d’affichage ou de communication avec Lovable Cloud.

## Détails techniques
- Adapter le code fourni à la version actuelle de TanStack Start sans modifier les fichiers générés.
- Importer seulement les sources, médias et migrations utiles, sans reprendre les secrets, métadonnées Git ou fichiers générés.
- Ajouter des métadonnées propres à chaque page pour le titre, la description et le partage social.
