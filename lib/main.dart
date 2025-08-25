import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import './screens/welcome_login_screen.dart';
import 'firebase_options.dart';
import './theme/theme_app.dart';
import 'screens/reservation_screen.dart';

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
      home: WelcomeLoginSignup(),
    );
  }
}
