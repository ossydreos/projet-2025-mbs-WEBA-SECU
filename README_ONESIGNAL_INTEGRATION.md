# 🔔 Intégration Firebase + OneSignal - Guide Complet

## ✅ Configuration terminée

L'intégration Firebase + OneSignal a été configurée avec succès selon les spécifications :

### 📁 **Structure créée :**

1. **Firebase Functions** (`firebase-functions/`)
   - `src/index.ts` - Cloud Function trigger
   - `package.json` - Dépendances Node 20
   - `tsconfig.json` - Configuration TypeScript

2. **Firestore Rules** (`firestore.rules`)
   - Règles de sécurité pour users et reservations

3. **Code Flutter** (`lib/main_onesignal.dart`)
   - Intégration OneSignal complète
   - Test de création de réservation

## 🚀 **Comment ça fonctionne :**

### **1. Côté App Flutter :**
- **OneSignal s'initialise** avec l'App ID
- **Utilisateur se connecte** → `OneSignal.User.login(uid)`
- **Document Firestore créé** avec `role: "admin"` ou `role: "user"`
- **Tag OneSignal ajouté** selon le rôle

### **2. Côté Cloud Function :**
- **Trigger Firestore** sur création de `reservations/{resId}`
- **Si status = "confirmed"** → récupère tous les admins
- **Appel API OneSignal** avec `include_external_user_ids`
- **Notification envoyée** aux admins uniquement

## 🧪 **Test end-to-end :**

### **1. Lancer l'app de test :**
```bash
# Utiliser le fichier de test
flutter run lib/main_onesignal.dart
```

### **2. Vérifier OneSignal Dashboard :**
- Allez dans OneSignal > Audience > All Users
- Votre appareil devrait apparaître avec l'UID Firebase

### **3. Tester la notification :**
- Appuyez sur "Créer réservation test" dans l'app
- Vérifiez les logs Firebase Functions
- Vous devriez recevoir une notification OneSignal

### **4. Vérifier Firestore :**
- Collection `users/{uid}` avec `role: "admin"`
- Collection `reservations/{resId}` avec `status: "confirmed"`

## 📊 **Logs à surveiller :**

### **Firebase Functions Logs :**
```bash
firebase functions:log
```

Recherchez :
- `"No admin found, skipping push."` - Pas d'admin trouvé
- `"OneSignal result: ..."` - Notification envoyée avec succès

### **OneSignal Dashboard :**
- Messages > Delivery > Voir les notifications envoyées
- Audience > Users > Vérifier les tags et external_user_id

## 🔧 **Configuration OneSignal :**

### **Variables configurées :**
- `onesignal.app_id` = `031e7630-e928-42fe-98a3-767668b2bedb`
- `onesignal.rest_key` = `os_v2_app_amphmmhjfbbp5gfdoz3grmv63nfzq6b7z3wuuh4jpw3ew7mam5gkye7y6lip3ck6mz52l6wxtwuesk3cspzmgrt26rw7eizavrvif4q`

### **Vérifier la config :**
```bash
firebase functions:config:get
```

## 🎯 **Intégration dans votre app existante :**

### **1. Remplacer main.dart :**
```dart
// Dans votre main.dart existant, ajoutez :

// Après Firebase.initializeApp()
await initOneSignal("031e7630-e928-42fe-98a3-767668b2bedb", uid, isAdmin: true);

// Après connexion utilisateur
await ensureUserDoc(uid, isAdmin: isAdminUser);
```

### **2. Pour les admins :**
```dart
// Quand un admin se connecte
await OneSignal.User.login(adminUid);
await OneSignal.User.addTagWithKey("role", "admin");
await ensureUserDoc(adminUid, isAdmin: true);
```

### **3. Pour les clients :**
```dart
// Quand un client se connecte
await OneSignal.User.login(clientUid);
await ensureUserDoc(clientUid, isAdmin: false);
```

## 🚨 **Dépannage :**

### **Problème : Pas de notification reçue**
1. Vérifiez que l'utilisateur a `role: "admin"` dans Firestore
2. Vérifiez que la réservation a `status: "confirmed"`
3. Vérifiez les logs Functions
4. Vérifiez OneSignal Dashboard

### **Problème : Erreur OneSignal API**
1. Vérifiez que la REST API Key est correcte
2. Vérifiez que l'App ID est correct
3. Vérifiez les logs Functions pour l'erreur exacte

### **Problème : Function ne se déclenche pas**
1. Vérifiez que la Function est déployée
2. Vérifiez que le document est créé dans Firestore
3. Vérifiez les permissions Firestore

## 📱 **Commandes utiles :**

```bash
# Déployer les Functions
firebase deploy --only functions

# Déployer les règles Firestore
firebase deploy --only firestore:rules

# Voir les logs Functions
firebase functions:log

# Tester localement
firebase emulators:start --only functions,firestore
```

## 🎉 **Résultat attendu :**

Quand une réservation avec `status: "confirmed"` est créée :
1. ✅ Cloud Function se déclenche
2. ✅ Récupère tous les admins de Firestore
3. ✅ Appelle l'API OneSignal
4. ✅ Notification push reçue par les admins
5. ✅ Interface locale affichée (si configurée)

**L'intégration est maintenant prête !** 🚀
