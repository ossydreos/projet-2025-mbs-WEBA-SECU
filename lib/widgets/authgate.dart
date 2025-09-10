import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/screens/splash_screen.dart';
import 'package:my_mobility_services/screens/log_screen/welcome_login_screen.dart';
import 'package:my_mobility_services/screens/admin/reception/admin_reception_screen.dart';
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
  final SessionService _sessionService = SessionService();
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkSessionValidity();
  }

  Future<void> _checkSessionValidity() async {
    try {
      final isValid = await _sessionService.isSessionValid();
      if (!isValid && mounted) {
        // Session invalide, déconnecter l'utilisateur
        await _sessionService.signOut();
      }
    } catch (e) {
      print('Erreur lors de la vérification de session: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingSession = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const SplashScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final user = snapshot.data;

        // Debug pour voir l'état de l'authentification
        print('AuthGate - User: ${user?.uid ?? "null"}');
        print('AuthGate - Connection state: ${snapshot.connectionState}');

        if (user == null) {
          print('AuthGate - Redirection vers WelcomeLoginSignup');
          return const WelcomeLoginSignup();
        } else {
          // Vérifier si l'utilisateur est admin
          return StreamBuilder<UserModel?>(
            stream: UserService().getCurrentUserStream(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              final userModel = userSnapshot.data;
              print('AuthGate - UserModel: ${userModel?.role.name ?? "null"}');

              if (userModel?.isAdmin == true) {
                print('AuthGate - Redirection vers AdminReceptionScreen');
                return const AdminReceptionScreen();
              } else {
                print('AuthGate - Redirection vers HomeShell');
                
                return const HomeShell();
              }
            },
          );
        }
      },
    );
  }
}
