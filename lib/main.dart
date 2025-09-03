import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart';
import 'package:my_mobility_services/widgets/authgate.dart';
import 'firebase_options.dart';
import 'ui/glass/glassmorphism_theme.dart';
// Import des écrans pour les routes
import './screens/profile_screen.dart';
import './screens/localisation_recherche_screen.dart';
import './screens/trajets_screen.dart';
import './screens/acceuil_screen.dart';
// Import des écrans admin
import './screens/admin_home_screen.dart';
import './screens/admin_gestion_screen.dart';
import './screens/admin_trajets_screen.dart';
import './screens/admin_profile_screen.dart';

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
        // Configuration des transitions fluides sans animations
        Widget page;
        switch (settings.name) {
          case '/home':
            page = const AccueilScreen();
            break;
          case '/trajets':
            page = const TrajetsScreen();
            break;
          case '/profile':
            page = const ProfileScreen();
            break;
          // Routes admin
          case '/admin/home':
            page = const AdminHomeScreen();
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
            page = const AccueilScreen();
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
