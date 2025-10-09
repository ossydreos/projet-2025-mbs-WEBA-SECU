// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/widgets/authgate.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'favorite_trips_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../legal/terms_conditions_screen.dart';
import '../legal/legal_mentions_screen.dart';

/// Modèle utilisateur avec données Firestore
class Utilisateur {
  final String uid;
  final String nom;
  final String email;
  final String telephone;
  final DateTime dateCreation;
  final bool emailVerified;
  final String provider;

  Utilisateur({
    required this.uid,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.dateCreation,
    required this.emailVerified,
    required this.provider,
  });

  factory Utilisateur.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final phone = data['phone'] ?? '';
    final countryCode = data['countryCode'] ?? '+33';
    
    return Utilisateur(
      uid: data['uid'] ?? '',
      nom: data['name'] ?? 'Utilisateur', // On garde ça comme fallback statique
      email: data['email'] ?? '',
      telephone: phone.isNotEmpty ? phone : 'Not provided', // Will be translated in widget
      dateCreation: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emailVerified: data['emailVerified'] ?? false,
      provider: data['provider'] ?? 'password',
    );
  }
}

/// Écran de profil - Version thématisée sombre
class ProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const ProfileScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir les données utilisateur depuis Firebase Auth
  User? get _currentUser => _auth.currentUser;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      initialData: _auth.currentUser,
      builder: (context, authSnapshot) {
        final hasAuth = authSnapshot.data != null;
        if (authSnapshot.connectionState == ConnectionState.waiting && !hasAuth) {
          return const GlassBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (authSnapshot.data == null) {
          return const Authgate();
        }

        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(authSnapshot.data!.uid).snapshots(),
          initialData: null,
          builder: (context, userSnapshot) {
            final hasUserData = userSnapshot.hasData && userSnapshot.data?.data() != null;
            if (userSnapshot.connectionState == ConnectionState.waiting && !hasUserData) {
              final loading = const Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(child: CircularProgressIndicator()),
              );
              return widget.showBottomBar ? GlassBackground(child: loading) : loading;
            }

            final utilisateur = userSnapshot.hasData 
                ? Utilisateur.fromFirestore(userSnapshot.data!)
                : _getDefaultUser(authSnapshot.data!);

            final scaffold = Scaffold(
              backgroundColor: Colors.transparent,
              appBar: GlassAppBar(title: AppLocalizations.of(context).profile),
              body: Stack(
                children: [
                  // Contenu principal avec espacement
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _buildContent(utilisateur),
                  ),
                  // Barre de navigation en bas
                  if (widget.showBottomBar)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: CustomBottomNavigationBar(
                        currentIndex: 3,
                        onTap: _handleNavigation,
                      ),
                    ),
                ],
              ),
            );

            return widget.showBottomBar ? GlassBackground(child: scaffold) : scaffold;
          },
        );
      },
    );
  }

  Utilisateur _getDefaultUser(User user) {
    return Utilisateur(
      uid: user.uid,
      nom: user.displayName ?? user.email?.split('@')[0] ?? 'Utilisateur', // Fallback statique
      email: user.email ?? 'email@example.com',
      telephone: user.phoneNumber ?? 'Not provided', // Will be translated in widget
      dateCreation: user.metadata.creationTime ?? DateTime.now(),
      emailVerified: user.emailVerified,
      provider: 'password',
    );
  }

  /// Gestion de la navigation
  void _handleNavigation(int index) {
    if (index == 3) return; // Déjà sur la page profil
    widget.onNavigate?.call(index);
  }

  /// Navigation vers les trajets favoris
  void _navigateToFavoriteTrips() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FavoriteTripsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }


  /// Contenu principal avec padding pour éviter le chevauchement
  Widget _buildContent(Utilisateur utilisateur) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildHeader(utilisateur),
            const SizedBox(height: 20),
            _buildUserInfoSection(utilisateur),
            const SizedBox(height: 16),
            _buildFavoriteTripsSection(),
            const SizedBox(height: 16),
            _buildLegalSection(),
            const SizedBox(height: 16),
            _buildAccountActions(utilisateur),
          ],
        ),
      ),
    );
  }

  /// Header avec photo et infos utilisateur - THÉMATISÉ
  Widget _buildHeader(Utilisateur utilisateur) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Photo de profil avec couleur accent
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.accent.withOpacity(0.2),
            child: Icon(Icons.person, size: 60, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          // Nom en blanc (thème appliqué automatiquement)
          Text(utilisateur.nom, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          // Email avec couleur secondaire
          Text(
            utilisateur.email,
            style: TextStyle(fontSize: 16, color: AppColors.text),
          ),
        ],
      ),
    );
  }

  /// Section informations utilisateur détaillées
  Widget _buildUserInfoSection(Utilisateur utilisateur) {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).personalInfo,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Implémenter la navigation vers l'écran de modification
                    _showFeatureDialog(AppLocalizations.of(context).editInfo);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withOpacity(0.2),
                    foregroundColor: AppColors.accent,
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.accent),
                    ),
                    elevation: 0,
                    minimumSize: const Size(40, 40),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.person, AppLocalizations.of(context).fullName, utilisateur.nom),
                Divider(
                  color: AppColors.glassStroke,
                  thickness: 1,
                  height: 1,
                ),
                _buildInfoRow(Icons.email, AppLocalizations.of(context).email, utilisateur.email),
                Divider(
                  color: AppColors.glassStroke,
                  thickness: 1,
                  height: 1,
                ),
                _buildInfoRow(Icons.phone, AppLocalizations.of(context).phoneNumber, 
                  utilisateur.telephone == 'Not provided' ? AppLocalizations.of(context).notProvided : utilisateur.telephone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Ligne d'information réutilisable - HARMONISÉE AVEC MENU
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône avec container glass comme dans le menu
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 16),

          // Textes avec même style que le menu - CORRIGÉ POUR OVERFLOW
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: null, // Permet plusieurs lignes
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }





  /// Section trajets favoris - THÉMATISÉE
  Widget _buildFavoriteTripsSection() {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: Text(
              AppLocalizations.of(context).favoriteTrips,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildMenuItem(Icons.favorite, AppLocalizations.of(context).favoriteTrips, () => _navigateToFavoriteTrips()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Actions de compte - THÉMATISÉES
  Widget _buildAccountActions(Utilisateur utilisateur) {
    return GlassContainer(
      margin: const EdgeInsets.all(15),
      child: Column(
        children: [
          // Bouton déconnexion - STYLE GLASSMORPHIQUE
          GlassContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showLogoutDialog();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).disconnectButton,
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textWeak,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    AppLocalizations.of(context).logoutDescription,
                    style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Informations compte
          GlassContainer(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Text(
                  'Membre depuis le ${DateFormat('dd/MM/yyyy').format(utilisateur.dateCreation)}',
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  'ID: ${utilisateur.uid}',
                  style: TextStyle(
                    color: AppColors.text.withOpacity(0.7),
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

  /// Item de menu réutilisable - EXACTEMENT COMME GESTION ADMIN
  Widget _buildMenuItem(IconData icon, String title, [VoidCallback? onTap]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          _showFeatureDialog(title);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icône avec container glass
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 16),

              // Textes
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      onTap != null 
                          ? AppLocalizations.of(context).tapToOpen
                          : AppLocalizations.of(context).featureComingSoon,
                      style: TextStyle(fontSize: 13, color: AppColors.textWeak),
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textWeak,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog de confirmation de déconnexion - STYLE GLASSMORPHIQUE
  void _showLogoutDialog() {
    showGlassConfirmDialog(
      context: context,
      title: AppLocalizations.of(context).logout,
      message: AppLocalizations.of(context).logoutConfirmation,
      confirmText: AppLocalizations.of(context).logout,
      cancelText: AppLocalizations.of(context).cancel,
      icon: Icons.logout,
      iconColor: Colors.redAccent,
      onConfirm: () {
        Navigator.pop(context);
        _performLogout();
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  /// Dialog pour les fonctionnalités à implémenter - EXACTEMENT COMME ADMIN
  void _showFeatureDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                feature,
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).featureComingSoonDescription,
                style: TextStyle(color: AppColors.textWeak),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(
                    label: 'OK',
                    onPressed: () => Navigator.pop(context),
                    primary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            content: Text(AppLocalizations.of(context).logoutSuccess),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      print('ProfileScreen - Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).logoutError(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Section légale - NOUVELLE
  Widget _buildLegalSection() {
    return GlassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 8),
            child: Text(
              AppLocalizations.of(context).legal,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          GlassContainer(
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                _buildMenuItem(Icons.privacy_tip, AppLocalizations.of(context).privacyPolicy, () => _navigateToPrivacyPolicy()),
                Divider(
                  color: AppColors.glassStroke,
                  thickness: 1,
                  height: 1,
                ),
                _buildMenuItem(Icons.description, AppLocalizations.of(context).termsConditions, () => _navigateToTermsConditions()),
                Divider(
                  color: AppColors.glassStroke,
                  thickness: 1,
                  height: 1,
                ),
                _buildMenuItem(Icons.info_outline, AppLocalizations.of(context).legalMentions, () => _navigateToLegalMentions()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Navigation vers la politique de confidentialité
  void _navigateToPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  /// Navigation vers les conditions d'utilisation
  void _navigateToTermsConditions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
    );
  }

  /// Navigation vers les mentions légales
  void _navigateToLegalMentions() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LegalMentionsScreen()),
    );
  }
}
