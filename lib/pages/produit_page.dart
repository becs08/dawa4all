import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dawa4all/pages/panier_provider.dart';
import '../models/medicament_model.dart';
import '../services/medicament_service.dart';

class ProduitPage extends StatefulWidget {
  final String nomProduit;
  final String imageProduit;
  final String prixAncien;
  final String prixNouveau;
  final String? id; // ID du produit, optionnel

  const ProduitPage({
    super.key,
    required this.nomProduit,
    required this.imageProduit,
    required this.prixAncien,
    required this.prixNouveau,
    this.id,
  });

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  int quantite = 1;
  bool _isAdmin = false;
  final MedicamentService _service = MedicamentService();
  bool _isLoading = false;
  String? _description;
  String _categorie = 'Adulte';
  int _stockQuantite = 0;

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _loadMedicamentDetails();
    }
  }

  Future<void> _loadMedicamentDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicament = await _service.getMedicament(widget.id!);
      setState(() {
        _description = medicament.description;
        _categorie = medicament.categorie;
        _stockQuantite = medicament.quantite;
      });
    } catch (e) {
      // En cas d'erreur, on utilise les valeurs par défaut
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les détails du produit')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'état admin des arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isAdmin = args?['isAdmin'] ?? false;
  }

  void incrementerQuantite() {
    setState(() {
      quantite++;
    });
  }

  void decrementerQuantite() {
    setState(() {
      if (quantite > 1) {
        quantite--;
      }
    });
  }

  void ajouterAuPanier() {
    final panierProvider = Provider.of<PanierProvider>(context, listen: false);

    // Créer l'objet produit avec la quantité sélectionnée
    final produit = {
      'nom': widget.nomProduit,
      'image': widget.imageProduit,
      'prixAncien': widget.prixAncien,
      'prixNouveau': widget.prixNouveau,
      'quantite': quantite,
    };

    // Ajouter le produit au panier
    panierProvider.ajouterAuPanier(produit);

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.nomProduit} ajouté au panier!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Voir le panier',
          onPressed: () {
            Navigator.pushNamed(context, '/panier');
          },
        ),
      ),
    );
  }

  void modifierProduit() {
    // Créer un objet Medicament à partir des données
    final medicament = Medicament(
      id: widget.id,
      nom: widget.nomProduit,
      image: widget.imageProduit,
      prixAncien: widget.prixAncien,
      prixNouveau: widget.prixNouveau,
      categorie: _categorie,
      quantite: _stockQuantite,
      description: _description ?? 'Description non disponible',
    );

    // Naviguer vers le formulaire d'édition
    Navigator.pushNamed(
      context,
      '/admin/editer_medicament',
      arguments: medicament,
    );
  }

  Future<void> supprimerProduit() async {
    if (widget.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de supprimer ce produit')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.deleteMedicament(widget.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.nomProduit} supprimé avec succès')),
      );
      Navigator.pop(context); // Retourner à la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(
              'assets/logoAccueil.png',
              height: 37,
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    widget.imageProduit.startsWith('http')
                        ? Image.network(
                      widget.imageProduit,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      widget.imageProduit,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade900,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          '-15%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
              const SizedBox(height: 16),
              Text(
                widget.nomProduit,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    widget.prixAncien,
                    style: const TextStyle(
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.prixNouveau,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Afficher la catégorie
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _categorie,
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Afficher la quantité en stock
              Row(
                children: [
                  const Icon(Icons.inventory, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    'Stock disponible: $_stockQuantite',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Afficher la sélection de quantité uniquement pour les utilisateurs normaux
              if (!_isAdmin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantité: ',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: decrementerQuantite,
                          icon: const Icon(Icons.remove),
                          color: Colors.green.shade900,
                        ),
                        Text(
                          '$quantite',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          onPressed: incrementerQuantite,
                          icon: const Icon(Icons.add),
                          color: Colors.green.shade900,
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAdmin ? Colors.blue : Colors.green.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isAdmin ? modifierProduit : ajouterAuPanier,
                      child: Text(
                        _isAdmin ? 'Modifier le produit' : 'Ajouter au panier',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isAdmin) // Afficher le bouton panier uniquement pour les utilisateurs normaux
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/panier');
                      },
                      icon: const Icon(Icons.shopping_cart),
                      color: Colors.green.shade900,
                      iconSize: 28,
                      tooltip: 'Voir le panier',
                    ),
                  if (_isAdmin) // Afficher le bouton de suppression pour les admins
                    IconButton(
                      onPressed: () {
                        // Afficher une boîte de dialogue de confirmation
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmation'),
                            content: Text('Voulez-vous vraiment supprimer ${widget.nomProduit}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  supprimerProduit();
                                },
                                child: const Text('Supprimer'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      iconSize: 28,
                      tooltip: 'Supprimer le produit',
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _stockQuantite > 0 ? Icons.check_circle : Icons.cancel,
                    color: _stockQuantite > 0 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _stockQuantite > 0 ? 'Disponible en stock' : 'Rupture de stock',
                    style: TextStyle(
                      color: _stockQuantite > 0 ? Colors.green : Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _description ?? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Sed diam nunc, viverra non interdum nec, aliquet luctus ligula. '
                    'Integer aliquam erat vel turpis laoreet, vel viverra erat blandit.',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}