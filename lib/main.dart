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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:my_mobility_services/screens/utilisateur/reservation/home_shell.dart';

import 'package:my_mobility_services/widgets/authgate.dart';
import 'package:my_mobility_services/widgets/admin/admin_screen_wrapper.dart';
import 'firebase/firebase_options.dart';
import 'theme/glassmorphism_theme.dart';
import 'design/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';
// Import des écrans pour les routes
// Import des écrans admin
import 'screens/admin/reception/admin_reception_screen_complete.dart';
import 'screens/admin/gestion/admin_gestion_screen.dart';
import 'screens/admin/gestion/vehicules/vehicle_gestion_screen.dart';
import 'screens/admin/trajets/admin_trajets_screen.dart';
import 'screens/admin/profile/admin_profile_screen.dart';
import 'screens/admin/gestion/code_promo/codePromo_cree_screen.dart';
import 'screens/admin/gestion/code_promo/codePromo_actif_screen.dart';
import 'screens/admin/gestion/users/admin_users_screen.dart';
import 'widgets/admin/test_notification_demo.dart';
import 'data/services/reservation_timeout_service.dart';
import 'data/services/admin_global_notification_service.dart';
import 'data/services/stripe_checkout_service.dart';
import 'package:app_links/app_links.dart';
import 'widgets/payment_success_animation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/maps_initialization_service.dart';

// Clé globale pour le navigator (pour afficher l'animation depuis n'importe où)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase de manière sécurisée
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialisé avec succès');
    
    // OneSignal init
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize("031e7630-e928-42fe-98a3-767668b2bedb");
    await OneSignal.Notifications.requestPermission(true); // iOS/Android 13+
    
    // Google Maps initialisé automatiquement via AndroidManifest.xml
    
    // Initialiser le service de notifications locales pour les admins
    await AdminGlobalNotificationService().initializeGlobal();
    
    // ❌ SUPPRIMÉ - Connexion automatique anonyme qui causait le bug de déconnexion
    // L'authentification sera gérée par AuthGate selon les besoins de l'utilisateur
    
    debugPrint('✅ OneSignal, Google Maps et notifications locales configurés - Authentification gérée par AuthGate');
    
    // Initialiser les données de fuseau horaire
    tz.initializeTimeZones();
    debugPrint('✅ Fuseaux horaires initialisés');
    
    // FCM désactivé - utilisation des notifications locales uniquement
    
    // ❌ DÉSACTIVÉ TEMPORAIREMENT - Test OneSignal uniquement
    // Initialiser le service de notifications admin global
    // (pour les notifications en arrière-plan)
    // try {
    //   AdminGlobalNotificationService().initializeGlobal();
    //   debugPrint('✅ Service notifications admin global initialisé');
    // } catch (e) {
    //   debugPrint('⚠️ Erreur service notifications admin: $e');
    // }
    debugPrint('🔔 Ancien système de notifications désactivé - Test OneSignal uniquement');
    
    // Initialiser la gestion des deep links
    try {
      final appLinks = AppLinks();
      appLinks.uriLinkStream.listen((uri) {
        _handleDeepLink(uri);
      });
      debugPrint('✅ Deep links initialisés');
    } catch (e) {
      debugPrint('⚠️ Erreur deep links: $e');
    }
    
    
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation Firebase: $e');
    debugPrint('🔄 Continuation sans Firebase pour tester...');
  }

  runApp(const MyApp());
}

// ✅ Gérer les deep links de paiement
void _handleDeepLink(Uri uri) {
  debugPrint('🔗 Deep link reçu: $uri');
  
  if (uri.scheme == 'my-mobility-services') {
    if (uri.host == 'payment-success') {
      // Paiement réussi
      final sessionId = uri.queryParameters['session_id'];
      final reservationId = uri.queryParameters['reservation_id'];
      debugPrint('✅ Paiement réussi! Session ID: $sessionId, reservation: $reservationId');

      if (sessionId != null && reservationId != null) {
        // Finaliser côté app: maj Firestore + passer en inProgress
        StripeCheckoutService.finalizePaymentFromDeepLink(
          sessionId: sessionId,
          reservationId: reservationId,
        );
        
        // Afficher l'animation de succès
        _showPaymentSuccessAnimation();
      }
    } else if (uri.host == 'payment-cancel') {
      // Paiement annulé
      debugPrint('❌ Paiement annulé');
      _showPaymentCancelMessage();
    }
  }
}

// ✅ Afficher l'animation de succès de paiement
void _showPaymentSuccessAnimation() {
  debugPrint('🎉 PAIEMENT CONFIRMÉ - La réservation est maintenant en cours !');
  
  // Attendre un peu pour que l'app soit complètement chargée
  Future.delayed(const Duration(milliseconds: 500), () {
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Afficher l'animation directement sans forcer la navigation
      showPaymentSuccessAnimation(
        context,
        message: 'Paiement confirmé !',
      );
    }
  });
}

// ✅ Afficher un message d'annulation de paiement
void _showPaymentCancelMessage() {
  debugPrint('❌ Paiement annulé par l\'utilisateur');
}


// Les services seront initialisés plus tard dans l'app pour éviter les crashes

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Ajouter la clé globale
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
        return GlassBackground(child: child!);
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
          case '/admin/users':
            page = AdminScreenWrapper(
              title: 'Utilisateurs',
              child: const AdminUsersScreen(),
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
