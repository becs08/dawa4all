import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dawa4all/pages/panier_provider.dart';

class ProduitPage extends StatefulWidget {
  final String nomProduit;
  final String imageProduit;
  final String prixAncien;
  final String prixNouveau;

  const ProduitPage({
    super.key,
    required this.nomProduit,
    required this.imageProduit,
    required this.prixAncien,
    required this.prixNouveau,
  });

  @override
  State<ProduitPage> createState() => _ProduitPageState();
}

class _ProduitPageState extends State<ProduitPage> {
  int quantite = 1;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Image.asset(
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
              const SizedBox(height: 16),
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
                        backgroundColor: Colors.green.shade900,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: ajouterAuPanier,
                      child: const Text(
                        'Ajouter au panier',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/panier');
                    },
                    icon: const Icon(Icons.shopping_cart),
                    color: Colors.green.shade900,
                    iconSize: 28,
                    tooltip: 'Voir le panier',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Disponible en stock',
                    style: TextStyle(
                      color: Colors.green,
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
              const Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                    'Sed diam nunc, viverra non interdum nec, aliquet luctus ligula. '
                    'Integer aliquam erat vel turpis laoreet, vel viverra erat blandit.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}