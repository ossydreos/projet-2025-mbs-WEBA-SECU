# Rapport de Correction des Bugs - My Mobility Services

**Date:** 16 octobre 2025  
---

## Résumé des Bugs Corrigés

### Bug 1: Géolocalisation non mise à jour après activation des permissions
**Problème:** Quand on refusait la géolocalisation au départ puis qu’on l’activait ensuite dans les réglages, l’app restait bloquée sur la carte d’Onex parce qu’elle croyait déjà connaître la position.

**Solution implémentée:**
- Dans lib/screens/utilisateur/reservation/acceuil_res_screen.dart la fonction '_centerOnUser()' vérifie désormais si   elle possède vraiment une coordonnée; si ce n’est pas le cas, elle relance immédiatement la récupération GPS ('_getUserLocation()'), ce qui force l’app à rapatrier la vraie position et à déplacer la carte sans redémarrage.

---

### Bug 2: Modification des infos personnelles
**Problème:** Le bouton de modification des infos perso n'était pas connecté.

**Solution implémentée:**
 - Connecter page au bouton

---

### Bug 3: Validation des filtres de dates et reinitialisation des filtres
**Problème:** L'utilisateur peut sélectionner uniquement une date de début ou de fin dans les filtres, puis appliquer le filtre qui ne fait rien, créant de la confusion. Pareil pour la reinitialisation.

**Solution implémentée:**

- Dans lib/design/filters/date/lg_date_range_calendar.dart, j’ai changé la logique du calendrier pour qu’un simple tap choisisse un intervalle d’un jour (début = fin) et qu’un second tap sur le même jour supprime la sélection, ce qui permet enfin d’appliquer un filtre sur une seule date sans fermer le panneau pour rien; puis, dans lib/data/models/reservation_filter.dart , j’ai fait évoluer copyWith() en introduisant un marqueur interne afin que, quand on appuie sur Réinitialiser, les champs startDate et endDate soient vraiment remis à null, le bouton Appliquer envoyant alors un filtre vide au lieu de conserver les anciennes valeurs.




---

### Bug 4: Pastille de notification pour les messages dans une course
**Problème:** Aucune pastille n'indique à l'utilisateur qu'il a reçu un message dans le chat d'une course et dans tous les autres chat.

**Solution implémentée:**

- J’ai relié chaque écran à Firestore pour surveiller les fils de discussion appropriés (RideChatService.threadsCollection pour les conversations trajets et SupportChatService.threadsCollection pour le support), puis j’ai converti les résultats en petites “signatures” texte stockées dans accueil_res_screen.dart côté client et admin_navbar.dart côté admin. À chaque fois qu’une signature change (donc qu’un message arrive ou qu’une course passe en inProgress), l’écran déclenche la pastille sur le bon onglet (CustomBottomNavigationBar, AdminBottomNavigationBar). Quand l’utilisateur ouvre l’onglet concerné, on remet la signature mémorisée au même état que la nouvelle, ce qui supprime la pastille. Autrement dit, pas besoin de connaître Flutter en profondeur : on écoute des flux de données Firebase, on fabrique une chaîne de caractères pour détecter les changements, et on synchronise l’état de la pastille avec ce qu’on a déjà “vu”.

---

### Bug 5: Bug graphique lors du swipe vers le bas dans l'onglet trajets
**Problème:** Problème graphique quand l'utilisateur swipe vers le bas (page qui monte) dans l'onglet trajets.

**Solution implémentée:**
- J’ai supprimé l’effet “stretch” de Flutter qui étirait l’écran en cas de swipe en ajoutant un comportement de scroll personnalisé dans lib/main.dart, puis j’ai gardé ce même blocage sur l’écran des trajets (lib/screens/utilisateur/trajets/trajets_screen.dart) et veillé à ce que le fond en verre soit découpé proprement via lib/theme/glassmorphism_theme.dart. Résultat : même sur ton téléphone, le fond ne se déforme plus quand tu tires la liste vers le bas.


---

### Bug 6 (CRITIQUE): Problèmes d'accès concurrentiels
**Problème:** Des actions simultanées créent des problèmes de concurrence dans la base de données Firestore.

**Solution implémentée:**
- Quand l’admin essaie d’annuler une course via ReservationService.updateReservationStatus()(lib/data/services/reservation_service.dart), on regarde d’abord le statut actuel : si c’est déjà ReservationStatus.inProgress ou ReservationStatus.completed, on balance une exception et ça bloque l’annulation pour éviter que tout parte en vrille quand le paiement a déjà fait avancer la course. Et si, pendant ce temps, le client finit quand même de payer sur Stripe, _handleSuccessfulPayment()dans StripeCheckoutService (lib/data/services/stripe_checkout_service.dart) voit que la course est annulée, déclenche le remboursement et laisse la réservation et la custom offer en mode annulé, donc personne ne se retrouve avec une fausse course “à venir”.
---

### Bug 7 : Son personnalisé alerte
**Problème:** Il fallait un son puissant pour les notifications

**Solution implémentée:**
- Étape 1 – Fichier son local : on a glissé le fichier uber_classic_retro.wav dans android/app/src/main/res/raw/. Android lit automatiquement tout ce qui est dans ce dossier, pas besoin de Flutter avancé.Étape 2 – Canal OneSignal : dans le tableau de bord OneSignal, on a créé un “Android Notification Channel” en lui donnant un nom, en le réglant sur importance High et en choisissant ce même son uber_classic_retro.wav. Un canal, c’est comme un profil de notif : Android se rappelle du son associé tant que l’application reste installée.Étape 3 – Back-end : dans la Cloud Function onReservationCreate() de functions/src/index.ts, on envoie la notif en précisant l’ID du canal (androidChannelId: "b842a17b-cf2b-42d9-8830-08405eeb4f3d"). Dès qu’une réservation “pending” est créée, OneSignal pousse la notif en utilisant ce canal, donc ce son.Réinstallation : Android ne reconfigure pas un canal déjà créé. Après avoir changé le son dans le dashboard, il faut réinstaller l’appli (ou purger le canal) pour que le téléphone prenne en compte la nouvelle configuration.
---