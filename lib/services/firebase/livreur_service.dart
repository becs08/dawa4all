import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/livreur_model.dart';
import '../../models/commande_model.dart';
import '../../models/notification_model.dart';

class LivreurService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final LivreurService _instance = LivreurService._internal();
  factory LivreurService() => _instance;
  LivreurService._internal();

  // Obtenir un livreur par ID
  Future<LivreurModel?> getLivreurById(String id) async {
    try {
      final doc = await _firestore.collection('livreurs').doc(id).get();
      if (doc.exists) {
        return LivreurModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du livreur: $e');
      return null;
    }
  }

  // Obtenir tous les livreurs
  Future<List<LivreurModel>> getAllLivreurs() async {
    try {
      final querySnapshot = await _firestore
          .collection('livreurs')
          .orderBy('note', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LivreurModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des livreurs: $e');
      return [];
    }
  }

  // Obtenir les livreurs disponibles
  Future<List<LivreurModel>> getLivreursDisponibles() async {
    try {
      final querySnapshot = await _firestore
          .collection('livreurs')
          .where('estDisponible', isEqualTo: true)
          .where('statut', isEqualTo: 'actif')
          .orderBy('note', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => LivreurModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des livreurs disponibles: $e');
      return [];
    }
  }

  // Mettre à jour la position du livreur
  Future<bool> updatePosition(String livreurId, Position position) async {
    try {
      await _firestore.collection('livreurs').doc(livreurId).update({
        'positionActuelle': GeoPoint(position.latitude, position.longitude),
        'derniereActivite': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la position: $e');
      return false;
    }
  }

  // Mettre à jour la disponibilité
  Future<bool> updateDisponibilite(String livreurId, bool estDisponible) async {
    try {
      await _firestore.collection('livreurs').doc(livreurId).update({
        'estDisponible': estDisponible,
        'statut': estDisponible ? 'actif' : 'inactif',
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la disponibilité: $e');
      return false;
    }
  }

  // Obtenir les demandes de livraison disponibles (non attribuées)
  Stream<List<CommandeModel>> getDemandesLivraison() {
    return _firestore
        .collection('commandes')
        .where('statutCommande', isEqualTo: 'validee')
        .where('livreurId', isNull: true)
        .orderBy('dateValidation', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtenir les commandes attribuées à un livreur spécifique
  Stream<List<CommandeModel>> getCommandesAttribuees(String livreurId) {
    return _firestore
        .collection('commandes')
        .where('statutCommande', isEqualTo: 'prete')
        .where('livreurId', isEqualTo: livreurId)
        .orderBy('datePrete', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Refuser une livraison
  Future<bool> refuserLivraison(String commandeId) async {
    try {
      // Marquer la commande comme refusée par ce livreur
      await _firestore.collection('commandes').doc(commandeId).update({
        'dateDerniereRefus': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du refus de la livraison: $e');
      return false;
    }
  }

  // Accepter une livraison
  Future<bool> accepterLivraison(String commandeId, String livreurId, [String? livreurNom]) async {
    try {
      // Vérifier si la commande est toujours disponible
      final commandeDoc = await _firestore.collection('commandes').doc(commandeId).get();
      if (!commandeDoc.exists) return false;
      
      final commande = CommandeModel.fromMap(commandeDoc.data()!, commandeId);
      // Pour les commandes attribuées, vérifier que c'est bien le bon livreur
      if (commande.statutCommande == 'prete' && commande.livreurId != livreurId) {
        // La commande a été attribuée à un autre livreur
        return false;
      }
      // Pour les commandes non attribuées, vérifier qu'elles sont disponibles
      if (commande.statutCommande == 'validee' && commande.livreurId != null) {
        // La commande a déjà été prise par un autre livreur
        return false;
      }

      // Obtenir le nom du livreur si pas fourni
      String nomLivreur = livreurNom ?? '';
      if (nomLivreur.isEmpty) {
        final livreurDoc = await _firestore.collection('livreurs').doc(livreurId).get();
        if (livreurDoc.exists) {
          final livreurData = livreurDoc.data()!;
          nomLivreur = '${livreurData['nom']} ${livreurData['prenom']}';
        }
      }

      // Attribuer le livreur
      await _firestore.collection('commandes').doc(commandeId).update({
        'livreurId': livreurId,
        'livreurNom': nomLivreur,
        'statutCommande': 'en_route_pharmacie',
        'statut': 'en_route_pharmacie',
        'dateAcceptation': Timestamp.now(),
      });

      // Mettre à jour le statut du livreur
      await _firestore.collection('livreurs').doc(livreurId).update({
        'statut': 'en_livraison',
        'estDisponible': false,
      });

      // Créer des notifications
      final batch = _firestore.batch();

      // Notification pour le client
      final notifClient = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        destinataireId: commande.clientId,
        typeDestinataire: 'client',
        titre: 'Livreur en route',
        message: 'Votre livreur $nomLivreur est en route',
        type: NotificationType.commandeLivraison,
        commandeId: commandeId,
        dateCreation: DateTime.now(),
      );
      batch.set(
        _firestore.collection('notifications').doc(notifClient.id),
        notifClient.toMap(),
      );

      // Notification pour la pharmacie
      final notifPharmacie = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        destinataireId: commande.pharmacieId,
        typeDestinataire: 'pharmacie',
        titre: 'Livraison acceptée',
        message: 'Le livreur $nomLivreur a accepté la livraison',
        type: NotificationType.commandeLivraison,
        commandeId: commandeId,
        dateCreation: DateTime.now(),
      );
      batch.set(
        _firestore.collection('notifications').doc(notifPharmacie.id),
        notifPharmacie.toMap(),
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de l\'acceptation de la livraison: $e');
      return false;
    }
  }

  // Confirmer récupération à la pharmacie
  Future<bool> confirmerRecuperationCommande(String commandeId) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'recuperee',
        'statut': 'en_route_client',
        'dateRecuperation': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la confirmation de récupération: $e');
      return false;
    }
  }

  // Confirmer une livraison
  Future<bool> confirmerLivraison(String commandeId, [String? livreurId]) async {
    try {
      await _firestore.collection('commandes').doc(commandeId).update({
        'statutCommande': 'livree',
        'statut': 'livree',
        'dateLivraison': Timestamp.now(),
      });

      // Obtenir livreurId de la commande si pas fourni
      String actualLivreurId = livreurId ?? '';
      if (actualLivreurId.isEmpty) {
        final commandeDoc = await _firestore.collection('commandes').doc(commandeId).get();
        if (commandeDoc.exists) {
          actualLivreurId = commandeDoc.data()!['livreurId'] ?? '';
        }
      }

      // Mettre à jour les stats du livreur
      if (actualLivreurId.isNotEmpty) {
        final livreurDoc = await _firestore.collection('livreurs').doc(actualLivreurId).get();
        if (livreurDoc.exists) {
          final livreur = LivreurModel.fromMap(livreurDoc.data()!);
          
          await _firestore.collection('livreurs').doc(actualLivreurId).update({
            'nombreLivraisons': livreur.nombreLivraisons + 1,
            'statut': 'actif',
            'estDisponible': true,
          });
        }
      }

      // Créer une notification pour le client
      final commandeDoc = await _firestore.collection('commandes').doc(commandeId).get();
      if (commandeDoc.exists) {
        final commande = CommandeModel.fromMap(commandeDoc.data()!);
        
        final notification = NotificationModel(
          id: _firestore.collection('notifications').doc().id,
          destinataireId: commande.clientId,
          typeDestinataire: 'client',
          titre: 'Livraison effectuée',
          message: 'Votre commande a été livrée avec succès',
          type: NotificationType.commandeLivree,
          commandeId: commandeId,
          dateCreation: DateTime.now(),
        );

        await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
      }

      return true;
    } catch (e) {
      print('Erreur lors de la confirmation de la livraison: $e');
      return false;
    }
  }

  // Obtenir l'historique des livraisons
  Stream<List<CommandeModel>> getHistoriqueLivraisons(String livreurId) {
    return _firestore
        .collection('commandes')
        .where('livreurId', isEqualTo: livreurId)
        .orderBy('dateLivraison', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Obtenir la livraison en cours
  Future<CommandeModel?> getLivraisonEnCours(String livreurId) async {
    try {
      final snapshot = await _firestore
          .collection('commandes')
          .where('livreurId', isEqualTo: livreurId)
          .where('statutCommande', isEqualTo: 'en_livraison')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CommandeModel.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la livraison en cours: $e');
      return null;
    }
  }

  // Calculer les revenus du livreur
  Future<Map<String, dynamic>> getStatistiquesLivreur(String livreurId) async {
    try {
      final snapshot = await _firestore
          .collection('commandes')
          .where('livreurId', isEqualTo: livreurId)
          .where('statutCommande', isEqualTo: 'livree')
          .get();

      double totalRevenus = 0;
      int nombreLivraisons = 0;
      
      for (var doc in snapshot.docs) {
        final commande = CommandeModel.fromMap(doc.data());
        totalRevenus += commande.fraisLivraison;
        nombreLivraisons++;
      }

      return {
        'totalRevenus': totalRevenus,
        'nombreLivraisons': nombreLivraisons,
        'revenuMoyen': nombreLivraisons > 0 ? totalRevenus / nombreLivraisons : 0,
      };
    } catch (e) {
      print('Erreur lors du calcul des statistiques: $e');
      return {
        'totalRevenus': 0,
        'nombreLivraisons': 0,
        'revenuMoyen': 0,
      };
    }
  }

  // Obtenir les livreurs disponibles près d'une position
  Future<List<LivreurModel>> getLivreursDisponiblesProches(GeoPoint position, double radiusKm) async {
    try {
      final snapshot = await _firestore
          .collection('livreurs')
          .where('estDisponible', isEqualTo: true)
          .where('statut', isEqualTo: 'actif')
          .get();

      final livreurs = snapshot.docs
          .map((doc) => LivreurModel.fromMap(doc.data()))
          .toList();

      // Filtrer par distance
      final livreursProches = <LivreurModel>[];
      
      for (var livreur in livreurs) {
        if (livreur.positionActuelle != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            livreur.positionActuelle!.latitude,
            livreur.positionActuelle!.longitude,
          );
          
          if (distance <= radiusKm * 1000) {
            livreursProches.add(livreur);
          }
        }
      }

      // Trier par note décroissante
      livreursProches.sort((a, b) => b.note.compareTo(a.note));

      return livreursProches;
    } catch (e) {
      print('Erreur lors de la récupération des livreurs disponibles: $e');
      return [];
    }
  }
}