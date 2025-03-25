// lib/models/medicament_model.dart
class Medicament {
  final String? id;
  final String nom;
  final String image;
  final String prixAncien;
  final String prixNouveau;
  final String categorie;
  final int quantite;
  final String description;

  Medicament({
    this.id,
    required this.nom,
    required this.image,
    required this.prixAncien,
    required this.prixNouveau,
    required this.categorie,
    required this.quantite,
    required this.description,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      id: json['id'],
      nom: json['nom'] ?? '',
      image: json['image'] ?? 'assets/medicament.png',
      prixAncien: json['prixAncien'] ?? '',
      prixNouveau: json['prixNouveau'] ?? '',
      categorie: json['categorie'] ?? 'Adulte',
      quantite: json['quantite'] ?? 0,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'image': image,
      'prixAncien': prixAncien,
      'prixNouveau': prixNouveau,
      'categorie': categorie,
      'quantite': quantite,
      'description': description,
    };
  }
}