import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Créer une nouvelle notification
  Future<bool> createNotification(NotificationModel notification) async {
    try {
      final docRef = _firestore.collection('notifications').doc();
      final notificationWithId = NotificationModel(
        id: docRef.id,
        destinataireId: notification.destinataireId,
        typeDestinataire: notification.typeDestinataire,
        titre: notification.titre,
        message: notification.message,
        type: notification.type,
        commandeId: notification.commandeId,
        pharmacieId: notification.pharmacieId,
        dateCreation: notification.dateCreation,
        lue: notification.lue,
        donnees: notification.donnees,
      );
      
      await docRef.set(notificationWithId.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de la création de la notification: $e');
      return false;
    }
  }

  // Obtenir les notifications d'un utilisateur
  Stream<List<NotificationModel>> getNotifications(String destinataireId) {
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: destinataireId)
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Marquer une notification comme lue
  Future<bool> marquerCommeLue(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'lu': true,
        'dateLecture': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
      return false;
    }
  }

  // Marquer toutes les notifications comme lues
  Future<bool> marquerToutesCommeLues(String destinataireId) async {
    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: destinataireId)
          .where('lue', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {
          'lue': true,
          'dateLecture': Timestamp.now(),
        });
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors du marquage de toutes les notifications: $e');
      return false;
    }
  }

  // Supprimer une notification
  Future<bool> supprimerNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de la notification: $e');
      return false;
    }
  }

  // Compter les notifications non lues
  Future<int> compterNotificationsNonLues(String destinataireId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: destinataireId)
          .where('lue', isEqualTo: false)
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des notifications: $e');
      return 0;
    }
  }

  // Nettoyer les anciennes notifications (plus de 30 jours)
  Future<bool> nettoyerAnciennesNotifications(String destinataireId) async {
    try {
      final dateLimit = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _firestore
          .collection('notifications')
          .where('destinataireId', isEqualTo: destinataireId)
          .where('dateCreation', isLessThan: Timestamp.fromDate(dateLimit))
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors du nettoyage des notifications: $e');
      return false;
    }
  }

  // Créer une notification de nouvelle commande
  Future<bool> notifierNouvelleCommande({
    required String pharmacieId,
    required String commandeId,
    required String clientNom,
    required double montant,
  }) async {
    return await createNotification(NotificationModel(
      id: '',
      destinataireId: pharmacieId,
      typeDestinataire: 'pharmacie',
      titre: 'Nouvelle commande',
      message: 'Nouvelle commande de $clientNom pour ${montant.toInt()} FCFA',
      type: NotificationType.nouvelleCommande,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      lue: false,
      donnees: {
        'commandeId': commandeId,
        'clientNom': clientNom,
        'montant': montant,
      },
    ));
  }

  // Créer une notification de commande validée
  Future<bool> notifierCommandeValidee({
    required String clientId,
    required String commandeId,
    required String pharmacieNom,
    required String pharmacieId,
  }) async {
    return await createNotification(NotificationModel(
      id: '',
      destinataireId: clientId,
      typeDestinataire: 'client',
      titre: 'Commande validée',
      message: 'Votre commande a été validée par $pharmacieNom',
      type: NotificationType.commandeValidee,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      lue: false,
      donnees: {
        'commandeId': commandeId,
        'pharmacieNom': pharmacieNom,
      },
    ));
  }

  // Créer une notification de commande refusée
  Future<bool> notifierCommandeRefusee({
    required String clientId,
    required String commandeId,
    required String pharmacieNom,
    required String pharmacieId,
    required String raison,
  }) async {
    return await createNotification(NotificationModel(
      id: '',
      destinataireId: clientId,
      typeDestinataire: 'client',
      titre: 'Commande refusée',
      message: 'Votre commande a été refusée par $pharmacieNom. Raison: $raison',
      type: NotificationType.commandeRefusee,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      lue: false,
      donnees: {
        'commandeId': commandeId,
        'pharmacieNom': pharmacieNom,
        'raison': raison,
      },
    ));
  }

  // Créer une notification de livreur attribué
  Future<bool> notifierLivreurAttribue({
    required String clientId,
    required String commandeId,
    required String pharmacieId,
    required String livreurNom,
  }) async {
    return await createNotification(NotificationModel(
      id: '',
      destinataireId: clientId,
      typeDestinataire: 'client',
      titre: 'Livreur attribué',
      message: 'Un livreur ($livreurNom) a été attribué à votre commande',
      type: NotificationType.livreurAttribue,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      lue: false,
      donnees: {
        'commandeId': commandeId,
        'livreurNom': livreurNom,
      },
    ));
  }

  // Créer une notification de nouvelle livraison pour le livreur
  Future<bool> notifierNouvelleLivraison({
    required String livreurId,
    required String commandeId,
    required String pharmacieId,
    required String pharmacieNom,
    required double fraisLivraison,
  }) async {
    return await createNotification(NotificationModel(
      id: '',
      destinataireId: livreurId,
      typeDestinataire: 'livreur',
      titre: 'Nouvelle livraison',
      message: 'Nouvelle livraison disponible de $pharmacieNom (${fraisLivraison.toInt()} FCFA)',
      type: NotificationType.nouvelleLivraison,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      lue: false,
      donnees: {
        'commandeId': commandeId,
        'pharmacieNom': pharmacieNom,
        'fraisLivraison': fraisLivraison,
      },
    ));
  }
}