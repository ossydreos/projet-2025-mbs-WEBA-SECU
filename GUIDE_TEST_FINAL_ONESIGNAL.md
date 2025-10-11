# 🧪 Guide de Test Final - OneSignal + Firebase

## ✅ Configuration Terminée

### 1. **Firebase Functions** ✅
- Function `onReservationCreate` déployée
- Configuration OneSignal sécurisée
- Trigger Firestore actif

### 2. **OneSignal** ✅
- App ID: `031e7630-e928-42fe-98a3-767668b2bedb`
- REST API Key configurée
- SDK Flutter intégré

### 3. **Firestore** ✅
- Règles de sécurité déployées
- Collections `users` et `reservations` configurées

## 🧪 Tests à Effectuer

### Test 1: Application de Test Simple
```bash
flutter run test_simple_onesignal.dart -d emulator-5554
```

**Actions dans l'app :**
1. L'app se lance et configure OneSignal automatiquement
2. Un utilisateur admin est créé dans Firestore
3. Appuyez sur "Créer réservation test"
4. Une réservation confirmée est créée
5. La Function Firebase se déclenche
6. Une notification OneSignal est envoyée

### Test 2: Vérification des Logs
```bash
firebase functions:log --only onReservationCreate
```

**Résultat attendu :**
```
OneSignal result: { "id": "...", "recipients": 1 }
```

### Test 3: Vérification OneSignal Dashboard
1. Allez sur [OneSignal Dashboard](https://app.onesignal.com)
2. **Audience > All Users** : Votre device devrait apparaître
3. **Messages > New Push** : Testez l'envoi manuel
4. **Analytics** : Vérifiez les notifications envoyées

## 🔧 Dépannage

### Problème: Pas de notification reçue
**Solutions :**
1. Vérifiez les permissions Android
2. Vérifiez que l'app est en foreground
3. Vérifiez les logs Firebase Functions
4. Vérifiez OneSignal Dashboard > Audience

### Problème: Function ne se déclenche pas
**Solutions :**
1. Vérifiez que la réservation a `status: "confirmed"`
2. Vérifiez les logs: `firebase functions:log`
3. Vérifiez que l'utilisateur a `role: "admin"`

### Problème: Erreur OneSignal API
**Solutions :**
1. Vérifiez la configuration: `firebase functions:config:get`
2. Vérifiez les clés OneSignal
3. Vérifiez les logs de la Function

## 📱 Intégration dans l'App Principale

### 1. **Pour les Admins**
Dans `admin_gestion_screen.dart` :
```dart
// Au début de initState()
await OneSignal.User.setExternalUserId(FirebaseAuth.instance.currentUser!.uid);
await OneSignal.User.addTagWithKey("role", "admin");
```

### 2. **Pour les Clients**
Dans `profile_screen_refined.dart` :
```dart
// Dans build()
await OneSignal.User.setExternalUserId(FirebaseAuth.instance.currentUser!.uid);
await OneSignal.User.addTagWithKey("role", "client");
```

### 3. **Envoi de Notifications**
La Function `onReservationCreate` s'occupe automatiquement d'envoyer les notifications aux admins quand une réservation confirmée est créée.

## 🎯 Résultat Final

- ✅ **Admins** : Reçoivent des notifications push OneSignal pour les nouvelles réservations
- ✅ **Clients** : Peuvent créer des réservations (pas de notifications)
- ✅ **Sécurité** : Configuration OneSignal sécurisée côté serveur
- ✅ **Scalabilité** : Prêt pour la production

## 🚀 Prochaines Étapes

1. **Tester** avec l'app de test simple
2. **Intégrer** dans l'app principale
3. **Tester** avec de vrais utilisateurs
4. **Déployer** en production

---

**Note :** Tous les fichiers de test peuvent être supprimés après validation.
