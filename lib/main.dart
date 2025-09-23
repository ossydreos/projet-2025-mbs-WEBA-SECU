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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:my_mobility_services/screens/utilisateur/reservation/home_shell.dart';

import 'package:my_mobility_services/widgets/authgate.dart';
import 'package:my_mobility_services/widgets/admin/admin_screen_wrapper.dart';
import 'firebase/firebase_options.dart';
import 'theme/glassmorphism_theme.dart';
import 'l10n/generated/app_localizations.dart';
// Import des écrans pour les routes
// Import des écrans admin
import 'screens/admin/reception/admin_reception_screen.dart';
import 'screens/admin/gestion/admin_gestion_screen.dart';
import 'screens/admin/gestion/vehicules/vehicle_gestion_screen.dart';
import 'screens/admin/trajets/admin_trajets_screen.dart';
import 'screens/admin/profile/admin_profile_screen.dart';
import 'screens/admin/gestion/code_promo/codePromo_cree_screen.dart';
import 'screens/admin/gestion/code_promo/codePromo_actif_screen.dart';
import 'widgets/admin/test_notification_demo.dart';
import 'data/services/reservation_timeout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialiser les données de fuseau horaire pour toute l'application
  tz.initializeTimeZones();

  // Démarrer le service de timeout des réservations
  final timeoutService = ReservationTimeoutService();
  timeoutService.startTimeoutService();

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

      // Configuration de l'internationalisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', ''), // Français (par défaut)
        Locale('en', ''), // Anglais
      ],

      // La langue sera automatiquement détectée selon l'appareil
      // Si langue non supportée → fallback vers l'anglais
      home: const Authgate(),
      builder: (context, child) {
        return child!;
      },
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
            page = AdminScreenWrapper(
              title: 'Réception',
              child: const AdminReceptionScreen(),
            );
            break;
          case '/admin/trajets':
            page = AdminScreenWrapper(
              title: 'Trajets',
              child: const AdminTrajetsScreen(),
            );
            break;
          case '/admin/gestion':
            page = AdminScreenWrapper(
              title: 'Gestion',
              child: const AdminGestionScreen(),
            );
            break;
          case '/admin/vehicle-management':
            page = AdminScreenWrapper(
              title: 'Gestion Véhicules',
              child: VehicleManagementScreen(),
            );
            break;
          case '/admin/profile':
            page = AdminScreenWrapper(
              title: 'Profil',
              child: const AdminProfileScreen(),
            );
            break;
          case '/admin/promo/create':
            page = AdminScreenWrapper(
              title: 'Créer Code Promo',
              child: const CreatePromoCodeScreen(),
            );
            break;
          case '/admin/promo/active':
            page = AdminScreenWrapper(
              title: 'Codes Promo Actifs',
              child: ActivePromoCodesScreen(),
            );
            break;
          case '/admin/demo/notification':
            page = AdminScreenWrapper(
              title: 'Test Notifications',
              child: const TestNotificationDemo(),
            );
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
