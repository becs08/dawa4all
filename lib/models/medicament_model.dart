import 'package:cloud_firestore/cloud_firestore.dart';

// Énumération pour les catégories de médicaments
enum CategorieMedicament {
  antibiotiques,
  antalgiques, 
  vitamines,
  digestif,
  respiratoire,
  cardiologie,
  dermatologie,
  ophtalmologie,
  gynecologie,
  pediatrie,
  autre
}

// Extensions pour l'énumération
extension CategorieMedicamentExtension on CategorieMedicament {
  String get nom {
    switch (this) {
      case CategorieMedicament.antibiotiques:
        return 'Antibiotiques';
      case CategorieMedicament.antalgiques:
        return 'Antalgiques';
      case CategorieMedicament.vitamines:
        return 'Vitamines';
      case CategorieMedicament.digestif:
        return 'Digestif';
      case CategorieMedicament.respiratoire:
        return 'Respiratoire';
      case CategorieMedicament.cardiologie:
        return 'Cardiologie';
      case CategorieMedicament.dermatologie:
        return 'Dermatologie';
      case CategorieMedicament.ophtalmologie:
        return 'Ophtalmologie';
      case CategorieMedicament.gynecologie:
        return 'Gynécologie';
      case CategorieMedicament.pediatrie:
        return 'Pédiatrie';
      case CategorieMedicament.autre:
        return 'Autre';
    }
  }

  String get icone {
    switch (this) {
      case CategorieMedicament.antibiotiques:
        return '💊';
      case CategorieMedicament.antalgiques:
        return '🩹';
      case CategorieMedicament.vitamines:
        return '🍊';
      case CategorieMedicament.digestif:
        return '🍽️';
      case CategorieMedicament.respiratoire:
        return '🫁';
      case CategorieMedicament.cardiologie:
        return '❤️';
      case CategorieMedicament.dermatologie:
        return '🧴';
      case CategorieMedicament.ophtalmologie:
        return '👁️';
      case CategorieMedicament.gynecologie:
        return '🚺';
      case CategorieMedicament.pediatrie:
        return '👶';
      case CategorieMedicament.autre:
        return '💉';
    }
  }

  static CategorieMedicament fromString(String value) {
    switch (value.toLowerCase()) {
      case 'antibiotiques':
        return CategorieMedicament.antibiotiques;
      case 'antalgiques':
        return CategorieMedicament.antalgiques;
      case 'vitamines':
        return CategorieMedicament.vitamines;
      case 'digestif':
        return CategorieMedicament.digestif;
      case 'respiratoire':
        return CategorieMedicament.respiratoire;
      case 'cardiologie':
        return CategorieMedicament.cardiologie;
      case 'dermatologie':
        return CategorieMedicament.dermatologie;
      case 'ophtalmologie':
        return CategorieMedicament.ophtalmologie;
      case 'gynecologie':
      case 'gynécologie':
        return CategorieMedicament.gynecologie;
      case 'pediatrie':
      case 'pédiatrie':
        return CategorieMedicament.pediatrie;
      default:
        return CategorieMedicament.autre;
    }
  }
}

// Modèle pour les médicaments avec catégories améliorées
class Medicament {
  final String id;
  final String nom;
  final String description;
  final double prix;
  final String imageUrl;
  final String laboratoire;
  final int stock;
  final String pharmacieId; // ID de la pharmacie qui vend ce médicament
  final bool necessite0rdonnance; // Si le médicament nécessite une ordonnance
  final String categorie; // Catégorie textuelle pour compatibilité
  final CategorieMedicament categorieEnum; // Catégorie énumérée
  final String? dosage; // Dosage du médicament
  final String? formePharmaceutique; // Comprimé, sirop, gélule, etc.
  final List<String> contreIndications; // Liste des contre-indications
  final String? modeEmploi; // Mode d'emploi
  final DateTime? dateExpiration;
  final DateTime dateAjout;
  final bool estDisponible;
  final double? noteMoyenne; // Note du médicament
  final int nombreAvis;

  Medicament({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.imageUrl,
    required this.laboratoire,
    required this.stock,
    required this.pharmacieId,
    required this.necessite0rdonnance,
    required this.categorie,
    CategorieMedicament? categorieEnum,
    this.dosage,
    this.formePharmaceutique,
    this.contreIndications = const [],
    this.modeEmploi,
    this.dateExpiration,
    required this.dateAjout,
    this.estDisponible = true,
    this.noteMoyenne,
    this.nombreAvis = 0,
  }) : categorieEnum = categorieEnum ?? CategorieMedicamentExtension.fromString(categorie);

