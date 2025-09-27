import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/livreur_service.dart';
import '../../models/livreur_model.dart';
import 'livreur_details_screen.dart';

class LivreursScreen extends StatefulWidget {
  const LivreursScreen({Key? key}) : super(key: key);

  @override
  _LivreursScreenState createState() => _LivreursScreenState();
}

class _LivreursScreenState extends State<LivreursScreen> {
  final LivreurService _livreurService = LivreurService();
  List<LivreurModel> _livreurs = [];
  List<LivreurModel> _filteredLivreurs = [];
  List<String> _livreursFavoris = [];
  bool _isLoading = true;
  String _filterStatus = 'all'; // all, disponible, favori
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLivreurs();
    _loadFavoris();
  }

  Future<void> _loadLivreurs() async {
    setState(() => _isLoading = true);
    
    try {
      final livreurs = await _livreurService.getAllLivreurs();
      setState(() {
        _livreurs = livreurs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement livreurs: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFavoris() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.id != null) {
      try {
        final pharmacieDoc = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(authProvider.currentUser!.id)
            .get();
        
        if (pharmacieDoc.exists) {
          final data = pharmacieDoc.data()!;
          setState(() {
            _livreursFavoris = List<String>.from(data['livreursFavoris'] ?? []);
          });
        }
      } catch (e) {
        print('Erreur chargement favoris: $e');
      }
    }
  }

  void _applyFilters() {
    _filteredLivreurs = _livreurs.where((livreur) {
      // Filtre par statut
      bool statusMatch = true;
      switch (_filterStatus) {
        case 'disponible':
          statusMatch = livreur.estDisponible && livreur.statut == 'actif';
          break;
        case 'favori':
          statusMatch = _livreursFavoris.contains(livreur.id);
          break;
        case 'all':
        default:
          statusMatch = true;
          break;
      }

      // Filtre par recherche
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        searchMatch = livreur.nomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     livreur.telephone.contains(_searchQuery) ||
                     livreur.ville.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return statusMatch && searchMatch;
    }).toList();

    // Trier par favoris en premier, puis par note
    _filteredLivreurs.sort((a, b) {
      final aFavori = _livreursFavoris.contains(a.id);
      final bFavori = _livreursFavoris.contains(b.id);
      
      if (aFavori && !bFavori) return -1;
      if (!aFavori && bFavori) return 1;
      
      return b.note.compareTo(a.note);
    });
  }

  Future<void> _toggleFavori(String livreurId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.id == null) return;

    try {
      final isFavori = _livreursFavoris.contains(livreurId);
      
      if (isFavori) {
        _livreursFavoris.remove(livreurId);
      } else {
        _livreursFavoris.add(livreurId);
      }

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(authProvider.currentUser!.id)
          .update({
        'livreursFavoris': _livreursFavoris,
      });

      setState(() {
        _applyFilters();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavori ? 'Livreur retiré des favoris' : 'Livreur ajouté aux favoris',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nos Livreurs'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadLivreurs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un livreur...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Filtres
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip('all', 'Tous', Icons.people),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('disponible', 'Disponibles', Icons.check_circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip('favori', 'Favoris', Icons.star),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Liste des livreurs
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  )
                : _filteredLivreurs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredLivreurs.length,
                        itemBuilder: (context, index) {
                          final livreur = _filteredLivreurs[index];
                          return _buildLivreurCard(livreur);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
          _applyFilters();
        });
      },
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun livreur trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres de recherche',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurCard(LivreurModel livreur) {
    final isFavori = _livreursFavoris.contains(livreur.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LivreurDetailsScreen(livreur: livreur),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Informations
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              livreur.nomComplet,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isFavori)
                            Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            livreur.ville,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.two_wheeler,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            livreur.typeVehicule,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Statut
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(livreur),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(livreur),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Note
                          if (livreur.note > 0) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${livreur.note.toStringAsFixed(1)} (${livreur.nombreAvis})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Livraisons
                          Text(
                            '${livreur.nombreLivraisons} livraisons',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _toggleFavori(livreur.id),
                      icon: Icon(
                        isFavori ? Icons.star : Icons.star_border,
                        color: isFavori ? Colors.amber : Colors.grey,
                      ),
                    ),
                    if (livreur.estDisponible && livreur.statut == 'actif')
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Attribuer une commande
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonctionnalité d\'attribution à venir'),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Attribuer',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(LivreurModel livreur) {
    if (livreur.statut != 'actif') return Colors.grey;
    return livreur.estDisponible ? Colors.green : Colors.orange;
  }

  String _getStatusText(LivreurModel livreur) {
    switch (livreur.statut) {
      case 'en_attente_validation':
        return 'En attente';
      case 'actif':
        return livreur.estDisponible ? 'Disponible' : 'Indisponible';
      case 'suspendu':
        return 'Suspendu';
      case 'en_livraison':
        return 'En livraison';
      default:
        return 'Inconnu';
    }
  }
}