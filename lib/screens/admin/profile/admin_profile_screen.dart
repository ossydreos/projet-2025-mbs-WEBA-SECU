import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/theme/glassmorphism_theme.dart'; // Import du nouveau thème
import 'package:my_mobility_services/widgets/admin/admin_navbar.dart';
import 'package:my_mobility_services/widgets/authgate.dart';

class AdminProfileScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final bool showBottomBar;

  const AdminProfileScreen({super.key, this.onNavigate, this.showBottomBar = true});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 3;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GlassBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Authgate();
        }

        return GlassBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: GlassAppBar(
              title: 'Compte',
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent),
                  ),
                  child: Text(
                    'ADMIN',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(child: _buildContent(user)),
                if (widget.showBottomBar)
                  AdminBottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _handleNavigation,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(User user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(user),
            const SizedBox(height: 20),
            _buildLogoutCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User user) {
    return SizedBox(
      // Correction ligne 111: Remplacer width par SizedBox
      width: double.infinity,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName ?? user.email?.split('@')[0] ?? 'Administrateur',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textStrong,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? 'admin@example.com',
              style: TextStyle(fontSize: 16, color: AppColors.text),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent),
              ),
              child: Text(
                'ADMINISTRATEUR',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Column(
      children: [
        // Bouton déconnexion - STYLE GLASSMORPHIQUE
        GlassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 0),
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
                            'Se déconnecter',
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
                  'Se déconnecter de votre compte administrateur.',
                  style: TextStyle(fontSize: 14, color: AppColors.textWeak),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Dialog de confirmation de déconnexion - STYLE GLASSMORPHIQUE
  void _showLogoutDialog() {
    showGlassConfirmDialog(
      context: context,
      title: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter de votre compte administrateur ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
      icon: Icons.logout,
      iconColor: Colors.redAccent,
      onConfirm: () {
        Navigator.pop(context);
        _performLogout();
      },
      onCancel: () => Navigator.pop(context),
    );
  }

  void _performLogout() async {
    try {
      await _auth.signOut();
      print('Déconnexion admin réussie');

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Authgate()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: AppColors.hot,
          ),
        );
      }
    }
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (widget.onNavigate != null) {
      widget.onNavigate!(index);
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/admin/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/admin/trajets');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/admin/gestion');
        break;
      case 3:
        break;
    }
  }
}