  // Méthode pour créer une instance depuis une Map (Firebase)
  factory Medicament.fromMap(Map<String, dynamic> data, String documentId) {
    return Medicament(
      id: documentId,
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      prix: (data['prix'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      laboratoire: data['laboratoire'] ?? '',
      stock: data['stock'] ?? 0,
      pharmacieId: data['pharmacieId'] ?? '',
      necessite0rdonnance: data['necessite0rdonnance'] ?? false,
      categorie: data['categorie'] ?? 'Autre',
      categorieEnum: data['categorieEnum'] != null 
          ? CategorieMedicamentExtension.fromString(data['categorieEnum'])
          : null,
      dosage: data['dosage'],
      formePharmaceutique: data['formePharmaceutique'],
      contreIndications: data['contreIndications'] != null
          ? List<String>.from(data['contreIndications'])
          : [],
      modeEmploi: data['modeEmploi'],
      dateExpiration: data['dateExpiration'] != null 
          ? (data['dateExpiration'] as Timestamp).toDate() 
          : null,
      dateAjout: data['dateAjout'] != null 
          ? (data['dateAjout'] as Timestamp).toDate() 
          : DateTime.now(),
      estDisponible: data['estDisponible'] ?? true,
      noteMoyenne: data['noteMoyenne'] != null ? (data['noteMoyenne']).toDouble() : null,
      nombreAvis: data['nombreAvis'] ?? 0,
    );
  }

  // Méthode pour convertir en Map (pour Firebase)
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'description': description,
      'prix': prix,
      'imageUrl': imageUrl,
      'laboratoire': laboratoire,
      'stock': stock,
      'pharmacieId': pharmacieId,
      'necessite0rdonnance': necessite0rdonnance,
      'categorie': categorie,
      'categorieEnum': categorieEnum.nom,
      'dosage': dosage,
      'formePharmaceutique': formePharmaceutique,
      'contreIndications': contreIndications,
      'modeEmploi': modeEmploi,
      'dateExpiration': dateExpiration != null 
          ? Timestamp.fromDate(dateExpiration!) 
          : null,
      'dateAjout': Timestamp.fromDate(dateAjout),
      'estDisponible': estDisponible,
      'noteMoyenne': noteMoyenne,
      'nombreAvis': nombreAvis,
    };
  }

  // Vérifier si le médicament est bientôt périmé (moins de 30 jours)
  bool get bientotPerime {
    if (dateExpiration == null) return false;
    final difference = dateExpiration!.difference(DateTime.now());
    return difference.inDays <= 30 && difference.inDays >= 0;
  }

  // Vérifier si le médicament est périmé
  bool get estPerime {
    if (dateExpiration == null) return false;
    return dateExpiration!.isBefore(DateTime.now());
  }

  // Obtenir le statut du stock
  String get statutStock {
    if (!estDisponible || estPerime) return 'Indisponible';
    if (stock == 0) return 'Rupture de stock';
    if (stock <= 5) return 'Stock faible';
    return 'En stock';
  }

  // Obtenir l'icône de la catégorie
  String get iconeCategorie => categorieEnum.icone;

  // Créer une copie avec des modifications
  Medicament copyWith({
    String? id,
    String? nom,
    String? description,
    double? prix,
    String? imageUrl,
    String? laboratoire,
    int? stock,
    String? pharmacieId,
    bool? necessite0rdonnance,
    String? categorie,
    CategorieMedicament? categorieEnum,
    String? dosage,
    String? formePharmaceutique,
    List<String>? contreIndications,
    String? modeEmploi,
    DateTime? dateExpiration,
    DateTime? dateAjout,
    bool? estDisponible,
    double? noteMoyenne,
    int? nombreAvis,
  }) {
    return Medicament(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      prix: prix ?? this.prix,
      imageUrl: imageUrl ?? this.imageUrl,
      laboratoire: laboratoire ?? this.laboratoire,
      stock: stock ?? this.stock,
      pharmacieId: pharmacieId ?? this.pharmacieId,
      necessite0rdonnance: necessite0rdonnance ?? this.necessite0rdonnance,
      categorie: categorie ?? this.categorie,
      categorieEnum: categorieEnum ?? this.categorieEnum,
      dosage: dosage ?? this.dosage,
      formePharmaceutique: formePharmaceutique ?? this.formePharmaceutique,
      contreIndications: contreIndications ?? this.contreIndications,
      modeEmploi: modeEmploi ?? this.modeEmploi,
      dateExpiration: dateExpiration ?? this.dateExpiration,
      dateAjout: dateAjout ?? this.dateAjout,
      estDisponible: estDisponible ?? this.estDisponible,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      nombreAvis: nombreAvis ?? this.nombreAvis,
    );
  }
}