import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les notifications
class NotificationModel {
  final String id;
  final String destinataireId;
  final String typeDestinataire; // 'pharmacie', 'livreur', 'client'
  final String titre;
  final String message;
  final String type; // 'commande', 'livraison', 'validation', 'refus', etc.
  final String? commandeId;
  final DateTime dateCreation;
  final bool lue;
  final Map<String, dynamic>? donnees; // Données supplémentaires

  NotificationModel({
    required this.id,
    required this.destinataireId,
    required this.typeDestinataire,
    required this.titre,
    required this.message,
    required this.type,
    this.commandeId,
    required this.dateCreation,
    this.lue = false,
    this.donnees,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'destinataireId': destinataireId,
      'typeDestinataire': typeDestinataire,
      'titre': titre,
      'message': message,
      'type': type,
      'commandeId': commandeId,
      'dateCreation': Timestamp.fromDate(dateCreation),
      'lue': lue,
      'donnees': donnees,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      destinataireId: map['destinataireId'] ?? '',
      typeDestinataire: map['typeDestinataire'] ?? '',
      titre: map['titre'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      commandeId: map['commandeId'],
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
      lue: map['lue'] ?? false,
      donnees: map['donnees'],
    );
  }
}