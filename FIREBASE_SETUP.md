# Configuration Firebase pour Dawa4All

## Fichiers de configuration requis

Pour faire fonctionner l'application, vous devez créer vos propres fichiers de configuration Firebase :

### 1. Configuration Android

1. Allez sur la [Console Firebase](https://console.firebase.google.com/)
2. Créez un nouveau projet ou utilisez un projet existant
3. Ajoutez une application Android avec le package name : `com.example.dawa4all`
4. Téléchargez le fichier `google-services.json`
5. Placez-le dans `android/app/google-services.json`

### 2. Configuration iOS (si nécessaire)

1. Ajoutez une application iOS dans votre projet Firebase
2. Téléchargez le fichier `GoogleService-Info.plist`
3. Placez-le dans `ios/Runner/GoogleService-Info.plist`

### 3. Services Firebase à activer

Dans votre console Firebase, activez les services suivants :

- **Authentication** (Email/Password)
- **Firestore Database**
- **Storage** (pour les images d'ordonnances)

### 4. Règles de sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Clients collection
    match /clients/{clientId} {
      allow read, write: if request.auth != null && request.auth.uid == clientId;
    }
    
    // Pharmacies collection
    match /pharmacies/{pharmacieId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == pharmacieId;
    }
    
    // Medicaments collection
    match /medicaments/{medicamentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
    
    // Commandes collection
    match /commandes/{commandeId} {
      allow read, write: if request.auth != null;
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 5. Règles de sécurité Storage

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Ordonnances (images d'ordonnances)
    match /ordonnances/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Variables d'environnement

Les fichiers suivants sont ignorés par Git pour des raisons de sécurité :

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `firebase_options.dart`
- Tous les fichiers `.env*`

## Template

Utilisez le fichier `android/app/google-services.json.template` comme base pour créer votre propre configuration.

## Support

Pour toute question sur la configuration Firebase, consultez la [documentation officielle](https://firebase.google.com/docs/flutter/setup).