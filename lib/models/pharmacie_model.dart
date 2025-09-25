import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les pharmacies avec fonctionnalités étendues
class PharmacieModel {
  final String id;
  final String userId; // ID de l'utilisateur associé
  final String nomPharmacie;
  final String adresse;
  final String ville;
  final String? telephone;
  final String? email;
  final GeoPoint localisation; // Position GPS
  final String numeroLicense;
  final String heuresOuverture;
  final String heuresFermeture;
  final String? horairesOuverture; // Format: "08:00-20:00" ou "24h/24"
  final bool horaires24h;
  final List<String> joursGarde; // Liste des jours de garde: ["lundi", "mardi", etc.]
  final double note; // Note moyenne
  final int nombreAvis;
  final bool estOuverte;
  final String? photoUrl;
  final Map<String, String>? horairesDetailles; // Horaires par jour de la semaine
  final DateTime? dateCreation;

  PharmacieModel({
    required this.id,
    required this.userId,
    required this.nomPharmacie,
    required this.adresse,
    required this.ville,
    this.telephone,
    this.email,
    required this.localisation,
    required this.numeroLicense,
    required this.heuresOuverture,
    required this.heuresFermeture,
    this.horairesOuverture,
    this.horaires24h = false,
    this.joursGarde = const [],
    this.note = 0.0,
    this.nombreAvis = 0,
    this.estOuverte = true,
    this.photoUrl,
    this.horairesDetailles,
    this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'nomPharmacie': nomPharmacie,
      'adresse': adresse,
      'ville': ville,
      'telephone': telephone,
      'email': email,
      'localisation': localisation,
      'numeroLicense': numeroLicense,
      'heuresOuverture': heuresOuverture,
      'heuresFermeture': heuresFermeture,
      'horairesOuverture': horairesOuverture,
      'horaires24h': horaires24h,
      'joursGarde': joursGarde,
      'note': note,
      'nombreAvis': nombreAvis,
      'estOuverte': estOuverte,
      'photoUrl': photoUrl,
      'horairesDetailles': horairesDetailles,
      'dateCreation': dateCreation != null ? Timestamp.fromDate(dateCreation!) : null,
    };
  }

