import 'package:cloud_firestore/cloud_firestore.dart';

// Classe de base pour tous les utilisateurs
class UserModel {
  final String id;
  final String email;
  final String nom;
  final String telephone;
  final String typeUtilisateur; // 'pharmacie', 'livreur', 'client'
  final DateTime dateCreation;

  UserModel({
    required this.id,
    required this.email,
    required this.nom,
    required this.telephone,
    required this.typeUtilisateur,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'telephone': telephone,
      'typeUtilisateur': typeUtilisateur,
      'dateCreation': Timestamp.fromDate(dateCreation),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      nom: map['nom'] ?? '',
      telephone: map['telephone'] ?? '',
      typeUtilisateur: map['typeUtilisateur'] ?? '',
      dateCreation: (map['dateCreation'] as Timestamp).toDate(),
    );
  }
}