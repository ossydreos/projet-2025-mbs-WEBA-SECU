# Index Firestore - My Mobility Services

## 🚨 INDEX REQUIS - À CRÉER IMMÉDIATEMENT

L'erreur que vous voyez indique qu'il manque un index Firestore. Voici comment le créer :

### 1. **Index pour les réservations utilisateur** (PRIORITÉ 1)

**Collection:** `reservations`
**Champs:**
- `userId` (Ascending)
- `createdAt` (Descending)

**URL directe pour créer l'index:**
```
https://console.firebase.google.com/v1/r/project/my-mobility-services/firestore/indexes?create_composite=ClIwcm9qZWN0cy9teS1tb2JpbGl0eS1zZXJ2aWNlcy9kYXRhYmFzZXMvKGRmYXVsdCkvY29sbGVjdGlvbkdyb3Vwcy9yZXNlcnZhdGlvbnMvaW5kZXhlcy9fXxABGgoKBnVzZXJJZBABGg0KCWNyZWF0ZWRBdBACGgwKCF9fbmFtZV9fEAI
```

### 2. **Index pour les réservations en attente** (PRIORITÉ 2)

**Collection:** `reservations`
**Champs:**
- `status` (Ascending)
- `createdAt` (Ascending)

### 3. **Comment créer l'index manuellement :**

1. **Aller sur Firebase Console:**
   - https://console.firebase.google.com/
   - Sélectionner le projet "my-mobility-services"

2. **Naviguer vers Firestore:**
   - Cliquer sur "Firestore Database"
   - Cliquer sur l'onglet "Indexes"

3. **Créer l'index:**
   - Cliquer sur "Create Index"
   - Collection ID: `reservations`
   - Ajouter les champs:
     - `userId` (Ascending)
     - `createdAt` (Descending)
   - Cliquer sur "Create"

### 4. **Temps d'attente:**
- L'index peut prendre quelques minutes à être créé
- Une fois créé, l'erreur disparaîtra automatiquement

## 🔧 Solution temporaire (en attendant l'index)

Si vous voulez tester l'app en attendant que l'index soit créé, je peux modifier le code pour utiliser une requête plus simple qui ne nécessite pas d'index.
