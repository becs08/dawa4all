import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dawa4all/pages/panier_provider.dart';
import '../data/medicament_data.dart';
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
      // En cas d'erreur, utiliser les données locales
      setState(() {
        _isLoading = false;
        // Les médicaments seront obtenus à partir de ListeMedicaments.medicaments
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les données depuis le serveur, utilisation des données locales.')),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Récupérer l'état admin des arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _isAdmin = args?['isAdmin'] ?? false;
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
        if (_isAdmin) {
          Navigator.pushNamed(context, '/admin/gestion_medicaments');
        } else {
          Navigator.pushNamed(context, '/panier');
        }
        break;
    }
  }

  Future<void> _supprimerMedicament(String id) async {
    try {
      await _service.deleteMedicament(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Médicament supprimé avec succès')),
      );
      _loadMedicaments(); // Recharger la liste
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les médicaments selon la recherche
    List<dynamic> produitsFiltres = [];

    if (_medicaments.isNotEmpty) {
      // Si les médicaments sont chargés depuis l'API
      produitsFiltres = _medicaments
          .where((med) => med.nom.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      // Sinon, utiliser les données locales
      produitsFiltres = ListeMedicaments.medicaments
          .where((produit) => produit['nom'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

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
                if (!_isAdmin)
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/panier');
                    },
                    icon: const Icon(Icons.shopping_cart),
                    color: Colors.green.shade900,
                  ),
                if (_isAdmin)
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin/dashboard');
                    },
                    icon: const Icon(Icons.dashboard),
                    color: Colors.green.shade900,
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
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMedicaments,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: produitsFiltres.length,
                  itemBuilder: (context, index) {
                    // Gérer à la fois les données API et locales
                    dynamic item = produitsFiltres[index];

                    // Variables pour stocker les données du produit
                    String nom, image, prixAncien, prixNouveau;
                    String? id;

                    if (item is Medicament) {
                      // Si l'item est un Medicament (depuis l'API)
                      id = item.id;
                      nom = item.nom;
                      image = item.image;
                      prixAncien = item.prixAncien;
                      prixNouveau = item.prixNouveau;
                    } else {
                      // Si l'item est un Map (depuis les données locales)
                      id = index.toString();
                      nom = item['nom'];
                      image = item['image'];
                      prixAncien = item['prixAncien'];
                      prixNouveau = item['prixNouveau'];
                    }

                    return GestureDetector(
                      onTap: () {
                        if (_isAdmin) {
                          // Pour l'admin, naviguer vers la page de détails admin
                          if (item is Medicament) {
                            Navigator.pushNamed(
                              context,
                              '/admin/details_medicament',
                              arguments: item,
                            );
                          } else {
                            // Convertir en objet Medicament
                            final medicament = Medicament(
                              id: id,
                              nom: nom,
                              image: image,
                              prixAncien: prixAncien,
                              prixNouveau: prixNouveau,
                              categorie: item['categorie'] ?? 'Adulte',
                              quantite: 0,
                              description: 'Description non disponible',
                            );
                            Navigator.pushNamed(
                              context,
                              '/admin/details_medicament',
                              arguments: medicament,
                            );
                          }
                        } else {
                          // Pour l'utilisateur normal
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProduitPage(
                                nomProduit: nom,
                                imageProduit: image,
                                prixAncien: prixAncien,
                                prixNouveau: prixNouveau,
                              ),
                              settings: RouteSettings(
                                arguments: {'isAdmin': _isAdmin},
                              ),
                            ),
                          );
                        }
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
                              image.startsWith('http')
                                  ? Image.network(
                                image,
                                height: 70,
                                width: 100,
                                fit: BoxFit.cover,
                              )
                                  : Image.asset(
                                image,
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
                                      nom,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      prixNouveau,
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
                              if (_isAdmin)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Bouton d'édition
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () {
                                        // Naviguer vers le formulaire d'édition
                                        if (item is Medicament) {
                                          Navigator.pushNamed(
                                            context,
                                            '/admin/editer_medicament',
                                            arguments: item,
                                          );
                                        } else {
                                          // Convertir en objet Medicament
                                          final medicament = Medicament(
                                            id: id,
                                            nom: nom,
                                            image: image,
                                            prixAncien: prixAncien,
                                            prixNouveau: prixNouveau,
                                            categorie: item['categorie'] ?? 'Adulte',
                                            quantite: 0,
                                            description: 'Description non disponible',
                                          );
                                          Navigator.pushNamed(
                                            context,
                                            '/admin/editer_medicament',
                                            arguments: medicament,
                                          );
                                        }
                                      },
                                    ),
                                    // Bouton de suppression
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        // Afficher une boîte de dialogue de confirmation
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirmation'),
                                            content: Text('Voulez-vous vraiment supprimer $nom?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  if (id != null && _medicaments.isNotEmpty) {
                                                    _supprimerMedicament(id);
                                                  } else {
                                                    // Simuler une suppression avec les données locales
                                                    setState(() {
                                                      ListeMedicaments.medicaments.removeAt(index);
                                                    });
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(content: Text('$nom supprimé!')),
                                                    );
                                                  }
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
                                    ),
                                  ],
                                )
                              else
                              // Bouton d'ajout au panier pour les utilisateurs normaux
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
                                        'nom': nom,
                                        'image': image,
                                        'prixAncien': prixAncien,
                                        'prixNouveau': prixNouveau,
                                        'quantite': 1,
                                      };
                                      panierProvider.ajouterAuPanier(produit);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$nom ajouté au panier!'),
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
      // Bouton flottant pour ajouter un médicament (admin uniquement)
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
        backgroundColor: Colors.green.shade900,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/admin/ajouter_medicament');
        },
      )
          : null,
    );
  }
}