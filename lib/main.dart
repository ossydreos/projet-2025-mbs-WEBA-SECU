import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_mobility_services/screens/welcome_login_screen.dart';
import 'package:my_mobility_services/widgets/authgate.dart';
import 'firebase_options.dart';
import './theme/theme_app.dart';
// Import des écrans pour les routes
import './screens/profile_screen.dart';
import './screens/localisation_recherche_screen.dart';
import './screens/trajets_screen.dart';
import './screens/acceuil_screen.dart';

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
      theme: AppTheme.dark(),
      home: const Authgate(),
      routes: {
        '/home': (context) => const AccueilScreen(),
        '/trajets': (context) => const TrajetsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
