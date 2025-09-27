# Déboguer l'affichage des demandes de livraison

## Problème actuel
Les demandes de livraison ne s'affichent pas chez le livreur après attribution par la pharmacie.

## Solution

### 1. Créer les index Firestore nécessaires

J'ai créé un fichier `firestore.indexes.json` qui contient les index nécessaires. Pour les déployer:

```bash
firebase deploy --only firestore:indexes
```

Ou créez-les manuellement dans la console Firebase:
1. Allez dans Firestore Database > Index
2. Créez un nouvel index composite pour la collection `commandes`:
   - Field 1: `statutCommande` (Ascending)
   - Field 2: `livreurId` (Ascending)  
   - Field 3: `dateCommande` (Descending)

### 2. Vérifier le flux d'attribution

Le flux correct est:
1. Pharmacie valide une commande → `statutCommande: 'validee'`
2. Pharmacie prépare la commande → `statutCommande: 'en_preparation'`
3. Pharmacie marque comme prête → `statutCommande: 'prete'`
4. Pharmacie attribue un livreur → `statutCommande: 'prete'`, `livreurId: [ID_DU_LIVREUR]`
5. Le livreur voit la commande dans son écran "Disponibles"

### 3. Test rapide

Pour tester rapidement:

1. Connectez-vous en tant que pharmacie
2. Allez dans "Commandes" 
3. Validez une commande en attente
4. Marquez-la comme "En préparation"
5. Marquez-la comme "Prête"
6. Cliquez sur "Attribuer livreur"
7. Sélectionnez un livreur et validez

Ensuite:
1. Connectez-vous en tant que livreur (celui que vous avez sélectionné)
2. Allez dans l'onglet "Disponibles"
3. La commande devrait apparaître

### 4. Vérifier dans Firestore

Dans la console Firebase, vérifiez que la commande a bien:
- `statutCommande: 'prete'`
- `livreurId: [ID_DU_LIVREUR_CONNECTÉ]`
- `livreurNom: [NOM_DU_LIVREUR]`

### 5. Si ça ne marche toujours pas

Vérifiez les logs dans la console pour voir s'il y a des erreurs de permissions ou d'index manquants.