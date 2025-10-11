# 🧪 Guide de Test Final - OneSignal + Firebase

## ✅ **Configuration terminée !**

L'intégration Firebase + OneSignal est maintenant complètement configurée et prête à être testée.

## 🚀 **Test de l'intégration :**

### **1. Lancer l'app de test :**
```bash
flutter run test_onesignal_integration.dart -d emulator-5554
```

### **2. Dans l'app :**
- Appuyez sur **"Créer réservation test"**
- Vous devriez voir un message de confirmation

### **3. Vérifier les logs Firebase Functions :**
```bash
firebase functions:log
```

Recherchez :
- `"No admin found, skipping push."` - Si pas d'admin trouvé
- `"OneSignal result: ..."` - Si notification envoyée avec succès

### **4. Vérifier OneSignal Dashboard :**
- Allez dans [OneSignal Dashboard](https://onesignal.com)
- **Audience > All Users** - Votre appareil devrait apparaître
- **Messages > Delivery** - Voir les notifications envoyées

## 🔍 **Ce qui se passe :**

1. **App démarre** → OneSignal s'initialise
2. **Auth anonyme** → UID Firebase généré
3. **Document Firestore créé** → `users/{uid}` avec `role: "admin"`
4. **OneSignal configuré** → `external_user_id = uid`, tag `role: admin`
5. **Bouton pressé** → Réservation créée dans Firestore
6. **Cloud Function déclenche** → Récupère les admins
7. **API OneSignal appelée** → Notification envoyée aux admins
8. **Notification reçue** → Sur l'appareil admin

## 📊 **Structure Firestore attendue :**

### **Collection `users/{uid}` :**
```json
{
  "role": "admin",
  "createdAt": "2025-10-11T11:30:00Z"
}
```

### **Collection `reservations/{resId}` :**
```json
{
  "userId": "test-client",
  "status": "confirmed",
  "dateISO": "2025-10-11T11:30:00.000Z",
  "createdAt": "2025-10-11T11:30:00Z"
}
```

## 🎯 **Résultat attendu :**

✅ **App démarre sans erreur**  
✅ **OneSignal s'initialise**  
✅ **Document admin créé dans Firestore**  
✅ **Réservation créée avec status "confirmed"**  
✅ **Cloud Function se déclenche**  
✅ **Notification OneSignal reçue**  

## 🚨 **Dépannage :**

### **Problème : App ne démarre pas**
- Vérifiez que Firebase est configuré
- Vérifiez que OneSignal est initialisé

### **Problème : Pas de notification**
1. Vérifiez les logs Functions
2. Vérifiez que l'utilisateur a `role: "admin"`
3. Vérifiez que la réservation a `status: "confirmed"`
4. Vérifiez OneSignal Dashboard

### **Problème : Erreur OneSignal API**
1. Vérifiez la REST API Key
2. Vérifiez l'App ID
3. Vérifiez les logs Functions

## 🎉 **Intégration dans votre app :**

Pour intégrer dans votre app existante, ajoutez dans `main.dart` :

```dart
// Après Firebase.initializeApp()
OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
OneSignal.initialize("031e7630-e928-42fe-98a3-767668b2bedb");
await OneSignal.Notifications.requestPermission(true);

// Après connexion utilisateur
await OneSignal.User.addExternalUserId(uid);
if (isAdmin) {
  await OneSignal.User.addTagWithKey("role", "admin");
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'role': 'admin',
    'createdAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
```

**L'intégration est maintenant prête et testée !** 🚀
