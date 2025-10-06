import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/screens/splash_screen.dart';
import 'package:my_mobility_services/screens/log_screen/welcome_login_screen.dart';
import 'package:my_mobility_services/screens/admin/reception/admin_reception_screen_complete.dart';
import 'package:my_mobility_services/widgets/admin/admin_screen_wrapper.dart';
import 'package:my_mobility_services/data/services/user_service.dart';
import 'package:my_mobility_services/data/services/session_service.dart';
import 'package:my_mobility_services/data/models/user_model.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/home_shell.dart';

class Authgate extends StatefulWidget {
  const Authgate({super.key});

  @override
  State<Authgate> createState() => _AuthgateState();
}

class _AuthgateState extends State<Authgate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Version ultra-simplifiée pour éviter les crashes
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Attendre un peu pour simuler l'initialisation
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('✅ Initialisation simplifiée terminée');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitialized = true);
        debugPrint('✅ AuthGate prêt');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    // Router l'app selon l'état d'auth Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final user = snapshot.data;
        if (user == null) {
          debugPrint('AuthGate -> utilisateur déconnecté → Welcome');
          return const WelcomeLoginSignup();
        }

        // Charger la fiche utilisateur pour router selon le rôle
        return FutureBuilder<UserModel?>(
          future: UserService().getUserById(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }
            final userModel = roleSnap.data;
            if (userModel?.isAdmin == true) {
              debugPrint('AuthGate -> admin connecté (${user.uid}) → AdminHome');
              return AdminScreenWrapper(
                title: 'Réception',
                child: const AdminReceptionScreen(),
              );
            }
            debugPrint('AuthGate -> utilisateur connecté (${user.uid}) → Home');
            return const HomeShell();
          },
        );
      },
    );
  }
}
