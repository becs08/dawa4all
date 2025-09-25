import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/pharmacie_model.dart';
import '../../models/medicament_model.dart';
import '../../models/commande_model.dart';
import '../../models/notification_model.dart';

class PharmacieService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final PharmacieService _instance = PharmacieService._internal();
  factory PharmacieService() => _instance;
  PharmacieService._internal();

  // Obtenir une pharmacie par ID
  Future<PharmacieModel?> getPharmacieById(String id) async {
    try {
      final doc = await _firestore.collection('pharmacies').doc(id).get();
      if (doc.exists) {
        return PharmacieModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la pharmacie: $e');
      return null;
    }
  }

  // Obtenir toutes les pharmacies (Stream)
  Stream<List<PharmacieModel>> getAllPharmaciesStream() {
    return _firestore
        .collection('pharmacies')
        .where('estOuverte', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PharmacieModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  // Obtenir toutes les pharmacies (Future)
  Future<List<PharmacieModel>> getAllPharmacies() async {
    try {
      final snapshot = await _firestore.collection('pharmacies').get();
      return snapshot.docs
          .map((doc) => PharmacieModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des pharmacies: $e');
      return [];
    }
  }

  // Obtenir les 3 pharmacies les plus proches (sans limite de rayon)
  Future<List<PharmacieModel>> getPharmaciesProches(Position position, [int limit = 3]) async {
    try {
      // Récupérer toutes les pharmacies
      final snapshot = await _firestore
          .collection('pharmacies')
          .where('estOuverte', isEqualTo: true)
          .get();

      final pharmacies = snapshot.docs
          .map((doc) => PharmacieModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      // Trier toutes les pharmacies par distance
      pharmacies.sort((a, b) {
        final distanceA = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          a.localisation.latitude,
          a.localisation.longitude,
        );
        
        final distanceB = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          b.localisation.latitude,
          b.localisation.longitude,
        );
        
        return distanceA.compareTo(distanceB);
      });

      // Retourner seulement les X plus proches
      return pharmacies.take(limit).toList();
    } catch (e) {
      print('Erreur lors de la récupération des pharmacies proches: $e');
      return [];
    }
  }

  // Ajouter un médicament
  Future<bool> ajouterMedicament(String pharmacieId, Medicament medicament) async {
    try {
      await _firestore.collection('medicaments').add(medicament.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout du médicament: $e');
      return false;
    }
  }

  // Modifier un médicament
  Future<bool> modifierMedicament(String medicamentId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('medicaments').doc(medicamentId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la modification du médicament: $e');
      return false;
    }
  }

  // Supprimer un médicament
  Future<bool> supprimerMedicament(String medicamentId) async {
    try {
      await _firestore.collection('medicaments').doc(medicamentId).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du médicament: $e');
      return false;
    }
  }

  // Obtenir les médicaments d'une pharmacie
  Stream<List<Medicament>> getMedicamentsPharmacie(String pharmacieId) {
    return _firestore
        .collection('medicaments')
        .where('pharmacieId', isEqualTo: pharmacieId)
        .where('estDisponible', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medicament.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtenir les commandes d'une pharmacie
  Stream<List<CommandeModel>> getCommandesPharmacie(String pharmacieId) {
    return _firestore
        .collection('commandes')
        .where('pharmacieId', isEqualTo: pharmacieId)
        .orderBy('dateCommande', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Valider une commande
  Future<bool> validerCommande(String commandeId, String noteValidation) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'validee',
        'dateValidation': Timestamp.now(),
        'noteValidation': noteValidation,
      });

      // Créer une notification pour le client
      final commande = await _firestore.collection('commandes').doc(commandeId).get();
      if (commande.exists) {
        final commandeData = CommandeModel.fromMap(commande.data()!);
        
        final notification = NotificationModel(
          id: _firestore.collection('notifications').doc().id,
          destinataireId: commandeData.clientId,
          typeDestinataire: 'client',
          titre: 'Commande validée',
          message: 'Votre commande a été validée par ${commandeData.pharmacieNom}',
          type: 'validation',
          commandeId: commandeId,
          dateCreation: DateTime.now(),
        );

        await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
      }

      return true;
    } catch (e) {
      print('Erreur lors de la validation de la commande: $e');
      return false;
    }
  }

  // Refuser une commande
  Future<bool> refuserCommande(String commandeId, String raisonRefus) async {
    try {
      // Récupérer la commande
      final commandeDoc = await _firestore.collection('commandes').doc(commandeId).get();
      if (!commandeDoc.exists) return false;

      final commande = CommandeModel.fromMap(commandeDoc.data()!);

      // Mettre à jour le statut
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'refusee',
        'dateValidation': Timestamp.now(),
        'raisonRefus': raisonRefus,
      });

      // Si le paiement a été effectué, créer une demande de remboursement
      if (commande.paiementEffectue && commande.modePaiement != 'cash') {
        await _firestore.collection('remboursements').add({
          'commandeId': commandeId,
          'clientId': commande.clientId,
          'montant': commande.montantTotalAvecLivraison,
          'modePaiement': commande.modePaiement,
          'statut': 'en_attente',
          'dateCreation': Timestamp.now(),
        });
      }

      // Créer une notification pour le client
      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        destinataireId: commande.clientId,
        typeDestinataire: 'client',
        titre: 'Commande refusée',
        message: 'Votre commande a été refusée. Raison: $raisonRefus',
        type: 'refus',
        commandeId: commandeId,
        dateCreation: DateTime.now(),
      );

      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());

      return true;
    } catch (e) {
      print('Erreur lors du refus de la commande: $e');
      return false;
    }
  }

  // Attribuer un livreur à une commande
  Future<bool> attribuerLivreur(String commandeId, String livreurId, String livreurNom) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'livreurId': livreurId,
        'livreurNom': livreurNom,
        'statutCommande': 'en_livraison',
      });

      // Créer une notification pour le livreur
      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        destinataireId: livreurId,
        typeDestinataire: 'livreur',
        titre: 'Nouvelle livraison',
        message: 'Une nouvelle livraison vous a été attribuée',
        type: 'livraison',
        commandeId: commandeId,
        dateCreation: DateTime.now(),
      );

      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());

      return true;
    } catch (e) {
      print('Erreur lors de l\'attribution du livreur: $e');
      return false;
    }
  }

  // Mettre à jour le profil de la pharmacie
  Future<bool> updatePharmacieProfil(String pharmacieId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('pharmacies').doc(pharmacieId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Mettre à jour le stock d'un médicament
  Future<bool> updateStock(String medicamentId, int newStock) async {
    try {
      await _firestore.collection('medicaments').doc(medicamentId).update({
        'stock': newStock,
        'estDisponible': newStock > 0,
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du stock: $e');
      return false;
    }
  }
}