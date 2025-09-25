import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les clients
class ClientModel {
  final String id;
  final String userId; // ID de l'utilisateur associé
  final String nomComplet;
  final String adresse;
  final String ville;
  final String? quartier;
  final GeoPoint? localisation;
  final List<String> historiqueCommandes;
  final String? photoUrl;

  ClientModel({
    required this.id,
    required this.userId,
    required this.nomComplet,
    required this.adresse,
    required this.ville,
    this.quartier,
    this.localisation,
    this.historiqueCommandes = const [],
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nomComplet': nomComplet,
      'adresse': adresse,
      'ville': ville,
      'quartier': quartier,
      'localisation': localisation,
      'historiqueCommandes': historiqueCommandes,
      'photoUrl': photoUrl,
    };
  }

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      nomComplet: map['nomComplet'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      quartier: map['quartier'],
      localisation: map['localisation'],
      historiqueCommandes: List<String>.from(map['historiqueCommandes'] ?? []),
      photoUrl: map['photoUrl'],
    );
  }
}