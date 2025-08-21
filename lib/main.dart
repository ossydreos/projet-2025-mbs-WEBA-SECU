import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

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
      title: 'Firestore Test',
      home: Scaffold(
        appBar: AppBar(title: const Text("Test Firestore")),
        body: const FirestoreTestWidget(),
      ),
    );
  }
}

class FirestoreTestWidget extends StatefulWidget {
  const FirestoreTestWidget({super.key});

  @override
  State<FirestoreTestWidget> createState() => _FirestoreTestWidgetState();
}

class _FirestoreTestWidgetState extends State<FirestoreTestWidget> {
  String _message = "⏳ Envoi en cours...";

  @override
  void initState() {
    super.initState();
    _testFirestore();
  }

  Future<void> _testFirestore() async {
    try {
      // 🔥 Écrire un document
      await FirebaseFirestore.instance.collection("tests").doc("hello").set({
        "message": "Hello depuis Flutter 🚀",
      });

      // 🔥 Lire le document
      final snapshot = await FirebaseFirestore.instance
          .collection("tests")
          .doc("hello")
          .get();

      setState(() {
        _message = "✅ Firestore OK : ${snapshot["message"]}";
      });
    } catch (e) {
      setState(() {
        _message = "❌ Erreur Firestore : $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(_message));
  }
}
