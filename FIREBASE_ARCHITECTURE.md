# Architecture Firebase pour Dawa4All V2

## Collections Firebase nécessaires

### 1. users
Collection principale pour tous les utilisateurs
```json
{
  "userId": {
    "id": "string",
    "email": "string",
    "nom": "string",
    "telephone": "string",
    "typeUtilisateur": "client|pharmacie|livreur",
    "dateCreation": "timestamp"
  }
}
```

### 2. clients
Profil spécifique des clients
```json
{
  "clientId": {
    "id": "string",
    "userId": "string", // Référence vers users
    "nomComplet": "string",
    "adresse": "string",
    "ville": "string",
    "quartier": "string?",
    "localisation": "GeoPoint?",
    "historiqueCommandes": ["string"], // IDs des commandes
    "photoUrl": "string?"
  }
}
```

### 3. pharmacies
Profil des pharmacies
```json
{
  "pharmacieId": {
    "id": "string",
    "userId": "string", // Référence vers users
    "nomPharmacie": "string",
    "adresse": "string",
    "ville": "string",
    "localisation": "GeoPoint", // Position GPS obligatoire
    "numeroLicense": "string",
    "heuresOuverture": "string",
    "heuresFermeture": "string",
    "note": "number", // Note moyenne
    "nombreAvis": "number",
    "estOuverte": "boolean",
    "photoUrl": "string?"
  }
}
```

### 4. livreurs
Profil des livreurs
```json
{
  "livreurId": {
    "id": "string",
    "userId": "string", // Référence vers users
    "nomComplet": "string",
    "numeroPermis": "string",
    "typeVehicule": "string",
    "numeroVehicule": "string",
    "estDisponible": "boolean",
    "positionActuelle": "GeoPoint?",
    "note": "number",
    "nombreAvis": "number",
    "nombreLivraisons": "number",
    "photoUrl": "string?",
    "statut": "actif|inactif|en_livraison"
  }
}
```

### 5. medicaments
Médicaments vendus par les pharmacies
```json
{
  "medicamentId": {
    "id": "string",
    "nom": "string",
    "description": "string",
    "prix": "number",
    "prixAncien": "number?", // Pour les promotions
    "imageUrl": "string",
    "laboratoire": "string",
    "stock": "number",
    "pharmacieId": "string", // Référence vers pharmacies
    "necessite0rdonnance": "boolean",
    "categorie": "string", // Adulte, Enfant, etc.
    "dosage": "string?",
    "dateExpiration": "timestamp?",
    "dateAjout": "timestamp",
    "estDisponible": "boolean"
  }
}
```

### 6. commandes
Commandes des clients
```json
{
  "commandeId": {
    "id": "string",
    "clientId": "string",
    "clientNom": "string",
    "clientTelephone": "string",
    "clientAdresse": "string",
    "clientLocalisation": "GeoPoint",
    "pharmacieId": "string",
    "pharmacieNom": "string",
    "pharmacieLocalisation": "GeoPoint",
    "items": [
      {
        "medicamentId": "string",
        "medicamentNom": "string",
        "prix": "number",
        "quantite": "number",
        "necessite0rdonnance": "boolean"
      }
    ],
    "montantTotal": "number",
    "fraisLivraison": "number",
    "statutCommande": "en_attente|validee|refusee|en_livraison|livree",
    "livreurId": "string?",
    "livreurNom": "string?",
    "dateCommande": "timestamp",
    "dateValidation": "timestamp?",
    "dateLivraison": "timestamp?",
    "modePaiement": "wave|om|cash",
    "paiementEffectue": "boolean",
    "ordonnanceUrl": "string?", // URL de l'ordonnance uploadée
    "noteValidation": "string?", // Note de la pharmacie
    "raisonRefus": "string?",
    "notePharmacie": "number?", // Note donnée par le client
    "noteLivreur": "number?", // Note donnée par le client
    "commentaireClient": "string?"
  }
}
```

### 7. notifications
Notifications pour tous les utilisateurs
```json
{
  "notificationId": {
    "id": "string",
    "destinataireId": "string", // ID de l'utilisateur
    "typeDestinataire": "pharmacie|livreur|client",
    "titre": "string",
    "message": "string",
    "type": "commande|livraison|validation|refus|etc",
    "commandeId": "string?", // Référence vers commande si applicable
    "dateCreation": "timestamp",
    "lue": "boolean",
    "donnees": "object?" // Données supplémentaires
  }
}
```

