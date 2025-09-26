import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../models/pharmacie_model.dart';
import '../../models/medicament_model.dart';
import '../../models/commande_model.dart';
import '../../models/notification_model.dart';

class PharmacieService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Instance unique (Singleton)
  static final PharmacieService _instance = PharmacieService._internal();
  factory PharmacieService() => _instance;
  PharmacieService._internal();

  String? get currentPharmacieId => _auth.currentUser?.uid;

  // Obtenir les statistiques du dashboard
  Future<Map<String, dynamic>> getDashboardStats() async {
    if (currentPharmacieId == null) {
      throw Exception('Pharmacie non connectée');
    }

    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      final commandesAujourdhui = await _firestore
          .collection('commandes')
          .where('pharmacieId', isEqualTo: currentPharmacieId)
          .where('dateCommande', isGreaterThanOrEqualTo: startOfDay)
          .where('dateCommande', isLessThanOrEqualTo: endOfDay)
          .get();

      final medicaments = await _firestore
          .collection('medicaments')
          .where('pharmacieId', isEqualTo: currentPharmacieId)
          .get();

      final startOfMonth = DateTime(today.year, today.month, 1);
      final commandesMois = await _firestore
          .collection('commandes')
          .where('pharmacieId', isEqualTo: currentPharmacieId)
          .where('statutCommande', isEqualTo: 'livree')
          .where('dateCommande', isGreaterThanOrEqualTo: startOfMonth)
          .get();

      double revenusMois = 0.0;
      for (var doc in commandesMois.docs) {
        final data = doc.data() as Map<String, dynamic>;
        revenusMois += (data['montantTotal'] ?? 0.0).toDouble();
      }

      final pharmacie = await _firestore
          .collection('pharmacies')
          .doc(currentPharmacieId)
          .get();
      
      double noteMoyenne = 0.0;
      if (pharmacie.exists) {
        final data = pharmacie.data() as Map<String, dynamic>;
        noteMoyenne = (data['note'] ?? 0.0).toDouble();
      }

      return {
        'commandesAujourdhui': commandesAujourdhui.docs.length,
        'totalMedicaments': medicaments.docs.length,
        'revenusMois': revenusMois,
        'noteMoyenne': noteMoyenne,
      };
    } catch (e) {
      print('Erreur lors de la récupération des stats: $e');
      return {
        'commandesAujourdhui': 0,
        'totalMedicaments': 0,
        'revenusMois': 0.0,
        'noteMoyenne': 0.0,
      };
    }
  }

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

  // Obtenir une pharmacie par ID (Stream)
  Stream<PharmacieModel?> getPharmacie(String id) {
    return _firestore.collection('pharmacies').doc(id).snapshots().map((doc) {
      if (doc.exists) {
        return PharmacieModel.fromMap({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
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
      print('🔵 ajouterMedicament appelé avec pharmacieId: $pharmacieId');
      print('📦 Médicament: ${medicament.nom}');
      
      final data = medicament.toMap();
      print('📝 Données à envoyer: $data');
      
      final docRef = await _firestore.collection('medicaments').add(data);
      print('✅ Médicament ajouté avec ID: ${docRef.id}');
      
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du médicament: $e');
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
          type: NotificationType.commandeValidee,
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
        type: NotificationType.commandeRefusee,
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
        type: NotificationType.commandeLivraison,
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
  Future<bool> updatePharmacieProfil(Map<String, dynamic> updates) async {
    try {
      if (currentPharmacieId == null) {
        throw Exception('Pharmacie non connectée');
      }
      await _firestore.collection('pharmacies').doc(currentPharmacieId).update(updates);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du profil: $e');
      return false;
    }
  }

  // Changer le statut d'ouverture/fermeture
  Future<bool> changerStatutOuverture(bool ouvert) async {
    try {
      if (currentPharmacieId == null) {
        throw Exception('Pharmacie non connectée');
      }
      await _firestore.collection('pharmacies').doc(currentPharmacieId).update({
        'estOuverte': ouvert,
      });
      return true;
    } catch (e) {
      print('Erreur lors du changement de statut: $e');
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

  // Mettre à jour le statut d'une commande
  Future<bool> updateCommandeStatut(String commandeId, String nouveauStatut) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': nouveauStatut,
        'dateMiseAJour': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // Corriger les champs manquants dans les pharmacies existantes
  Future<bool> corrigerChampsManquants() async {
    try {
      final snapshot = await _firestore.collection('pharmacies').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Vérifier si les champs sont manquants
        Map<String, dynamic> updates = {};
        
        if (!data.containsKey('joursGarde')) {
          updates['joursGarde'] = [];
        }
        
        if (!data.containsKey('horairesDetailles')) {
          updates['horairesDetailles'] = {
            'lundi': '08:00-20:00',
            'mardi': '08:00-20:00',
            'mercredi': '08:00-20:00',
            'jeudi': '08:00-20:00',
            'vendredi': '08:00-20:00',
            'samedi': '08:00-20:00',
            'dimanche': 'Fermé',
          };
        }
        
        if (!data.containsKey('horaires24h')) {
          updates['horaires24h'] = false;
        }
        
        if (!data.containsKey('estOuverte')) {
          updates['estOuverte'] = data['ouvert'] ?? true;
        }
        
        if (!data.containsKey('telephonePharmacie')) {
          updates['telephonePharmacie'] = '';
        }
        
        if (!data.containsKey('horairesOuverture')) {
          final ouverture = data['heuresOuverture'] ?? '08:00';
          final fermeture = data['heuresFermeture'] ?? '20:00';
          updates['horairesOuverture'] = '$ouverture-$fermeture';
        }
        
        // Appliquer les mises à jour si nécessaire
        if (updates.isNotEmpty) {
          await _firestore.collection('pharmacies').doc(doc.id).update(updates);
          print('✅ Pharmacie ${doc.id} mise à jour: ${updates.keys.join(', ')}');
        }
      }
      
      return true;
    } catch (e) {
      print('❌ Erreur lors de la correction des champs manquants: $e');
      return false;
    }
  }
}