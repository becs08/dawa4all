import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les livreurs
class LivreurModel {
  final String id;
  final String userId; // ID de l'utilisateur associé
  final String nomComplet;
  final String numeroPermis;
  final String typeVehicule;
  final String numeroVehicule;
  final bool estDisponible;
  final GeoPoint? positionActuelle;
  final double note; // Note moyenne
  final int nombreAvis;
  final int nombreLivraisons;
  final String? photoUrl;
  final String statut; // 'actif', 'inactif', 'en_livraison'

  LivreurModel({
    required this.id,
    required this.userId,
    required this.nomComplet,
    required this.numeroPermis,
    required this.typeVehicule,
    required this.numeroVehicule,
    this.estDisponible = true,
    this.positionActuelle,
    this.note = 0.0,
    this.nombreAvis = 0,
    this.nombreLivraisons = 0,
    this.photoUrl,
    this.statut = 'actif',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nomComplet': nomComplet,
      'numeroPermis': numeroPermis,
      'typeVehicule': typeVehicule,
      'numeroVehicule': numeroVehicule,
      'estDisponible': estDisponible,
      'positionActuelle': positionActuelle,
      'note': note,
      'nombreAvis': nombreAvis,
      'nombreLivraisons': nombreLivraisons,
      'photoUrl': photoUrl,
      'statut': statut,
    };
  }

  factory LivreurModel.fromMap(Map<String, dynamic> map) {
    return LivreurModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      nomComplet: map['nomComplet'] ?? '',
      numeroPermis: map['numeroPermis'] ?? '',
      typeVehicule: map['typeVehicule'] ?? '',
      numeroVehicule: map['numeroVehicule'] ?? '',
      estDisponible: map['estDisponible'] ?? true,
      positionActuelle: map['positionActuelle'],
      note: (map['note'] ?? 0.0).toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
      nombreLivraisons: map['nombreLivraisons'] ?? 0,
      photoUrl: map['photoUrl'],
      statut: map['statut'] ?? 'actif',
    );
  }
}