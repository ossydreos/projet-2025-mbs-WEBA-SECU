import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_mobility_services/screens/acceuil_screen.dart';
import 'package:my_mobility_services/screens/splash_screen.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart';
import 'package:my_mobility_services/screens/admin_home_screen.dart';
import 'package:my_mobility_services/services/user_service.dart';
import 'package:my_mobility_services/models/user_model.dart';
import 'package:my_mobility_services/screens/home_shell.dart';

class Authgate extends StatelessWidget {
  const Authgate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
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
                return SplashScreen();
              }
              
              final userModel = userSnapshot.data;
              print('AuthGate - UserModel: ${userModel?.role.name ?? "null"}');
              
              if (userModel?.isAdmin == true) {
                print('AuthGate - Redirection vers AdminHomeScreen');
                return const AdminHomeScreen();
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
