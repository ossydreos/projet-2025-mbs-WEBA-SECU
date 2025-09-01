import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_mobility_services/widgets/authgate.dart';
import 'firebase_options.dart';
import './theme/theme_app.dart';
// Import des écrans pour les routes
import './screens/reservation_screen.dart';
import './screens/profile_screen.dart';
import './screens/localisation_recherche_screen.dart';

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
      title: 'Login v0.1',
      theme: AppTheme.dark(),
      home: Authgate(),
      // 🎯 ROUTES POUR NAVIGATION
      routes: {
        '/home': (context) => const VehicleReservationScreen(),
        '/profile': (context) => const EcranProfile(),
        '/search': (context) => LocationSearchScreen(),
        '/trips': (context) => const TripsScreen(),
      },
    );
  }
}

// Écran temporaire pour les trajets
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Trajets'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Mes Trajets',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Aucun trajet pour le moment',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
