// lib/screens/utilisateur/profile/profile_screen_refined.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_mobility_services/widgets/utilisateur/widget_navBar.dart';
import 'package:my_mobility_services/widgets/authgate.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'favorite_trips_screen.dart';

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

  factory Utilisateur.fromFirestore(DocumentSnapshot doc, BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final phone = data['phone'] ?? '';
    
    return Utilisateur(
      uid: data['uid'] ?? '',
      nom: data['name'] ?? AppLocalizations.of(context).user,
      email: data['email'] ?? '',
      telephone: phone.isNotEmpty ? phone : AppLocalizations.of(context).notProvided,
      dateCreation: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      emailVerified: data['emailVerified'] ?? false,
      provider: data['provider'] ?? 'password',
    );
  }
}

/// Écran de profil - Version Liquid Glass iOS 26
class ProfileScreenRefined extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const ProfileScreenRefined({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<ProfileScreenRefined> createState() => _ProfileScreenRefinedState();
}

class _ProfileScreenRefinedState extends State<ProfileScreenRefined>
    with AutomaticKeepAliveClientMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      initialData: _auth.currentUser,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return GlassBackground(
            child: const Scaffold(
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
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return GlassBackground(
                child: const Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final utilisateur = userSnapshot.hasData 
                ? Utilisateur.fromFirestore(userSnapshot.data!, context)
                : _getDefaultUser(authSnapshot.data!);

            return _buildMainContent(utilisateur);
          },
        );
      },
    );
  }

  Widget _buildMainContent(Utilisateur utilisateur) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: GlassAppBar(
          title: AppLocalizations.of(context).profile,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header avec avatar
                GlassContainer(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.accent.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        utilisateur.nom,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textStrong,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        utilisateur.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.text.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Informations personnelles
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).personalInformation,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textStrong,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _showEditInfoDialog(utilisateur);
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
                          child: const Icon(
                            Icons.edit,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      child: Column(
                        children: [
                          _buildInfoRow(Icons.person, AppLocalizations.of(context).fullName, utilisateur.nom),
                          const Divider(color: AppColors.glassStroke),
                          _buildInfoRow(Icons.email, AppLocalizations.of(context).emailAddress, utilisateur.email),
                          const Divider(color: AppColors.glassStroke),
                          _buildInfoRow(
                            Icons.phone, 
                            AppLocalizations.of(context).phone, 
                            utilisateur.telephone == AppLocalizations.of(context).notProvided 
                                ? AppLocalizations.of(context).notProvidedShort 
                                : utilisateur.telephone
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Section trajets favoris
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).favoriteTrips,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      child: _buildMenuItem(Icons.favorite, AppLocalizations.of(context).myFavoriteTrips, () => _navigateToFavoriteTrips()),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Section légale
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).legal,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textStrong,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      child: Column(
                        children: [
                          _buildMenuItem(Icons.privacy_tip, AppLocalizations.of(context).privacyPolicy),
                          const Divider(color: AppColors.glassStroke),
                          _buildMenuItem(Icons.description, 'Conditions d\'utilisation'),
                          const Divider(color: AppColors.glassStroke),
                          _buildMenuItem(Icons.info_outline, 'Mentions légales'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Bouton de déconnexion
                GlassContainer(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _showLogoutDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context).disconnectButton,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.textWeak,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 100), // Espace pour la navbar
              ],
            ),
          ),
        ),
        bottomNavigationBar: widget.showBottomBar ? _buildBottomNavBar() : null,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: AppColors.textWeak),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, [VoidCallback? onTap]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {
          // TODO: Implémenter la navigation
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
              ),
              const Icon(
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

  Widget _buildBottomNavBar() {
    return CustomBottomNavigationBar(
      currentIndex: 3,
      onTap: _handleNavigation,
    );
  }

  Utilisateur _getDefaultUser(User user) {
    return Utilisateur(
      uid: user.uid,
      nom: user.displayName ?? user.email?.split('@')[0] ?? 'Utilisateur',
      email: user.email ?? 'email@example.com',
      telephone: user.phoneNumber ?? 'Not provided',
      dateCreation: user.metadata.creationTime ?? DateTime.now(),
      emailVerified: user.emailVerified,
      provider: 'password',
    );
  }

  void _handleNavigation(int index) {
    if (index == 3) return;
    widget.onNavigate?.call(index);
  }

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

  void _showEditInfoDialog(Utilisateur utilisateur) {
    final nameController = TextEditingController(text: utilisateur.nom);
    final emailController = TextEditingController(text: utilisateur.email);
    final phoneController = TextEditingController(text: utilisateur.telephone);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit,
                  color: AppColors.accent,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Modifier mes informations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textStrong,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Champ nom
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).fullName,
                    labelStyle: const TextStyle(color: AppColors.textWeak),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassStroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    filled: true,
                    fillColor: AppColors.glass.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: AppColors.textStrong),
                ),
                const SizedBox(height: 16),
                
                // Champ email
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).email,
                    labelStyle: const TextStyle(color: AppColors.textWeak),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassStroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    filled: true,
                    fillColor: AppColors.glass.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: AppColors.textStrong),
                ),
                const SizedBox(height: 16),
                
                // Champ téléphone
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).phone,
                    labelStyle: const TextStyle(color: AppColors.textWeak),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassStroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.accent),
                    ),
                    filled: true,
                    fillColor: AppColors.glass.withOpacity(0.1),
                  ),
                  style: const TextStyle(color: AppColors.textStrong),
                ),
                const SizedBox(height: 24),
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Annuler',
                        onPressed: () => Navigator.pop(context),
                        primary: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        label: 'Sauvegarder',
                        onPressed: () {
                          _saveUserInfo(
                            nameController.text,
                            emailController.text,
                            phoneController.text,
                          );
                          Navigator.pop(context);
                        },
                        primary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveUserInfo(String name, String email, String phone) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Récupérer les données actuelles pour l'historique
        final currentDoc = await _firestore.collection('users').doc(user.uid).get();
        final currentData = currentDoc.data();
        
        if (currentData != null) {
          // Créer un log de l'ancienne version
          final historyEntry = {
            'name': currentData['name'] ?? '',
            'email': currentData['email'] ?? '',
            'phone': currentData['phone'] ?? '',
            'updatedAt': currentData['updatedAt'] ?? FieldValue.serverTimestamp(),
            'changedAt': FieldValue.serverTimestamp(),
            'changedBy': 'user', // ou 'admin' si modifié par un admin
          };
          
          // Ajouter l'historique dans une sous-collection
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('profile_history')
              .add(historyEntry);
        }
        
        // Mettre à jour les données actuelles
        await _firestore.collection('users').doc(user.uid).update({
          'name': name,
          'email': email,
          'phone': phone,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).profileUpdatedSuccess),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).logout,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textStrong,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).logoutConfirmation,
                style: const TextStyle(color: AppColors.textWeak),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GlassButton(
                    label: AppLocalizations.of(context).cancel,
                    onPressed: () => Navigator.pop(context),
                    primary: false,
                  ),
                  const SizedBox(width: 12),
                  GlassButton(
                    label: AppLocalizations.of(context).logout,
                    onPressed: () {
                      Navigator.pop(context);
                      _performLogout();
                    },
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

  Future<void> _performLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
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
}