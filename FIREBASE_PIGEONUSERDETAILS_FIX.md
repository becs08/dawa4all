# Résolution de l'erreur PigeonUserDetails Firebase

## Description du problème
L'erreur `type 'List<Object?>' is not a subtype of type 'PigeonUserDetails?' in type cast` est un bug connu de Firebase Auth sur Flutter qui se produit lors de la création de comptes utilisateurs.

## Solutions à essayer dans l'ordre

### 1. Nettoyer le cache Flutter
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### 2. Mettre à jour les packages Firebase
Dans `pubspec.yaml`, essayez ces versions spécifiques qui sont connues pour fonctionner ensemble :
```yaml
dependencies:
  firebase_core: 2.15.1
  firebase_auth: 4.9.0
  cloud_firestore: 4.9.1
```

Puis exécutez :
```bash
flutter pub get
```

### 3. Modifier android/app/build.gradle
Assurez-vous que ces lignes sont présentes :
```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### 4. Vérifier google-services.json
1. Téléchargez la dernière version depuis Firebase Console
2. Placez-la dans `android/app/`
3. Vérifiez que le package name correspond

### 5. Solution temporaire dans le code
Le code a déjà été modifié pour gérer cette erreur avec une stratégie de contournement :
- Tentative de création du compte
- Si erreur PigeonUserDetails, attendre 1 seconde
- Essayer de se connecter avec les mêmes identifiants
- Si succès, continuer avec la création du profil

### 6. Alternative : Utiliser l'émulateur Firebase Auth
Pour le développement local, vous pouvez utiliser l'émulateur Firebase :
```dart
await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
```

### 7. Si le problème persiste
1. Créez un nouveau projet Flutter minimal avec seulement Firebase Auth
2. Testez si l'inscription fonctionne
3. Si oui, comparez les configurations
4. Si non, le problème vient de l'environnement de développement

## Vérifications supplémentaires
- [ ] Firebase Auth est activé dans Firebase Console
- [ ] Les méthodes email/password sont activées
- [ ] Le projet Firebase n'a pas atteint ses quotas
- [ ] La connexion Internet est stable
- [ ] Aucun proxy/firewall ne bloque Firebase

## Logs utiles
Activez les logs détaillés :
```dart
FirebaseAuth.instance.setLogLevel(LogLevel.debug);
```