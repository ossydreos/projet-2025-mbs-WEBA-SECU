# 📋 RÉSUMÉ COMPLET - Intégration OneSignal + Firebase

## 🎯 Objectif
Intégrer OneSignal pour envoyer des notifications push aux administrateurs quand une nouvelle réservation est créée, en utilisant Firebase Functions comme backend.

## 📁 FICHIERS CRÉÉS

### 1. **firebase-functions/package.json**
```json
{
  "engines": { "node": "20" },
  "main": "lib/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "deploy": "npm run build && firebase deploy --only functions",
    "serve": "npm run build && firebase emulators:start --only functions,firestore"
  },
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^5.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

### 2. **firebase-functions/tsconfig.json**
```json
{
  "compilerOptions": {
    "lib": ["ES2022"],
    "target": "ES2022",
    "module": "ES2022",
    "moduleResolution": "Node",
    "outDir": "lib",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src"]
}
```

### 3. **firebase-functions/src/index.ts**
```typescript
import * as functions from "firebase-functions";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

initializeApp();

// Types Firestore
type Reservation = {
  userId?: string;
  status?: "pending" | "confirmed" | "canceled";
  dateISO?: string; // ISO8601
};

// Récupération config OneSignal (sécurisée)
const APP_ID = functions.config().onesignal.app_id as string;
const REST_KEY = functions.config().onesignal.rest_key as string;

async function sendToOneSignal(params: {
  externalUserIds: string[];         // liste des uid (== external_user_id)
  title: string;
  body: string;
  data?: Record<string, string>;
  // Optionnel: programmer l'envoi plus tard (format "Fri, 24 Oct 2025 16:30:00 GMT")
  sendAfterGMT?: string;
}) {
  const payload: any = {
    app_id: APP_ID,
    include_external_user_ids: params.externalUserIds,
    headings: { fr: params.title, en: params.title },
    contents: { fr: params.body,  en: params.body },
    data: params.data ?? {},
  };
  if (params.sendAfterGMT) {
    payload.send_after = params.sendAfterGMT; // doit être GMT
  }

  const res = await fetch("https://api.onesignal.com/notifications", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${REST_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`OneSignal error ${res.status}: ${text}`);
  }
  return res.json();
}

// 🔔 Trigger: à la création d'une réservation confirmée → push aux admins
export const onReservationCreate = functions.firestore
  .document("reservations/{resId}")
  .onCreate(async (snap, ctx) => {
    const res = snap.data() as Reservation;
    if (!res || res.status !== "confirmed") return;

    // 1) Récupérer tous les admins
    const adminsSnap = await getFirestore()
      .collection("users")
      .where("role", "==", "admin")
      .get();

    const adminIds = adminsSnap.docs.map(d => d.id).filter(Boolean);

    if (adminIds.length === 0) {
      console.log("No admin found, skipping push.");
      return;
    }

    // 2) Construire le contenu de la notif
    let body = "Nouvelle réservation confirmée";
    if (res.dateISO) {
      try {
        const when = new Date(res.dateISO);
        body = new Intl.DateTimeFormat("fr-FR", {
          dateStyle: "medium",
          timeStyle: "short",
        }).format(when);
      } catch {
        // garde body par défaut
      }
    }

    // 3) Envoyer via OneSignal
    const route = `/reservations/${ctx.params.resId}`;
    const result = await sendToOneSignal({
      externalUserIds: adminIds,
      title: "Nouvelle réservation ✅",
      body,
      data: { route },
    });

    console.log("OneSignal result:", result);
  });
```

### 4. **firestore.rules**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    match /reservations/{resId} {
      // Adapte selon tes besoins; ici on autorise les utilisateurs connectés à créer
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if false;
    }
  }
}
```

### 5. **firestore.indexes.json**
```json
{
  "indexes": [],
  "fieldOverrides": []
}
```

### 6. **test_onesignal_integration.dart**
```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialiser OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("031e7630-e928-42fe-98a3-767668b2bedb");
  await OneSignal.Notifications.requestPermission(true);

  // Auth anonyme pour test
  final auth = FirebaseAuth.instance;
  UserCredential cred = await auth.signInAnonymously();
  final uid = cred.user!.uid;

  // Tagger comme admin
  await OneSignal.User.setExternalUserId(uid);
  await OneSignal.User.addTagWithKey("role", "admin");

  // Créer document utilisateur admin
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'role': 'admin',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // Créer une réservation confirmée pour déclencher la Cloud Function
  await FirebaseFirestore.instance.collection('reservations').add({
    "userId": uid,
    "status": "confirmed",
    "dateISO": DateTime.now().toIso8601String(),
    "createdAt": FieldValue.serverTimestamp(),
  });

  print('✅ Réservation test créée !');
}
```

### 7. **test_simple_onesignal.dart**
```dart
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Initialiser OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("031e7630-e928-42fe-98a3-767668b2bedb");
  await OneSignal.Notifications.requestPermission(true);
  
  // Auth anonyme pour test
  final auth = FirebaseAuth.instance;
  UserCredential cred = await auth.signInAnonymously();
  final uid = cred.user!.uid;
  
  print('🔔 UID généré: $uid');
  
  // Tagger comme admin
  await OneSignal.User.setExternalUserId(uid);
  await OneSignal.User.addTagWithKey("role", "admin");
  
  print('✅ OneSignal configuré avec external_user_id: $uid');
  
  // Créer document utilisateur admin
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'role': 'admin',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  
  print('✅ Document admin créé dans Firestore');
  
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OneSignal Test Simple',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test OneSignal'),
          backgroundColor: Colors.blue,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications, size: 64, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                'OneSignal + Firebase configuré !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Appuyez sur le bouton pour créer une réservation et déclencher la notification OneSignal.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Créer une réservation confirmée pour déclencher la notification
                    final doc = await FirebaseFirestore.instance.collection('reservations').add({
                      'userId': 'test-client-${DateTime.now().millisecondsSinceEpoch}',
                      'status': 'confirmed',
                      'dateISO': DateTime.now().toIso8601String(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Réservation créée: ${doc.id}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    
                    print('🔔 Réservation créée: ${doc.id}');
                    print('🔔 Vérifiez les logs: firebase functions:log');
                    print('🔔 Vous devriez recevoir une notification OneSignal !');
                    
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('❌ Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    print('❌ Erreur: $e');
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer réservation test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Instructions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('1. Appuyez sur le bouton ci-dessus'),
                      Text('2. Vérifiez les logs: firebase functions:log'),
                      Text('3. Vous devriez recevoir une notification OneSignal'),
                      Text('4. Vérifiez OneSignal Dashboard > Audience'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 8. **test_manual_firestore.js**
```javascript
// Script de test manuel pour Firestore
// Exécuter avec: node test_manual_firestore.js

const admin = require('firebase-admin');

// Initialiser Firebase Admin
const serviceAccount = require('./firebase-functions/serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function testIntegration() {
  try {
    console.log('🧪 Test d\'intégration OneSignal + Firebase...');
    
    // 1. Créer un utilisateur admin
    const adminUid = 'test-admin-' + Date.now();
    await db.collection('users').doc(adminUid).set({
      role: 'admin',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Utilisateur admin créé:', adminUid);
    
    // 2. Créer une réservation confirmée (déclenche la Function)
    const reservationRef = await db.collection('reservations').add({
      userId: 'test-client',
      status: 'confirmed',
      dateISO: new Date().toISOString(),
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log('✅ Réservation créée:', reservationRef.id);
    console.log('🔔 La Function onReservationCreate devrait se déclencher...');
    console.log('🔔 Vérifiez les logs: firebase functions:log');
    
    // Attendre un peu pour voir les logs
    console.log('⏳ Attente de 5 secondes...');
    await new Promise(resolve => setTimeout(resolve, 5000));
    
    console.log('✅ Test terminé !');
    console.log('📱 Vérifiez que vous avez reçu une notification OneSignal');
    
  } catch (error) {
    console.error('❌ Erreur:', error);
  }
}

testIntegration();
```

## 📝 FICHIERS MODIFIÉS

### 1. **pubspec.yaml**
```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... autres dépendances existantes ...
  onesignal_flutter: ^5.1.2  # AJOUTÉ
```

### 2. **android/app/src/main/AndroidManifest.xml**
```xml
<application>
    <!-- OneSignal App ID -->
    <meta-data
        android:name="onesignal_app_id"
        android:value="031e7630-e928-42fe-98a3-767668b2bedb" />
    
    <!-- OneSignal Notification Service -->
    <service
        android:name="com.onesignal.NotificationExtenderService"
        android:exported="false">
        <intent-filter>
            <action android:name="com.onesignal.NotificationExtenderService" />
        </intent-filter>
    </service>
    
    <!-- ... reste de la configuration existante ... -->
</application>
```

### 3. **lib/main.dart** (modifications partielles)
```dart
import 'package:onesignal_flutter/onesignal_flutter.dart';
// ... autres imports ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable verbose logging for debugging (remove in production)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  // Initialize with your OneSignal App ID
  OneSignal.initialize("031e7630-e928-42fe-98a3-767668b2bedb");
  // Use this method to prompt for push notifications.
  // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
  OneSignal.Notifications.requestPermission(false);
  
  // Pas de tag global - on taggera seulement les admins
  
  try {
    // Initialiser Firebase de manière sécurisée
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('✅ Firebase initialisé avec succès');
    // ... rest of main function ...
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation Firebase: $e');
    debugPrint('🔄 Continuation sans Firebase pour tester...');
  }

  runApp(const MyApp());
}
```

## 🔧 COMMANDES EXÉCUTÉES

### 1. **Configuration Firebase Functions**
```bash
cd firebase-functions
npm install firebase-admin firebase-functions
npm install -D typescript
```

### 2. **Configuration OneSignal**
```bash
firebase functions:config:set onesignal.app_id="031e7630-e928-42fe-98a3-767668b2bedb"
firebase functions:config:set onesignal.rest_key="os_v2_app_amphmmhjfbbp5gfdoz3grmv63nfzq6b7z3wuuh4jpw3ew7mam5gkye7y6lip3ck6mz52l6wxtwuesk3cspzmgrt26rw7eizavrvif4q"
```

### 3. **Déploiement**
```bash
firebase deploy --only firestore:rules
firebase deploy --only functions
```

### 4. **Tests**
```bash
flutter run test_simple_onesignal.dart -d emulator-5554
firebase functions:log --only onReservationCreate
```

## ❌ ERREURS RENCONTRÉES

### 1. **Erreur OneSignal API**
```
Error: The method 'setExternalUserId' isn't defined for the type 'OneSignalUser'
```

**Cause :** La méthode `setExternalUserId` n'existe pas dans la version 5.3.4 du SDK OneSignal Flutter.

**Tentatives de correction :**
- `OneSignal.User.setExternalUserId(uid)` ❌
- `OneSignal.User.addExternalUserId(uid)` ❌
- `OneSignal.User.login(uid)` ❌

### 2. **Erreur Firebase Options**
```
Error when reading 'firebase/firebase_options.dart': Le chemin d'accès spécifié est introuvable
```

**Correction :** Changé vers `lib/firebase/firebase_options.dart`

## 🎯 CONFIGURATION ONESIGNAL

- **App ID :** `031e7630-e928-42fe-98a3-767668b2bedb`
- **REST API Key :** `os_v2_app_amphmmhjfbbp5gfdoz3grmv63nfzq6b7z3wuuh4jpw3ew7mam5gkye7y6lip3ck6mz52l6wxtwuesk3cspzmgrt26rw7eizavrvif4q`
- **SDK Version :** `onesignal_flutter: ^5.1.2` (mais installé 5.3.4)

## 📱 STRUCTURE FIRESTORE ATTENDUE

### Collection `users/{uid}`
```json
{
  "role": "admin" | "user",
  "createdAt": "timestamp"
}
```

### Collection `reservations/{resId}`
```json
{
  "userId": "uid_du_client",
  "status": "confirmed" | "pending" | "canceled",
  "dateISO": "2025-10-24T18:30:00.000Z",
  "createdAt": "timestamp"
}
```

## 🚨 PROBLÈME PRINCIPAL

**La méthode pour définir l'external_user_id dans OneSignal Flutter SDK 5.3.4 n'est pas claire.**

**Documentation consultée :** https://documentation.onesignal.com/docs/en/flutter-sdk-setup

**Méthodes testées sans succès :**
- `OneSignal.User.setExternalUserId()`
- `OneSignal.User.addExternalUserId()`
- `OneSignal.User.login()`
- `OneSignal.User.addTagWithKey()`

## 🎯 OBJECTIF FINAL

Envoyer des notifications push OneSignal aux administrateurs quand une nouvelle réservation avec `status: "confirmed"` est créée dans Firestore, en utilisant Firebase Functions comme backend sécurisé.

---

**Note :** Tous les fichiers de test peuvent être supprimés après résolution du problème principal.
