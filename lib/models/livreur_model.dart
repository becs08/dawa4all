import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les livreurs
class LivreurModel {
  final String id;
  final String userId; // ID de l'utilisateur associé
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String adresse;
  final String ville;
  final String cni;
  final String nomComplet;
  final String numeroPermis;
  final String typeVehicule;
  final String numeroVehicule;
  final String plaqueVehicule;
  final bool estDisponible;
  final GeoPoint? positionActuelle;
  final double note; // Note moyenne
  final int nombreAvis;
  final int nombreLivraisons;
  final String? photoUrl;
  final String statut; // 'actif', 'inactif', 'en_livraison', 'en_attente_validation'
  final DateTime dateInscription;
  final DateTime derniereActivite;

  LivreurModel({
    required this.id,
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.ville,
    required this.cni,
    required this.nomComplet,
    required this.numeroPermis,
    required this.typeVehicule,
    required this.numeroVehicule,
    required this.plaqueVehicule,
    this.estDisponible = true,
    this.positionActuelle,
    this.note = 0.0,
    this.nombreAvis = 0,
    this.nombreLivraisons = 0,
    this.photoUrl,
    this.statut = 'actif',
    required this.dateInscription,
    required this.derniereActivite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'adresse': adresse,
      'ville': ville,
      'cni': cni,
      'nomComplet': nomComplet,
      'numeroPermis': numeroPermis,
      'typeVehicule': typeVehicule,
      'numeroVehicule': numeroVehicule,
      'plaqueVehicule': plaqueVehicule,
      'estDisponible': estDisponible,
      'positionActuelle': positionActuelle,
      'note': note,
      'nombreAvis': nombreAvis,
      'nombreLivraisons': nombreLivraisons,
      'photoUrl': photoUrl,
      'statut': statut,
      'dateInscription': Timestamp.fromDate(dateInscription),
      'derniereActivite': Timestamp.fromDate(derniereActivite),
    };
  }

  factory LivreurModel.fromMap(Map<String, dynamic> map) {
    return LivreurModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      cni: map['cni'] ?? '',
      nomComplet: map['nomComplet'] ?? '',
      numeroPermis: map['numeroPermis'] ?? '',
      typeVehicule: map['typeVehicule'] ?? '',
      numeroVehicule: map['numeroVehicule'] ?? '',
      plaqueVehicule: map['plaqueVehicule'] ?? '',
      estDisponible: map['estDisponible'] ?? true,
      positionActuelle: map['positionActuelle'] ?? map['localisationActuelle'],
      note: (map['note'] ?? 0.0).toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
      nombreLivraisons: map['nombreLivraisons'] ?? 0,
      photoUrl: map['photoUrl'],
      statut: map['statut'] ?? 'actif',
      dateInscription: map['dateInscription'] != null 
          ? (map['dateInscription'] as Timestamp).toDate() 
          : DateTime.now(),
      derniereActivite: map['derniereActivite'] != null 
          ? (map['derniereActivite'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }

  // Méthode copyWith pour créer une copie modifiée
  LivreurModel copyWith({
    String? id,
    String? userId,
    String? nom,
    String? prenom,
    String? email,
    String? telephone,
    String? adresse,
    String? ville,
    String? cni,
    String? nomComplet,
    String? numeroPermis,
    String? typeVehicule,
    String? numeroVehicule,
    String? plaqueVehicule,
    bool? estDisponible,
    GeoPoint? positionActuelle,
    double? note,
    int? nombreAvis,
    int? nombreLivraisons,
    String? photoUrl,
    String? statut,
    DateTime? dateInscription,
    DateTime? derniereActivite,
  }) {
    return LivreurModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      cni: cni ?? this.cni,
      nomComplet: nomComplet ?? this.nomComplet,
      numeroPermis: numeroPermis ?? this.numeroPermis,
      typeVehicule: typeVehicule ?? this.typeVehicule,
      numeroVehicule: numeroVehicule ?? this.numeroVehicule,
      plaqueVehicule: plaqueVehicule ?? this.plaqueVehicule,
      estDisponible: estDisponible ?? this.estDisponible,
      positionActuelle: positionActuelle ?? this.positionActuelle,
      note: note ?? this.note,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      nombreLivraisons: nombreLivraisons ?? this.nombreLivraisons,
      photoUrl: photoUrl ?? this.photoUrl,
      statut: statut ?? this.statut,
      dateInscription: dateInscription ?? this.dateInscription,
      derniereActivite: derniereActivite ?? this.derniereActivite,
    );
  }
}