### 8. remboursements
Demandes de remboursement (pour les paiements Wave/OM refusés)
```json
{
  "remboursementId": {
    "commandeId": "string",
    "clientId": "string",
    "montant": "number",
    "modePaiement": "wave|om",
    "statut": "en_attente|traite|echec",
    "dateCreation": "timestamp",
    "dateTraitement": "timestamp?"
  }
}
```

## Index Firebase recommandés

### Pour les requêtes de géolocalisation et recherche :
- `medicaments`: `pharmacieId`, `estDisponible`, `nom`
- `commandes`: `clientId`, `pharmacieId`, `livreurId`, `statutCommande`, `dateCommande`
- `notifications`: `destinataireId`, `typeDestinataire`, `dateCreation`, `lue`
- `pharmacies`: `estOuverte`, `ville`
- `livreurs`: `estDisponible`, `statut`

### Index composés nécessaires :
- `commandes`: `pharmacieId` + `statutCommande` + `dateCommande`
- `commandes`: `livreurId` + `statutCommande`
- `notifications`: `destinataireId` + `typeDestinataire` + `lue`
- `medicaments`: `pharmacieId` + `estDisponible` + `necessite0rdonnance`

## Sécurité Firebase Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users peuvent lire/écrire leur propre profil
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Clients peuvent lire/écrire leur propre profil
    match /clients/{clientId} {
      allow read, write: if request.auth != null && request.auth.uid == clientId;
    }
    
    // Pharmacies peuvent lire/écrire leur propre profil
    match /pharmacies/{pharmacieId} {
      allow read: if request.auth != null; // Lecture publique pour les clients
      allow write: if request.auth != null && request.auth.uid == pharmacieId;
    }
    
    // Livreurs peuvent lire/écrire leur propre profil
    match /livreurs/{livreurId} {
      allow read: if request.auth != null; // Lecture pour pharmacies
      allow write: if request.auth != null && request.auth.uid == livreurId;
    }
    
    // Médicaments - lecture publique, écriture par propriétaire pharmacie
    match /medicaments/{medicamentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        get(/databases/$(database)/documents/medicaments/$(medicamentId)).data.pharmacieId == request.auth.uid;
    }
    
    // Commandes - accès selon le rôle
    match /commandes/{commandeId} {
      allow read, write: if request.auth != null && (
        resource.data.clientId == request.auth.uid ||
        resource.data.pharmacieId == request.auth.uid ||
        resource.data.livreurId == request.auth.uid
      );
    }
    
    // Notifications - lecture par le destinataire
    match /notifications/{notificationId} {
      allow read: if request.auth != null && 
        resource.data.destinataireId == request.auth.uid;
      allow write: if request.auth != null;
    }
  }
}
```

## Configuration Firebase Storage

### Répertoires :
- `/ordonnances/{commandeId}/` : Images des ordonnances
- `/medicaments/{medicamentId}/` : Photos des médicaments
- `/profils/{userId}/` : Photos de profil
- `/pharmacies/{pharmacieId}/` : Photos des pharmacies

### Règles de stockage :
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Ordonnances - seulement le client propriétaire
    match /ordonnances/{commandeId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    
    // Photos de profil
    match /profils/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Photos de médicaments - par la pharmacie propriétaire
    match /medicaments/{medicamentId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## Actions à effectuer sur Firebase Console

1. **Créer le projet Firebase**
2. **Activer Authentication avec Email/Password**
3. **Créer les collections Firestore** (automatique lors de la première écriture)
4. **Configurer les index composés** (via Firebase Console > Firestore > Index)
5. **Activer Firebase Storage**
6. **Configurer les règles de sécurité** (copier les règles ci-dessus)
7. **Activer les notifications push** (optionnel pour les notifications temps réel)

## Extension recommandées
- **Firebase Extensions > Delete User Data** : Pour supprimer automatiquement les données utilisateur
- **Firebase Extensions > Resize Images** : Pour redimensionner les images uploadées