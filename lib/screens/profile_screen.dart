// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/widget_navBar.dart';
import '../widgets/authgate.dart';
import '../theme/theme_app.dart';

/// Modèle utilisateur (temporaire - sans Firebase)
class Utilisateur {
  final String uid;
  final String nom;
  final String email;
  final String telephone;
  final DateTime dateCreation;

  Utilisateur({
    required this.uid,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.dateCreation,
  });
}

/// Écran de profil - Version thématisée sombre
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtenir les données utilisateur depuis Firebase Auth
  User? get _currentUser => _auth.currentUser;
  
  // Données utilisateur avec Firebase Auth
  Utilisateur get _utilisateur {
    if (_currentUser != null) {
      print('ProfileScreen - Utilisateur connecté: ${_currentUser!.email}');
      print('ProfileScreen - DisplayName: ${_currentUser!.displayName}');
      return Utilisateur(
        uid: _currentUser!.uid,
        nom: _currentUser!.displayName ?? _currentUser!.email?.split('@')[0] ?? 'Utilisateur',
        email: _currentUser!.email ?? 'email@example.com',
        telephone: _currentUser!.phoneNumber ?? '+33 0 00 00 00 00',
        dateCreation: _currentUser!.metadata.creationTime ?? DateTime.now(),
      );
    } else {
      print('ProfileScreen - Aucun utilisateur connecté');
      // Utilisateur par défaut si pas connecté
      return Utilisateur(
        uid: 'guest',
        nom: 'Invité',
        email: 'invite@example.com',
        telephone: '+33 0 00 00 00 00',
        dateCreation: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        return Scaffold(
          // ✅ Utilise le thème sombre automatiquement
          appBar: AppBar(
            title: const Text('Profil'),
            centerTitle: true,
            // Le thème AppBarTheme s'applique automatiquement
          ),
          body: Stack(
            children: [
              // Contenu principal
              _buildContent(),
              // Barre de navigation en bas
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomBottomNavigationBar(
                  currentIndex: 2,
                  onTap: _handleNavigation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Gestion de la navigation
  void _handleNavigation(int index) {
    if (index == 2) return; // Déjà sur la page profil

    switch (index) {
      case 0: // Accueil
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Trajets
        Navigator.pushReplacementNamed(context, '/trajets');
        break;
    }
  }

  /// Contenu principal avec padding pour éviter le chevauchement
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildHeader(),
            _buildUpdateAccountCard(),
            _buildMenuSection(),
            _buildLocationSection(),
            _buildSettingsSection(),
            _buildAccountActions(),
          ],
        ),
      ),
    );
  }

  /// Header avec photo et infos utilisateur - THÉMATISÉ
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.surface, // ✅ Couleur du thème
      child: Column(
        children: [
          // Photo de profil avec couleur accent
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: Icon(
              Icons.person,
              size: 60,
              color: AppColors.accent, // ✅ Couleur accent
            ),
          ),
          const SizedBox(height: 15),
          // Nom en blanc (thème appliqué automatiquement)
          Text(_utilisateur.nom, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          // Email avec couleur secondaire
          Text(
            _utilisateur.email,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary, // ✅ Couleur secondaire
            ),
          ),
        ],
      ),
    );
  }

  /// Carte de mise à jour - THÉMATISÉE
  Widget _buildUpdateAccountCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 20, 15, 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface, // ✅ Surface sombre
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.3),
        ), // ✅ Bordure accent
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accent), // ✅ Icône accent
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              'Mettez à jour vos informations de compte',
              style: Theme.of(context).textTheme.bodyMedium, // ✅ Texte blanc
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// Section menu - THÉMATISÉE
  Widget _buildMenuSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              'Menu',
              style: Theme.of(context).textTheme.titleLarge, // ✅ Titre blanc
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface, // ✅ Surface sombre
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.directions_car, 'Mes réservations'),
                _buildMenuItem(Icons.history, 'Historique'),
                _buildMenuItem(Icons.payment, 'Paiements'),
                _buildMenuItem(Icons.help_outline, 'Aide'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section localisation - THÉMATISÉE
  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              'Localisation',
              style: Theme.of(context).textTheme.titleLarge, // ✅ Titre blanc
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface, // ✅ Surface sombre
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.location_on, 'Adresses sauvegardées'),
                _buildMenuItem(Icons.map, 'Gérer les lieux favoris'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section paramètres - THÉMATISÉE
  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              'Paramètres',
              style: Theme.of(context).textTheme.titleLarge, // ✅ Titre blanc
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface, // ✅ Surface sombre
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildMenuItem(Icons.notifications, 'Notifications'),
                _buildMenuItem(Icons.privacy_tip, 'Confidentialité'),
                _buildMenuItem(Icons.language, 'Langue'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Actions de compte - THÉMATISÉES
  Widget _buildAccountActions() {
    return Container(
      margin: const EdgeInsets.all(15),
      child: Column(
        children: [
          // Bouton déconnexion
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface, // ✅ Surface sombre
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                _showLogoutDialog();
              },
            ),
          ),
          const SizedBox(height: 10),
          // Informations compte
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: AppColors.background, // ✅ Background noir
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface),
            ),
            child: Column(
              children: [
                Text(
                  'Membre depuis le ${DateFormat('dd/MM/yyyy').format(_utilisateur.dateCreation)}',
                  style: TextStyle(
                    color: AppColors.textSecondary, // ✅ Texte secondaire
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'ID: ${_utilisateur.uid}',
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Item de menu réutilisable - THÉMATISÉ
  Widget _buildMenuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary), // ✅ Icône secondaire
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium, // ✅ Texte blanc
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.textSecondary.withOpacity(0.6),
      ),
      onTap: () {
        _showFeatureDialog(title);
      },
    );
  }

  /// Dialog de confirmation de déconnexion - THÉMATISÉ
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface, // ✅ Dialog sombre
          title: Text(
            'Déconnexion',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _performLogout();
              },
              child: Text(
                'Déconnexion',
                style: TextStyle(color: AppColors.accent), // ✅ Couleur accent
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dialog pour les fonctionnalités à implémenter - THÉMATISÉ
  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface, // ✅ Dialog sombre
          title: Text(feature, style: Theme.of(context).textTheme.titleLarge),
          content: Text(
            'Cette fonctionnalité sera bientôt disponible.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.accent), // ✅ Couleur accent
              ),
            ),
          ],
        );
      },
    );
  }

  /// Déconnexion réelle avec Firebase Auth
  Future<void> _performLogout() async {
    try {
      print('ProfileScreen - Début de la déconnexion');
      await _auth.signOut();
      print('ProfileScreen - signOut() terminé');
      
      // Forcer la navigation vers l'écran de connexion
      if (mounted) {
        print('ProfileScreen - Navigation vers AuthGate');
        // Naviguer vers AuthGate qui gérera la redirection
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Authgate()),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Déconnexion réussie'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      print('ProfileScreen - Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
