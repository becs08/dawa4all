import 'package:cloud_firestore/cloud_firestore.dart';

// Modèle pour les commandes
class CommandeModel {
  final String id;
  final String clientId;
  final String clientNom;
  final String clientPrenom;
  final String clientTelephone;
  final String clientAdresse;
  final String adresseLivraison;
  final GeoPoint clientLocalisation;
  final GeoPoint? clientPosition;
  final String pharmacieId;
  final String pharmacieNom;
  final String pharmacieAdresse;
  final GeoPoint pharmacieLocalisation;
  final GeoPoint? pharmaciePosition;
  final List<ItemCommande> items;
  final List<Map<String, dynamic>> medicaments;
  final double montantTotal;
  final double total;
  final double fraisLivraison;
  final String statutCommande; // 'en_attente', 'validee', 'refusee', 'en_livraison', 'livree'
  final String statut; // Alias pour statutCommande
  final String? livreurId;
  final String? livreurNom;
  final DateTime dateCommande;
  final DateTime? dateValidation;
  final DateTime? dateLivraison;
  final String modePaiement; // 'wave', 'om', 'cash'
  final bool paiementEffectue;
  final String? typeLivraison; // 'standard', 'express'
  final String? ordonnanceUrl; // URL de l'ordonnance uploadée
  final String? noteValidation; // Note de la pharmacie (posologie, etc.)
  final String? raisonRefus;
  final double? notePharmacie;
  final double? noteLivreur;
  final String? commentaireClient;

  CommandeModel({
    required this.id,
    required this.clientId,
    required this.clientNom,
    required this.clientPrenom,
    required this.clientTelephone,
    required this.clientAdresse,
    required this.adresseLivraison,
    required this.clientLocalisation,
    this.clientPosition,
    required this.pharmacieId,
    required this.pharmacieNom,
    required this.pharmacieAdresse,
    required this.pharmacieLocalisation,
    this.pharmaciePosition,
    required this.items,
    required this.medicaments,
    required this.montantTotal,
    required this.total,
    required this.fraisLivraison,
    required this.statutCommande,
    required this.statut,
    this.livreurId,
    this.livreurNom,
    required this.dateCommande,
    this.dateValidation,
    this.dateLivraison,
    required this.modePaiement,
    required this.paiementEffectue,
    this.typeLivraison,
    this.ordonnanceUrl,
    this.noteValidation,
    this.raisonRefus,
    this.notePharmacie,
    this.noteLivreur,
    this.commentaireClient,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'clientNom': clientNom,
      'clientPrenom': clientPrenom,
      'clientTelephone': clientTelephone,
      'clientAdresse': clientAdresse,
      'adresseLivraison': adresseLivraison,
      'clientLocalisation': clientLocalisation,
      'clientPosition': clientPosition,
      'pharmacieId': pharmacieId,
      'pharmacieNom': pharmacieNom,
      'pharmacieAdresse': pharmacieAdresse,
      'pharmacieLocalisation': pharmacieLocalisation,
      'pharmaciePosition': pharmaciePosition,
      'items': items.map((item) => item.toMap()).toList(),
      'medicaments': medicaments,
      'montantTotal': montantTotal,
      'total': total,
      'fraisLivraison': fraisLivraison,
      'statutCommande': statutCommande,
      'statut': statut,
      'livreurId': livreurId,
      'livreurNom': livreurNom,
      'dateCommande': Timestamp.fromDate(dateCommande),
      'dateValidation': dateValidation != null ? Timestamp.fromDate(dateValidation!) : null,
      'dateLivraison': dateLivraison != null ? Timestamp.fromDate(dateLivraison!) : null,
      'modePaiement': modePaiement,
      'paiementEffectue': paiementEffectue,
      'typeLivraison': typeLivraison,
      'ordonnanceUrl': ordonnanceUrl,
      'noteValidation': noteValidation,
      'raisonRefus': raisonRefus,
      'notePharmacie': notePharmacie,
      'noteLivreur': noteLivreur,
      'commentaireClient': commentaireClient,
    };
  }

