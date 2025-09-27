# Guide de débogage pour l'affichage des commandes chez le livreur

## Corrections appliquées

1. **LivreurService** : Ajouté une nouvelle méthode `getCommandesAttribuees()` qui récupère spécifiquement les commandes avec :
   - `statutCommande: 'prete'`
   - `livreurId: [ID_DU_LIVREUR]`

2. **AvailableDeliveriesScreen** : Modifié pour utiliser la nouvelle méthode du service

3. **Index Firestore** : Ajouté un nouvel index nécessaire

## Vérifications à effectuer

### 1. Dans la console Firebase

Vérifiez qu'après l'attribution, la commande a bien :
```json
{
  "statutCommande": "prete",
  "livreurId": "[ID_DU_LIVREUR]",
  "livreurNom": "[NOM_DU_LIVREUR]",
  "datePrete": "[TIMESTAMP]"
}
```

### 2. Créer le nouvel index

Dans Firebase Console > Firestore > Index, créez :
- Collection ID: `commandes`
- Fields indexed:
  - `statutCommande` (Ascending)
  - `livreurId` (Ascending)  
  - `datePrete` (Descending)

### 3. Test complet

#### Côté Pharmacie :
1. Connexion pharmacie
2. Aller dans "Commandes"
3. Sur une commande en attente :
   - Cliquer "Valider"
   - Cliquer "Préparer"
   - Cliquer "Marquer prête"
   - Cliquer "Attribuer livreur"
4. Dans l'écran d'attribution :
   - Sélectionner un livreur
   - Ajouter des notes (optionnel)
   - Cliquer "Attribuer"

#### Côté Livreur :
1. Déconnexion et reconnexion avec le compte du livreur sélectionné
2. Aller dans l'onglet "Disponibles"
3. La commande doit apparaître avec :
   - Timer de 2 minutes
   - Informations de la pharmacie
   - Informations du client
   - Montant des frais de livraison
   - Boutons Accepter/Refuser

### 4. Si ça ne fonctionne toujours pas

#### Vérifier les logs
Dans la console du navigateur (F12), regardez s'il y a des erreurs

#### Vérifier l'ID du livreur
```dart
// Ajoutez temporairement ce code dans available_deliveries_screen.dart
print('Livreur ID: ${Provider.of<AuthProvider>(context).currentUser?.id}');
```

#### Vérifier manuellement dans Firestore
1. Notez l'ID du livreur connecté
2. Dans Firestore, filtrez les commandes avec :
   - `statutCommande == "prete"`
   - `livreurId == "[ID_NOTÉ]"`

### 5. Solutions alternatives

Si le problème persiste :
1. Supprimez et recréez l'index
2. Vérifiez que le livreur est bien validé (`statut: 'actif'`)
3. Testez avec un nouveau livreur et une nouvelle commande