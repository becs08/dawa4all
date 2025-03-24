import 'package:flutter/foundation.dart';

class PanierProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _produitsPanel = [];

  List<Map<String, dynamic>> get produitsPanier => _produitsPanel;

  void ajouterAuPanier(Map<String, dynamic> produit) {
    _produitsPanel.add(produit);
    notifyListeners();
  }

  void supprimerDuPanier(int index) {
    _produitsPanel.removeAt(index);
    notifyListeners();
  }

  double getTotal() {
    double total = 0;
    for (var produit in _produitsPanel) {
      total += double.parse(produit['prixNouveau'].replaceAll(' XOF', '').replaceAll(' ', ''));
    }
    return total;
  }
}