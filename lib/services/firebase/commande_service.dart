import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/commande_model.dart';

class CommandeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final CommandeService _instance = CommandeService._internal();
  factory CommandeService() => _instance;
  CommandeService._internal();

  // Mettre à jour une commande
  Future<bool> updateCommande(String commandeId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la commande: $e');
      return false;
    }
  }

  // Obtenir une commande par ID
  Future<CommandeModel?> getCommandeById(String commandeId) async {
    try {
      final doc = await _firestore.collection('commandes').doc(commandeId).get();
      if (doc.exists) {
        return CommandeModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la commande: $e');
      return null;
    }
  }

  // Obtenir les commandes d'un client
  Stream<List<CommandeModel>> getCommandesClient(String clientId) {
    return _firestore
        .collection('commandes')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateCommande', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data()))
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

  // Obtenir les commandes d'un livreur
  Stream<List<CommandeModel>> getCommandesLivreur(String livreurId) {
    return _firestore
        .collection('commandes')
        .where('livreurId', isEqualTo: livreurId)
        .orderBy('dateCommande', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Créer une nouvelle commande
  Future<String?> createCommande(CommandeModel commande) async {
    try {
      final docRef = await _firestore.collection('commandes').add(commande.toMap());
      
      // Mettre à jour l'ID de la commande
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      return null;
    }
  }

  // Annuler une commande
  Future<bool> annulerCommande(String commandeId, String raison) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'annulee',
        'raisonAnnulation': raison,
        'dateAnnulation': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'annulation de la commande: $e');
      return false;
    }
  }

  // Valider une commande (pharmacie)
  Future<bool> validerCommande(String commandeId, String? noteValidation) async {
    try {
      final updates = {
        'statutCommande': 'validee',
        'dateValidation': Timestamp.now(),
      };
      
      if (noteValidation != null && noteValidation.isNotEmpty) {
        updates['noteValidation'] = noteValidation;
      }
      
      await _firestore.collection('commandes').doc(commandeId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la validation de la commande: $e');
      return false;
    }
  }

  // Refuser une commande (pharmacie)
  Future<bool> refuserCommande(String commandeId, String raisonRefus) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'refusee',
        'raisonRefus': raisonRefus,
        'dateRefus': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du refus de la commande: $e');
      return false;
    }
  }

  // Mettre à jour le statut d'une commande
  Future<bool> updateStatut(String commandeId, String nouveauStatut) async {
    try {
      final updates = <String, dynamic>{
        'statutCommande': nouveauStatut,
      };
      
      // Ajouter la date selon le statut
      switch (nouveauStatut) {
        case 'en_preparation':
          updates['datePreparation'] = Timestamp.now();
          break;
        case 'prete':
          updates['datePrete'] = Timestamp.now();
          break;
        case 'en_livraison':
          updates['dateLivraison'] = Timestamp.now();
          break;
        case 'livree':
          updates['dateLivraison'] = Timestamp.now();
          break;
      }
      
      await _firestore.collection('commandes').doc(commandeId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }
}