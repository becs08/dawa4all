import 'package:cloud_firestore/cloud_firestore.dart';

/// Types de notifications possibles
enum NotificationType {
  nouvelleCommande,
  commandeValidee,
  commandeRefusee,
  commandePreparation,
  commandePrete,
  commandeLivraison,
  commandeLivree,
  commandeAnnulee,
  nouvellePharmacieGarde,
  stockFaible,
  rappel,
  systeme,
  nouvelleLivraison,
  livreurAttribue,
}

// Modèle pour les notifications
class NotificationModel {
  final String? id;
  final String destinataireId;
  final String typeDestinataire; // 'pharmacie', 'livreur', 'client'
  final String titre;
  final String message;
  final NotificationType type;
  final String? commandeId;
  final String? pharmacieId;
  final DateTime dateCreation;
  final bool lue;
  final Map<String, dynamic>? donnees; // Données supplémentaires

  NotificationModel({
    this.id,
    required this.destinataireId,
    required this.typeDestinataire,
    required this.titre,
    required this.message,
    required this.type,
    this.commandeId,
    this.pharmacieId,
    required this.dateCreation,
    this.lue = false,
    this.donnees,
  });

  /// Crée une copie avec modification
  NotificationModel copyWith({
    String? id,
    String? destinataireId,
    String? typeDestinataire,
    String? titre,
    String? message,
    NotificationType? type,
    String? commandeId,
    String? pharmacieId,
    DateTime? dateCreation,
    bool? lue,
    Map<String, dynamic>? donnees,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      destinataireId: destinataireId ?? this.destinataireId,
      typeDestinataire: typeDestinataire ?? this.typeDestinataire,
      titre: titre ?? this.titre,
      message: message ?? this.message,
      type: type ?? this.type,
      commandeId: commandeId ?? this.commandeId,
      pharmacieId: pharmacieId ?? this.pharmacieId,
      dateCreation: dateCreation ?? this.dateCreation,
      lue: lue ?? this.lue,
      donnees: donnees ?? this.donnees,
    );
  }

  /// Convertit en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'destinataireId': destinataireId,
      'typeDestinataire': typeDestinataire,
      'titre': titre,
      'message': message,
      'type': type.toString().split('.').last,
      'commandeId': commandeId,
      'pharmacieId': pharmacieId,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'lue': lue,
      'donnees': donnees,
    };
  }

  Map<String, dynamic> toMap() => toFirestore();

  /// Crée depuis un document Firestore
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel.fromMap(data, doc.id);
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    // Convertir le type string en enum
    NotificationType notifType = NotificationType.systeme;
    final typeStr = map['type'] as String?;
    if (typeStr != null) {
      try {
        notifType = NotificationType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => NotificationType.systeme,
        );
      } catch (_) {
        notifType = NotificationType.systeme;
      }
    }

    return NotificationModel(
      id: documentId ?? map['id'],
      destinataireId: map['destinataireId'] ?? '',
      typeDestinataire: map['typeDestinataire'] ?? '',
      titre: map['titre'] ?? '',
      message: map['message'] ?? '',
      type: notifType,
      commandeId: map['commandeId'],
      pharmacieId: map['pharmacieId'],
      dateCreation: map['dateCreation'] != null 
          ? (map['dateCreation'] as Timestamp).toDate()
          : DateTime.now(),
      lue: map['lue'] ?? false,
      donnees: map['donnees'],
    );
  }

  /// Obtient l'icône emoji selon le type
  String getIcon() {
    switch (type) {
      case NotificationType.nouvelleCommande:
        return '🛒';
      case NotificationType.commandeValidee:
        return '✅';
      case NotificationType.commandeRefusee:
        return '❌';
      case NotificationType.commandePreparation:
        return '⚙️';
      case NotificationType.commandePrete:
        return '📦';
      case NotificationType.commandeLivraison:
        return '🚚';
      case NotificationType.commandeLivree:
        return '🎉';
      case NotificationType.commandeAnnulee:
        return '🚫';
      case NotificationType.nouvellePharmacieGarde:
        return '🏥';
      case NotificationType.stockFaible:
        return '⚠️';
      case NotificationType.rappel:
        return '🔔';
      case NotificationType.systeme:
        return '📢';
      case NotificationType.nouvelleLivraison:
        return '🚚';
      case NotificationType.livreurAttribue:
        return '👨‍💼';
    }
  }

  /// Crée une notification pour nouvelle commande (usage pharmacie)
  static NotificationModel nouvelleCommande({
    required String destinataireId,
    required String commandeId,
    required String pharmacieId,
    required String clientNom,
    required double montant,
  }) {
    return NotificationModel(
      destinataireId: destinataireId,
      typeDestinataire: 'pharmacie',
      titre: 'Nouvelle commande reçue',
      message: 'Commande de $clientNom pour ${montant.toStringAsFixed(0)} FCFA',
      type: NotificationType.nouvelleCommande,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      donnees: {
        'clientNom': clientNom,
        'montant': montant,
      },
    );
  }

  /// Crée une notification pour changement de statut (usage client)
  static NotificationModel changementStatut({
    required String destinataireId,
    required String commandeId,
    required String pharmacieId,
    required String statut,
    required String clientNom,
  }) {
    NotificationType type;
    String titre;

    switch (statut) {
      case 'validee':
        type = NotificationType.commandeValidee;
        titre = 'Commande validée';
        break;
      case 'en_preparation':
        type = NotificationType.commandePreparation;
        titre = 'Commande en préparation';
        break;
      case 'prete':
        type = NotificationType.commandePrete;
        titre = 'Commande prête';
        break;
      case 'en_livraison':
        type = NotificationType.commandeLivraison;
        titre = 'Commande en livraison';
        break;
      case 'livree':
        type = NotificationType.commandeLivree;
        titre = 'Commande livrée';
        break;
      case 'refusee':
        type = NotificationType.commandeRefusee;
        titre = 'Commande refusée';
        break;
      case 'annulee':
        type = NotificationType.commandeAnnulee;
        titre = 'Commande annulée';
        break;
      default:
        type = NotificationType.systeme;
        titre = 'Mise à jour de commande';
    }

    return NotificationModel(
      destinataireId: destinataireId,
      typeDestinataire: 'client',
      titre: titre,
      message: 'Votre commande a été mise à jour',
      type: type,
      commandeId: commandeId,
      pharmacieId: pharmacieId,
      dateCreation: DateTime.now(),
      donnees: {
        'statut': statut,
        'clientNom': clientNom,
      },
    );
  }
}