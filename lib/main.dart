import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_mobility_services/screens/utilisateur/reservation/home_shell.dart';

import 'package:my_mobility_services/widgets/authgate.dart';
import 'firebase/firebase_options.dart';
import 'theme/glassmorphism_theme.dart';
// Import des écrans pour les routes
import 'screens/utilisateur/profile/profile_screen.dart';
import 'screens/utilisateur/reservation/localisation_recherche_screen.dart';
import 'screens/utilisateur/trajets/trajets_screen.dart';
import 'screens/utilisateur/reservation/acceuil_res_screen.dart';
import 'screens/utilisateur/offres/offres_personnalisees_screen.dart';
// Import des écrans admin
import 'screens/admin/reception/admin_reception_screen.dart';
import 'screens/admin/gestion/admin_gestion_screen.dart';
import 'screens/admin/trajets/admin_trajets_screen.dart';
import 'screens/admin/profile/admin_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Mobility Services',
      theme: AppTheme.glassDark,
      home: const Authgate(),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/home':
            page = const HomeShell(initialIndex: 0);
            break;
          case '/offres':
            page = const HomeShell(initialIndex: 1);
            break;
          case '/trajets':
            page = const HomeShell(initialIndex: 2);
            break;
          case '/profile':
            page = const HomeShell(initialIndex: 3);
            break;
          // Routes admin
          case '/admin/home':
            page = const AdminReceptionScreen();
            break;
          case '/admin/trajets':
            page = const AdminTrajetsScreen();
            break;
          case '/admin/gestion':
            page = const AdminGestionScreen();
            break;
          case '/admin/profile':
            page = const AdminProfileScreen();
            break;
          default:
            page = const HomeShell();
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              child,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        );
      },
    );
  }
}
