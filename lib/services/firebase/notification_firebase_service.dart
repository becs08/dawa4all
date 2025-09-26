import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/notification_model.dart';
import '../notification_service.dart';

class NotificationFirebaseService {
  static final NotificationFirebaseService _instance = NotificationFirebaseService._internal();
  factory NotificationFirebaseService() => _instance;
  NotificationFirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  /// Collection des notifications
  CollectionReference get _notificationsCollection => 
      _firestore.collection('notifications');

  /// Crée une nouvelle notification
  Future<bool> creerNotification(NotificationModel notification) async {
    try {
      // Ajouter la notification à Firestore
      final docRef = await _notificationsCollection.add(notification.toFirestore());
      
      // Afficher la notification locale
      await _afficherNotificationLocale(notification.copyWith(id: docRef.id));
      
      print('✅ Notification créée avec succès: ${docRef.id}');
      return true;
    } catch (e) {
      print('❌ Erreur lors de la création de notification: $e');
      return false;
    }
  }

  /// Affiche une notification locale
  Future<void> _afficherNotificationLocale(NotificationModel notification) async {
    switch (notification.type) {
      case NotificationType.nouvelleCommande:
        await _notificationService.showNewOrderNotification(
          commandeId: notification.commandeId ?? '',
          clientNom: notification.donnees?['clientNom'] ?? 'Client inconnu',
          montant: (notification.donnees?['montant'] ?? 0.0).toDouble(),
        );
        break;
      
      default:
        await _notificationService.showLocalNotification(
          title: '${notification.getIcon()} ${notification.titre}',
          body: notification.message,
          payload: '${notification.type.toString().split('.').last}:${notification.commandeId ?? ''}',
        );
    }
  }

  /// Obtient les notifications d'un utilisateur
  Stream<List<NotificationModel>> getNotificationsUtilisateur(String utilisateurId) {
    return _notificationsCollection
        .where('destinataireId', isEqualTo: utilisateurId)
        .orderBy('dateCreation', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Marque une notification comme lue
  Future<bool> marquerCommeLue(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'lue': true,
      });
      return true;
    } catch (e) {
      print('❌ Erreur lors du marquage comme lue: $e');
      return false;
    }
  }

  /// Marque toutes les notifications comme lues
  Future<bool> marquerToutesCommeLues(String utilisateurId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsCollection
          .where('destinataireId', isEqualTo: utilisateurId)
          .where('lue', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'lue': true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('❌ Erreur lors du marquage global: $e');
      return false;
    }
  }

  /// Supprime une notification
  Future<bool> supprimerNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      return true;
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Supprime les anciennes notifications (plus de 30 jours)
  Future<void> nettoyerAnciennesNotifications() async {
    try {
      final dateLimit = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _notificationsCollection
          .where('dateCreation', isLessThan: Timestamp.fromDate(dateLimit))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('🧹 ${snapshot.docs.length} anciennes notifications supprimées');
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Obtient le nombre de notifications non lues
  Future<int> getNombreNotificationsNonLues(String utilisateurId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('destinataireId', isEqualTo: utilisateurId)
          .where('lue', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('❌ Erreur lors du comptage: $e');
      return 0;
    }
  }

  /// Stream pour le nombre de notifications non lues
  Stream<int> streamNombreNotificationsNonLues(String utilisateurId) {
    return _notificationsCollection
        .where('destinataireId', isEqualTo: utilisateurId)
        .where('lue', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Crée une notification pour nouvelle commande
  Future<void> notifierNouvelleCommande({
    required String pharmacieId,
    required String commandeId,
    required String clientNom,
    required double montant,
  }) async {
    final notification = NotificationModel.nouvelleCommande(
      destinataireId: pharmacieId,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      clientNom: clientNom,
      montant: montant,
    );

    await creerNotification(notification);
  }

  /// Crée une notification pour changement de statut
  Future<void> notifierChangementStatut({
    required String clientId,
    required String commandeId,
    required String pharmacieId,
    required String statut,
    required String clientNom,
  }) async {
    final notification = NotificationModel.changementStatut(
      destinataireId: clientId,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      statut: statut,
      clientNom: clientNom,
    );

    await creerNotification(notification);
  }

  /// Écoute les nouvelles commandes et envoie des notifications
  void ecouterNouvellesCommandes(String pharmacieId) {
    _firestore
        .collection('commandes')
        .where('pharmacieId', isEqualTo: pharmacieId)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Vérifier si c'est vraiment une nouvelle commande
          final dateCommande = (data['dateCommande'] as Timestamp?)?.toDate();
          if (dateCommande != null && 
              DateTime.now().difference(dateCommande).inMinutes < 2) {
            
            notifierNouvelleCommande(
              pharmacieId: pharmacieId,
              commandeId: change.doc.id,
              clientNom: data['clientNom'] ?? 'Client inconnu',
              montant: (data['montantTotal'] ?? 0.0).toDouble(),
            );
          }
        }
        
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final clientId = data['clientId'];
          final statut = data['statutCommande'];
          
          if (clientId != null && statut != null) {
            notifierChangementStatut(
              clientId: clientId,
              commandeId: change.doc.id,
              pharmacieId: pharmacieId,
              statut: statut,
              clientNom: data['clientNom'] ?? 'Client inconnu',
            );
          }
        }
      }
    });
  }

  /// Initialise les listeners pour les notifications temps réel
  void initialiserListeners(String utilisateurId, String userType) {
    if (userType == 'pharmacie') {
      // Écouter les nouvelles commandes pour cette pharmacie
      ecouterNouvellesCommandes(utilisateurId);
    }
    
    // Programmer le nettoyage périodique
    Future.delayed(const Duration(hours: 24), () {
      nettoyerAnciennesNotifications();
    });
  }
}