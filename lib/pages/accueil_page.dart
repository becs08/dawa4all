import 'package:dawa4all/pages/panier_provider.dart';
import 'package:flutter/material.dart';
import 'package:dawa4all/pages/produit_page.dart';
import 'package:provider/provider.dart';

import '../data/populaire_data.dart';

class AccueilPage extends StatefulWidget {
  const AccueilPage({super.key});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> {
  int _selectedIndex = 0;
  String _selectedCategory = 'Tout';
  String _searchQuery = '';
  bool _isAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'état admin des arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isAdmin = args?['isAdmin'] ?? false;
  }

  List<Map<String, String>> get _filteredProduits {
    List<Map<String, String>> filteredList = PopulairePage.produitsPopulaires;

    if (_selectedCategory != 'Tout') {
      filteredList = filteredList
          .where((produit) => produit['categorie'] == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((produit) => produit['nom']!.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filteredList;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 1:
        Navigator.pushNamed(context, '/listeProduits', arguments: {'isAdmin': _isAdmin});
        break;
      case 2:
        if (_isAdmin) {
          Navigator.pushNamed(context, '/admin/gestion_medicaments');
        } else {
          Navigator.pushNamed(context, '/panier');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/logoAccueil.png', height: 37),
            Row(
              children: [
                /*IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite),
                  color: Colors.green.shade900,
                ),*/
                IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/panier');
                  },
                  icon: const Icon(Icons.shopping_cart),
                  color: Colors.green.shade900,
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher des produits',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Catégories
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catégories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryButton('Tout', Icons.add),
                  _buildCategoryButton('Adulte', Icons.medical_services),
                  _buildCategoryButton('Enfant', Icons.child_care),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Produits populaires',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/listeProduits');
                    },
                    child: const Text(
                      '+Voir tout',
                      style: TextStyle(color: Color(0xFF1B5E20)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _filteredProduits.length,
                itemBuilder: (context, index) {
                  final produit = _filteredProduits[index];
                  return _buildProductCard(produit);
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade900,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            label: 'Liste',
          ),
          _isAdmin
              ? const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Gestion',
          )
              : const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, IconData icon) {
    final isSelected = _selectedCategory == label;
    return Expanded(
      child: Column(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.green.shade900 : Colors.white,
              side: const BorderSide(color: Color(0xFF1B5E20)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(15),
            ),
            onPressed: () {
              setState(() {
                _selectedCategory = label;
              });
            },
            child: Icon(icon, color: isSelected ? Colors.white : Colors.green.shade900),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, String> produit) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProduitPage(
              nomProduit: produit['nom']!,
              imageProduit: produit['image']!,
              prixAncien: produit['prixAncien']!,
              prixNouveau: produit['prixNouveau']!,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.green.shade900, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 5,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                produit['image']!,
                fit: BoxFit.cover,
                height: 120,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 2,
                    color: Colors.green.shade900,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  Text(
                    produit['nom']!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${produit['prixAncien']!} ',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: produit['prixNouveau']!,
                          style: const TextStyle(
                            color: Color(0xFF1B5E20),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      final panierProvider = Provider.of<PanierProvider>(context, listen: false);
                      panierProvider.ajouterAuPanier(produit);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${produit['nom']} ajouté au panier!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart),
                    color: Colors.green.shade900,
                  ),
                ],
              ),
            ),
          ],

        ),
      ),
    );
  }
}
