import 'package:dawa4all/pages/panier_provider.dart';
import 'package:flutter/material.dart';
import 'package:dawa4all/pages/produit_page.dart';
import 'package:provider/provider.dart';
import '../models/medicament_model.dart';
import '../services/medicament_service.dart';

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
  bool _isLoading = true;
  List<Medicament> _medicaments = [];
  final MedicamentService _service = MedicamentService();

  @override
  void initState() {
    super.initState();
    _loadMedicaments();
  }

  Future<void> _loadMedicaments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicaments = await _service.getMedicaments();
      setState(() {
        _medicaments = medicaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Ne pas afficher de message d'erreur ici, car on est dans l'initialisation
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'état admin des arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isAdmin = args?['isAdmin'] ?? false;
  }

  List<Medicament> get _filteredMedicaments {
    List<Medicament> filteredList = _medicaments;

    if (_selectedCategory != 'Tout') {
      filteredList = filteredList
          .where((medicament) => medicament.categorie == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList
          .where((medicament) => medicament.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
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
        if (_isAdmin) {
          // Pour l'admin, le deuxième onglet est "Tableau de bord"
          Navigator.pushNamed(context, '/admin/dashboard');
        } else {
          // Pour l'utilisateur, le deuxième onglet est "Liste des produits"
          Navigator.pushNamed(context, '/listeProduits', arguments: {'isAdmin': _isAdmin});
        }
        break;
      case 2:
        if (_isAdmin) {
          // Pour l'admin, le troisième onglet est "Gestion"
          Navigator.pushNamed(context, '/admin/gestion_medicaments');
        } else {
          // Pour l'utilisateur, le troisième onglet est "Panier"
          Navigator.pushNamed(context, '/panier');
        }
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/logoAccueil.png', height: 37),
            Row(
              children: [
                // Afficher le bouton panier uniquement pour les utilisateurs non-admin
                if (!_isAdmin)
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/panier');
                    },
                    icon: const Icon(Icons.shopping_cart),
                    color: Colors.green.shade900,
                  ),
                // Ajouter un bouton de déconnexion
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  color: Colors.green.shade900,
                  tooltip: 'Déconnexion',
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  if (!_isAdmin) // Ne pas afficher "Voir tout" pour l'admin
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/listeProduits', arguments: {'isAdmin': _isAdmin});
                      },
                      child: const Text(
                        '+Voir tout',
                        style: TextStyle(color: Color(0xFF1B5E20)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _filteredMedicaments.isEmpty
                  ? const Center(
                child: Text(
                  'Aucun médicament disponible',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _filteredMedicaments.length,
                itemBuilder: (context, index) {
                  final medicament = _filteredMedicaments[index];
                  return _buildProductCard(medicament);
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
          // Modifier le deuxième élément en fonction du rôle
          _isAdmin
              ? const BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Tableau de bord',
          )
              : const BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            label: 'Liste',
          ),
          // Modifier le troisième élément en fonction du rôle
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

  Widget _buildProductCard(Medicament medicament) {
    return GestureDetector(
      onTap: () {
        if (_isAdmin) {
          // Pour l'admin, naviguer vers la page de détails admin
          Navigator.pushNamed(
            context,
            '/admin/details_medicament',
            arguments: medicament,
          );
        } else {
          // Pour l'utilisateur normal
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProduitPage(
                nomProduit: medicament.nom,
                imageProduit: medicament.image,
                prixAncien: medicament.prixAncien,
                prixNouveau: medicament.prixNouveau,
                id: medicament.id,
              ),
              settings: RouteSettings(
                arguments: {'isAdmin': _isAdmin},
              ),
            ),
          );
        }
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
              child: medicament.image.startsWith('http')
                  ? Image.network(
                medicament.image,
                fit: BoxFit.cover,
                height: 120,
                width: double.infinity,
              )
                  : Image.asset(
                medicament.image,
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
                    medicament.nom,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${medicament.prixAncien} ',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: medicament.prixNouveau,
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
                  // Afficher le bouton panier uniquement pour les utilisateurs non-admin
                  if (!_isAdmin)
                    IconButton(
                      onPressed: () {
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
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      color: Colors.green.shade900,
                    ),
                  if (_isAdmin)
                    IconButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/admin/editer_medicament',
                          arguments: medicament,
                        );
                      },
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
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