  factory PharmacieModel.fromMap(Map<String, dynamic> map) {
    return PharmacieModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      nomPharmacie: map['nomPharmacie'] ?? '',
      adresse: map['adresse'] ?? '',
      ville: map['ville'] ?? '',
      telephone: map['telephone'],
      email: map['email'],
      localisation: map['localisation'],
      numeroLicense: map['numeroLicense'] ?? '',
      heuresOuverture: map['heuresOuverture'] ?? '',
      heuresFermeture: map['heuresFermeture'] ?? '',
      horairesOuverture: map['horairesOuverture'],
      horaires24h: map['horaires24h'] ?? false,
      joursGarde: List<String>.from(map['joursGarde'] ?? []),
      note: (map['note'] ?? 0.0).toDouble(),
      nombreAvis: map['nombreAvis'] ?? 0,
      estOuverte: map['estOuverte'] ?? true,
      photoUrl: map['photoUrl'],
      horairesDetailles: map['horairesDetailles'] != null 
          ? Map<String, String>.from(map['horairesDetailles'])
          : null,
      dateCreation: map['dateCreation'] != null 
          ? (map['dateCreation'] as Timestamp).toDate()
          : null,
    );
  }

  // Vérifier si la pharmacie est ouverte maintenant
  bool get estOuverteActuellement {
    final now = DateTime.now();
    
    // Si c'est une pharmacie 24h/24, elle est toujours ouverte
    if (horaires24h) return true;
    
    // Vérifier si c'est un jour de garde
    final jourActuel = _getJourSemaine(now.weekday);
    final estJourGarde = joursGarde.contains(jourActuel);
    
    // Si c'est un jour de garde, la pharmacie peut être ouverte selon ses horaires spéciaux
    if (estJourGarde) {
      return true; // Simplifié: les pharmacies de garde sont considérées ouvertes
    }
    
    // Vérifier les horaires normaux
    if (horairesDetailles != null && horairesDetailles!.containsKey(jourActuel)) {
      return _estDansHoraires(horairesDetailles![jourActuel]!, now);
    }
    
    // Fallback sur horairesOuverture si disponible
    if (horairesOuverture != null) {
      return _estDansHoraires(horairesOuverture!, now);
    }
    
    // Fallback sur estOuverte
    return estOuverte;
  }

  // Obtenir le statut textuel de la pharmacie
  String get statutTexte {
    if (horaires24h) return "Ouvert 24h/24";
    
    final now = DateTime.now();
    final jourActuel = _getJourSemaine(now.weekday);
    
    if (joursGarde.contains(jourActuel)) {
      return "De garde aujourd'hui";
    }
    
    if (estOuverteActuellement) {
      return "Ouvert";
    } else {
      return "Fermé";
    }
  }

  // Obtenir la couleur du statut
  String get couleurStatut {
    if (horaires24h) return "green";
    if (joursGarde.contains(_getJourSemaine(DateTime.now().weekday))) return "orange";
    return estOuverteActuellement ? "green" : "red";
  }

  // Helper: obtenir le jour de la semaine en français
  String _getJourSemaine(int weekday) {
    const jours = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    return jours[weekday - 1];
  }

  // Helper: vérifier si l'heure actuelle est dans les horaires
  bool _estDansHoraires(String horaires, DateTime maintenant) {
    if (horaires.toLowerCase().contains('24h') || horaires.toLowerCase().contains('24/24')) {
      return true;
    }
    
    // Format attendu: "08:00-20:00" ou "08:00-12:00, 14:00-20:00"
    final creneaux = horaires.split(',');
    final heureActuelle = maintenant.hour * 60 + maintenant.minute;
    
    for (final creneau in creneaux) {
      final parties = creneau.trim().split('-');
      if (parties.length == 2) {
        final debut = _parseHeure(parties[0].trim());
        final fin = _parseHeure(parties[1].trim());
        
        if (debut != null && fin != null) {
          if (heureActuelle >= debut && heureActuelle <= fin) {
            return true;
          }
        }
      }
    }
    
    return false;
  }

  // Helper: parser une heure au format "HH:MM"
  int? _parseHeure(String heure) {
    try {
      final parties = heure.split(':');
      if (parties.length == 2) {
        final heures = int.parse(parties[0]);
        final minutes = int.parse(parties[1]);
        return heures * 60 + minutes;
      }
    } catch (e) {
      // Erreur de parsing
    }
    return null;
  }

  // Obtenir les prochains jours de garde
  List<String> get prochainsJoursGarde {
    final joursOrdre = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    
    final aujourd = DateTime.now().weekday - 1; // 0-6
    final prochains = <String>[];
    
    for (int i = 1; i <= 7; i++) {
      final jour = joursOrdre[(aujourd + i) % 7];
      if (joursGarde.contains(jour)) {
        prochains.add(jour);
      }
    }
    
    return prochains.take(3).toList(); // Max 3 prochains jours
  }

  // Créer une copie avec des modifications
  PharmacieModel copyWith({
    String? id,
    String? userId,
    String? nomPharmacie,
    String? adresse,
    String? ville,
    String? telephone,
    String? email,
    GeoPoint? localisation,
    String? numeroLicense,
    String? heuresOuverture,
    String? heuresFermeture,
    String? horairesOuverture,
    bool? horaires24h,
    List<String>? joursGarde,
    double? note,
    int? nombreAvis,
    bool? estOuverte,
    String? photoUrl,
    Map<String, String>? horairesDetailles,
    DateTime? dateCreation,
  }) {
    return PharmacieModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      nomPharmacie: nomPharmacie ?? this.nomPharmacie,
      adresse: adresse ?? this.adresse,
      ville: ville ?? this.ville,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      localisation: localisation ?? this.localisation,
      numeroLicense: numeroLicense ?? this.numeroLicense,
      heuresOuverture: heuresOuverture ?? this.heuresOuverture,
      heuresFermeture: heuresFermeture ?? this.heuresFermeture,
      horairesOuverture: horairesOuverture ?? this.horairesOuverture,
      horaires24h: horaires24h ?? this.horaires24h,
      joursGarde: joursGarde ?? this.joursGarde,
      note: note ?? this.note,
      nombreAvis: nombreAvis ?? this.nombreAvis,
      estOuverte: estOuverte ?? this.estOuverte,
      photoUrl: photoUrl ?? this.photoUrl,
      horairesDetailles: horairesDetailles ?? this.horairesDetailles,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}