import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicament_model.dart';
import '../models/pharmacie_model.dart';
import '../models/commande_model.dart';

// Classe pour représenter un article dans le panier
class CartItem {
  final Medicament medicament;
  final PharmacieModel pharmacie;
  int quantite;

  CartItem({
    required this.medicament,
    required this.pharmacie,
    this.quantite = 1,
  });

  double get sousTotal => medicament.prix * quantite;
}

class PanierProvider extends ChangeNotifier {
  List<CartItem> _panier = [];
  String? _pharmacieSelectionneeId;

  // Getters
  List<CartItem> get panier => _panier;
  String? get pharmacieSelectionneeId => _pharmacieSelectionneeId;

  // Ajouter un médicament au panier
  void ajouterAuPanier(Medicament medicament, PharmacieModel pharmacie) {
    // Vérifier si on ajoute d'une pharmacie différente
    if (_pharmacieSelectionneeId != null && 
        _pharmacieSelectionneeId != pharmacie.id) {
      // Demander confirmation avant de vider le panier
      // Pour l'instant on vide directement
      _panier.clear();
    }

    _pharmacieSelectionneeId = pharmacie.id;

    // Vérifier si le médicament est déjà dans le panier
    final index = _panier.indexWhere((item) => item.medicament.id == medicament.id);
    
    if (index >= 0) {
      // Augmenter la quantité si déjà présent et si stock disponible
      if (_panier[index].quantite < medicament.stock) {
        _panier[index].quantite++;
      }
    } else {
      // Ajouter au panier
      _panier.add(CartItem(
        medicament: medicament,
        pharmacie: pharmacie,
      ));
    }
    
    notifyListeners();
  }

  // Retirer un médicament du panier
  void retirerDuPanier(String medicamentId) {
    _panier.removeWhere((item) => item.medicament.id == medicamentId);
    
    if (_panier.isEmpty) {
      _pharmacieSelectionneeId = null;
    }
    
    notifyListeners();
  }

  // Modifier la quantité d'un article
  void modifierQuantite(String medicamentId, int nouvelleQuantite) {
    final index = _panier.indexWhere((item) => item.medicament.id == medicamentId);
    
    if (index >= 0) {
      if (nouvelleQuantite <= 0) {
        retirerDuPanier(medicamentId);
      } else if (nouvelleQuantite <= _panier[index].medicament.stock) {
        _panier[index].quantite = nouvelleQuantite;
        notifyListeners();
      }
    }
  }

  // Vider le panier
  void viderPanier() {
    _panier.clear();
    _pharmacieSelectionneeId = null;
    notifyListeners();
  }

  // Calculer le total du panier
  double calculerTotal() {
    double total = 0.0;
    for (var item in _panier) {
      total += item.sousTotal;
    }
    return total;
  }

  // Obtenir le nombre total d'articles
  int getNombreArticles() {
    int total = 0;
    for (var item in _panier) {
      total += item.quantite;
    }
    return total;
  }

  // Vérifier si un médicament est dans le panier
  bool estDansPanier(String medicamentId) {
    return _panier.any((item) => item.medicament.id == medicamentId);
  }

  // Obtenir la quantité d'un médicament dans le panier
  int getQuantite(String medicamentId) {
    final item = _panier.firstWhere(
      (item) => item.medicament.id == medicamentId,
      orElse: () => CartItem(
        medicament: Medicament(
          id: '',
          nom: '',
          description: '',
          prix: 0,
          imageUrl: '',
          laboratoire: '',
          stock: 0,
          pharmacieId: '',
          necessite0rdonnance: false,
          categorie: '',
          dateAjout: DateTime.now(),
        ),
        pharmacie: PharmacieModel(
          id: '',
          userId: '',
          nomPharmacie: '',
          adresse: '',
          ville: '',
          localisation: GeoPoint(0, 0),
          numeroLicense: '',
          heuresOuverture: '',
          heuresFermeture: '',
        ),
        quantite: 0,
      ),
    );
    return item.quantite;
  }

  // Vérifier si le panier contient des médicaments nécessitant une ordonnance
  bool besoinOrdonnance() {
    return _panier.any((item) => item.medicament.necessite0rdonnance);
  }

  // Obtenir la pharmacie du panier
  PharmacieModel? getPharmacie() {
    if (_panier.isNotEmpty) {
      return _panier.first.pharmacie;
    }
    return null;
  }

  // Obtenir la liste des médicaments nécessitant une ordonnance
  List<CartItem> getMedicamentsAvecOrdonnance() {
    return _panier.where((item) => item.medicament.necessite0rdonnance).toList();
  }

  // Obtenir les items du panier pour la commande
  List<ItemCommande> getItemsCommande() {
    return _panier.map((cartItem) => ItemCommande(
      medicamentId: cartItem.medicament.id,
      medicamentNom: cartItem.medicament.nom,
      prix: cartItem.medicament.prix,
      quantite: cartItem.quantite,
      necessite0rdonnance: cartItem.medicament.necessite0rdonnance,
    )).toList();
  }
}