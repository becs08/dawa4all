// lib/pages/admin/details_medicament_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicament_model.dart';
import '../panier_provider.dart';

class DetailsMedicamentPage extends StatelessWidget {
  final Medicament medicament;
  final bool isAdmin;

  const DetailsMedicamentPage({
    Key? key,
    required this.medicament,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicament.nom),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: medicament.image.startsWith('http')
                  ? Image.network(
                medicament.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              )
                  : Image.asset(
                medicament.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          medicament.nom,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            medicament.categorie,
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          medicament.prixAncien,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          medicament.prixNouveau,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Icon(Icons.inventory, color: Colors.blue),
                        const SizedBox(width: 10),
                        Text(
                          'Stock disponible: ${medicament.quantite}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      medicament.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isAdmin
            ? ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/admin/editer_medicament',
              arguments: medicament,
            );
          },
          child: const Text('Modifier'),
        )
            : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade900,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
          onPressed: () {
            // Logique pour ajouter au panier
            final panierProvider = Provider.of<PanierProvider>(context, listen: false);

            final produit = {
              'nom': medicament.nom,
              'image': medicament.image,
              'prixAncien': medicament.prixAncien,
              'prixNouveau': medicament.prixNouveau,
              'quantite': 1,
            };

            panierProvider.ajouterAuPanier(produit);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${medicament.nom} ajouté au panier!'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Ajouter au panier'),
        ),
      ),
    );
  }
}