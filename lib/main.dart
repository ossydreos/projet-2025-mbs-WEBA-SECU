/*
 * My Mobility Services - Application Flutter
 * 
 * CRÉDITS IA : Ce projet utilise l'assistance de ChatGPT-5
 * pour optimiser la productivité et la qualité du code.
 * 
 * ADAPTATION HUMAINE : Tous les éléments générés ont été adaptés, 
 * testés et validés par l'équipe de développement.
 * 
 *  APPROCHE MODERNE : En tant que développeurs modernes, nous utilisons
 * tous les outils disponibles pour maximiser notre productivité. L'IA est
 * un amplificateur de notre expertise, pas un remplacement.
 * 
 */

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:my_mobility_services/screens/utilisateur/reservation/home_shell.dart';

import 'package:my_mobility_services/widgets/authgate.dart';
import 'firebase/firebase_options.dart';
import 'theme/glassmorphism_theme.dart';
// Import des écrans pour les routes
// Import des écrans admin
import 'screens/admin/reception/admin_reception_screen.dart';
import 'screens/admin/gestion/admin_gestion_screen.dart';
import 'screens/admin/gestion/vehicle_management_screen.dart';
import 'screens/admin/trajets/admin_trajets_screen.dart';
import 'screens/admin/profile/admin_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialiser les données de fuseau horaire pour toute l'application
  tz.initializeTimeZones();
  
  
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
          case '/admin/vehicle-management':
            page = const VehicleManagementScreen();
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
