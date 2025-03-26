import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dawa4all/pages/panier_provider.dart';
import '../models/medicament_model.dart';
import '../services/medicament_service.dart';
import 'produit_page.dart';

class ListeProduitsPage extends StatefulWidget {
  @override
  _ListeProduitsPageState createState() => _ListeProduitsPageState();
}

class _ListeProduitsPageState extends State<ListeProduitsPage> {
  int _selectedIndex = 1;
  String query = "";
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
      // Essayer de charger les médicaments depuis l'API
      final medicaments = await _service.getMedicaments();
      setState(() {
        _medicaments = medicaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les données depuis le serveur.')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'état admin des arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isAdmin = args?['isAdmin'] ?? false;

    // Si c'est un admin, rediriger vers le tableau de bord
    if (_isAdmin) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/accueil', arguments: {'isAdmin': _isAdmin});
        break;
      case 2:
        Navigator.pushNamed(context, '/panier');
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
    // Si admin, ne pas afficher cette page
    if (_isAdmin) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Filtrer les médicaments selon la recherche
    List<Medicament> medicamentsFiltres = _medicaments
        .where((med) => med.nom.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/logoAccueil.png', height: 37),
            Row(
              children: [
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                hintText: 'Rechercher un produit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.green.shade900),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (medicamentsFiltres.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Aucun médicament trouvé',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMedicaments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: medicamentsFiltres.length,
                  itemBuilder: (context, index) {
                    final medicament = medicamentsFiltres[index];

                    return GestureDetector(
                      onTap: () {
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
                      },
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              medicament.image.startsWith('http')
                                  ? Image.network(
                                medicament.image,
                                height: 70,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                medicament.image,
                                height: 70,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      medicament.nom,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      medicament.prixNouveau,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bouton d'ajout au panier
                              SizedBox(
                                height: 35,
                                width: 35,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade900,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  onPressed: () {
                                    final panierProvider = Provider.of<PanierProvider>(context, listen: false);
                                    // Créer un Map pour l'ajouter au panier
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
                                  child: const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade900,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            label: 'Liste',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Panier',
          ),
        ],
      ),
    );
  }
}