  factory CommandeModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    final statutCommande = map['statutCommande'] ?? map['statut'] ?? 'en_attente';
    final medicamentsList = map['medicaments'] != null 
        ? List<Map<String, dynamic>>.from(map['medicaments']) 
        : <Map<String, dynamic>>[];
    
    return CommandeModel(
      id: documentId ?? map['id'] ?? '',
      clientId: map['clientId'] ?? '',
      clientNom: map['clientNom'] ?? '',
      clientPrenom: map['clientPrenom'] ?? '',
      clientTelephone: map['clientTelephone'] ?? '',
      clientAdresse: map['clientAdresse'] ?? '',
      adresseLivraison: map['adresseLivraison'] ?? map['clientAdresse'] ?? '',
      clientLocalisation: map['clientLocalisation'],
      clientPosition: map['clientPosition'],
      pharmacieId: map['pharmacieId'] ?? '',
      pharmacieNom: map['pharmacieNom'] ?? '',
      pharmacieAdresse: map['pharmacieAdresse'] ?? '',
      pharmacieLocalisation: map['pharmacieLocalisation'],
      pharmaciePosition: map['pharmaciePosition'],
      items: List<ItemCommande>.from(
        (map['items'] ?? []).map((item) => ItemCommande.fromMap(item)),
      ),
      medicaments: medicamentsList,
      montantTotal: (map['montantTotal'] ?? map['total'] ?? 0).toDouble(),
      total: (map['total'] ?? map['montantTotal'] ?? 0).toDouble(),
      fraisLivraison: (map['fraisLivraison'] ?? 0).toDouble(),
      statutCommande: statutCommande,
      statut: statutCommande,
      livreurId: map['livreurId'],
      livreurNom: map['livreurNom'],
      dateCommande: (map['dateCommande'] as Timestamp).toDate(),
      dateValidation: map['dateValidation'] != null 
          ? (map['dateValidation'] as Timestamp).toDate() 
          : null,
      dateLivraison: map['dateLivraison'] != null 
          ? (map['dateLivraison'] as Timestamp).toDate() 
          : null,
      modePaiement: map['modePaiement'] ?? 'cash',
      paiementEffectue: map['paiementEffectue'] ?? false,
      typeLivraison: map['typeLivraison'],
      ordonnanceUrl: map['ordonnanceUrl'],
      noteValidation: map['noteValidation'],
      raisonRefus: map['raisonRefus'],
      notePharmacie: map['notePharmacie'] != null 
          ? (map['notePharmacie']).toDouble() 
          : null,
      noteLivreur: map['noteLivreur'] != null 
          ? (map['noteLivreur']).toDouble() 
          : null,
      commentaireClient: map['commentaireClient'],
    );
  }

  // Factory constructor for Firestore documents
  factory CommandeModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return CommandeModel.fromMap(data, docId);
  }

  // Alternative factory constructor
  factory CommandeModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommandeModel.fromMap(data, doc.id);
  }

  // Calculer le montant total (médicaments + livraison)
  double get montantTotalAvecLivraison => montantTotal + fraisLivraison;
}

// Modèle pour les items d'une commande
class ItemCommande {
  final String medicamentId;
  final String medicamentNom;
  final double prix;
  final int quantite;
  final bool necessite0rdonnance;

  ItemCommande({
    required this.medicamentId,
    required this.medicamentNom,
    required this.prix,
    required this.quantite,
    required this.necessite0rdonnance,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicamentId': medicamentId,
      'medicamentNom': medicamentNom,
      'prix': prix,
      'quantite': quantite,
      'necessite0rdonnance': necessite0rdonnance,
    };
  }

  factory ItemCommande.fromMap(Map<String, dynamic> map) {
    return ItemCommande(
      medicamentId: map['medicamentId'] ?? '',
      medicamentNom: map['medicamentNom'] ?? '',
      prix: (map['prix'] ?? 0).toDouble(),
      quantite: map['quantite'] ?? 1,
      necessite0rdonnance: map['necessite0rdonnance'] ?? false,
    );
  }

  // Calculer le sous-total de l'item
  double get sousTotal => prix * quantite;
}