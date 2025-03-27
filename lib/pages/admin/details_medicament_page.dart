// lib/pages/admin/details_medicament_page.dart
import 'package:flutter/material.dart';
import '../../models/medicament_model.dart';
import '../../services/medicament_service.dart';

class DetailsMedicamentPage extends StatefulWidget {
  final Medicament medicament;
  final bool isAdmin;

  const DetailsMedicamentPage({
    super.key,
    required this.medicament,
    this.isAdmin = true,
  });

  @override
  _DetailsMedicamentPageState createState() => _DetailsMedicamentPageState();
}

class _DetailsMedicamentPageState extends State<DetailsMedicamentPage> {
  int _selectedIndex = 2; // Par défaut, on est dans l'onglet "Gestion"
  final MedicamentService _service = MedicamentService();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/accueil', arguments: {'isAdmin': true});
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/admin/gestion_medicaments');
        break;
    }
  }

  void _logout() {
    // Nettoyer l'authentification
    _service.clearAuth();
    // Rediriger vers la page de connexion
    Navigator.pushReplacementNamed(context, '/connexion');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicament.nom),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true, // Garder le bouton retour pour la page détail
        actions: [
          // Ajouter un bouton de déconnexion
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: widget.medicament.image.startsWith('http')
                  ? Image.network(
                widget.medicament.image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
              )
                  : Image.asset(
                widget.medicament.image,
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
                          widget.medicament.nom,
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
                            widget.medicament.categorie,
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
                          widget.medicament.prixAncien,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.medicament.prixNouveau,
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
                          'Stock disponible: ${widget.medicament.quantite}',
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
                      widget.medicament.description,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton d'édition
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/admin/editer_medicament',
                  arguments: widget.medicament,
                );
              },
              child: const Text('Modifier'),
            ),
          ),
          // Bottom Navigation Bar
          BottomNavigationBar(
            backgroundColor: Colors.green.shade900,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.greenAccent,
            unselectedItemColor: Colors.white,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Tableau de bord',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: 'Gestion',
              ),
            ],
          ),
        ],
      ),
    );
  }
}