import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/panier_provider.dart';
import '../../services/firebase/client_service.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../services/location_service.dart';
import '../../models/pharmacie_model.dart';
import '../../utils/test_data_utils.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key}) : super(key: key);

  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final ClientService _clientService = ClientService();
  final PharmacieService _pharmacieService = PharmacieService();
  final TextEditingController _searchController = TextEditingController();
  
  List<PharmacieModel> _pharmaciesProches = [];
  List<Map<String, dynamic>> _resultatsRecherche = [];
  List<Map<String, dynamic>> _medicamentsPopulaires = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isLoadingMedicaments = false;
  Position? _currentPosition;
  String _selectedCategory = 'Tous';
  
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Tous', 'icon': Icons.all_inclusive, 'color': Colors.blue},
    {'name': 'Antibiotiques', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Antalgiques', 'icon': Icons.healing, 'color': Colors.orange},
    {'name': 'Vitamines', 'icon': Icons.energy_savings_leaf, 'color': Colors.green},
    {'name': 'Digestif', 'icon': Icons.restaurant, 'color': Colors.purple},
    {'name': 'Respiratoire', 'icon': Icons.air, 'color': Colors.cyan},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMedicamentsPopulaires();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Essayer d'obtenir la position avec un timeout raisonnable
      _currentPosition = await LocationService.getCurrentPosition()
          .timeout(const Duration(seconds: 12));
      
      if (_currentPosition != null) {
        print('🎯 Utilisation de la position GPS réelle: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
        await _loadPharmaciesProches();
      } else {
        print('❌ Position null après timeout');
        _showLocationPermissionDialog();
      }
    } catch (e) {
      if (e is CustomLocationServiceDisabledException) {
        _showLocationServiceDialog();
      } else if (e is CustomLocationPermissionException) {
        _showLocationPermissionDialog();
      } else {
        print('❌ Erreur géolocalisation: $e');
        
        // En cas d'erreur, utiliser une position par défaut (Dakar)
        _currentPosition = Position(
          latitude: 14.7167,
          longitude: -17.4677,
          timestamp: DateTime.now(),
          accuracy: 1000,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        
        print('📍 Utilisation position par défaut: Dakar (${_currentPosition!.latitude}, ${_currentPosition!.longitude})');
        await _loadPharmaciesProches();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Position par défaut utilisée (Dakar). Activez la géolocalisation pour une meilleure précision.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _loadPharmaciesProches() async {
    if (_currentPosition != null) {
      print('🏥 === RECHERCHE PHARMACIES PROCHES ===');
      print('📍 Position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      try {
        // Chercher les 3 pharmacies les plus proches
        final pharmacies = await _pharmacieService.getPharmaciesProches(
          _currentPosition!,
          3, // Limiter à 3 pharmacies
        );
        
        print('🏥 Les ${pharmacies.length} pharmacies les plus proches trouvées:');
        for (var pharmacie in pharmacies) {
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            pharmacie.localisation.latitude,
            pharmacie.localisation.longitude,
          ) / 1000;
          print('  - ${pharmacie.nomPharmacie}: ${distance.toStringAsFixed(2)}km - ${pharmacie.statutTexte}');
        }
        
        if (mounted) {
          setState(() {
            _pharmaciesProches = pharmacies;
          });
        }
        
        // Si aucune pharmacie proche, créer des données de test à proximité
        if (pharmacies.isEmpty) {
          print('⚠️ Aucune pharmacie proche trouvée, création de pharmacies de test à proximité...');
          await _createTestDataWithLocation();
        }
        
      } catch (e) {
        print('❌ Erreur chargement pharmacies: $e');
        // En cas d'erreur, créer automatiquement des données de test
        if (mounted) {
          await _createTestDataWithLocation();
        }
      }
    } else {
      print('❌ Aucune position disponible pour chercher les pharmacies');
    }
  }
  
  Future<void> _loadMedicamentsPopulaires() async {
    setState(() {
      _isLoadingMedicaments = true;
    });
    
    try {
      // Charger les médicaments depuis Firebase
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      QuerySnapshot snapshot = await firestore
          .collection('medicaments')
          .where('estDisponible', isEqualTo: true)
          .limit(20) // Limiter pour la performance
          .get();
      
      List<Map<String, dynamic>> medicaments = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Filtrer par catégorie si une catégorie est sélectionnée
        if (_selectedCategory != 'Toutes') {
          final categorie = data['categorie']?.toString().toLowerCase() ?? '';
          final selectedCat = _selectedCategory.toLowerCase();
          
          // Vérifier si la catégorie correspond
          if (selectedCat == 'antibiotiques' && categorie != 'antibiotiques') continue;
          if (selectedCat == 'antalgiques' && categorie != 'antalgiques') continue;
          if (selectedCat == 'vitamines' && categorie != 'vitamines') continue;
          if (selectedCat == 'digestif' && categorie != 'digestif') continue;
        }
        
        medicaments.add({
          'id': doc.id,
          'nom': data['nom'] ?? 'Médicament',
          'prix': (data['prix'] ?? 0).toDouble(),
          'image': data['imageUrl'] ?? 'https://via.placeholder.com/150/4CAF50/FFFFFF?text=Med',
          'category': data['categorie'] ?? 'Autre',
          'ordonnance': data['necessite0rdonnance'] ?? false,
          'pharmacieId': data['pharmacieId'] ?? '',
        });
      }
      
      if (mounted) {
        setState(() {
          _medicamentsPopulaires = medicaments;
        });
      }
    } catch (e) {
      print('Erreur chargement médicaments: $e');
    }
    
    if (mounted) {
      setState(() {
        _isLoadingMedicaments = false;
      });
    }
  }

  Future<void> _rechercherMedicament(String query) async {
    if (query.isEmpty) {
      setState(() {
        _resultatsRecherche = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final resultats = await _clientService.rechercherMedicament(query);
      setState(() {
        _resultatsRecherche = resultats;
      });
    } catch (e) {
      print('Erreur recherche: $e');
    }

    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          // Menu profil
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Naviguer vers le profil
                  break;
                case 'orders':
                  Navigator.pushNamed(context, '/client/orders');
                  break;
                case 'test_data':
                  _createTestData();
                  break;
                case 'fix_data':
                  _fixMissingFields();
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Mon profil'),
                ),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Mes commandes'),
                ),
              ),
              const PopupMenuItem(
                value: 'test_data',
                child: ListTile(
                  leading: Icon(Icons.science),
                  title: Text('Créer données test'),
                ),
              ),
              const PopupMenuItem(
                value: 'fix_data',
                child: ListTile(
                  leading: Icon(Icons.build),
                  title: Text('Corriger pharmacies'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message de bienvenue
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.waving_hand,
                          color: Color(0xFF2E7D32),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour ${authProvider.currentUser?.nom ?? ""}!',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'Trouvez vos médicaments facilement',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Barre de recherche
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _rechercherMedicament,
            ),
            const SizedBox(height: 20),

            // Résultats de recherche ou contenu principal
            if (_resultatsRecherche.isNotEmpty) ...[
              const Text(
                'Résultats de la recherche',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _resultatsRecherche.length,
                itemBuilder: (context, index) {
                  final resultat = _resultatsRecherche[index];
                  return _buildMedicamentCard(resultat);
                },
              ),
            ] else if (_searchController.text.isNotEmpty && !_isSearching) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Aucun médicament trouvé',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Contenu principal
              _buildMainContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Statistiques rapides
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_pharmacy,
                title: 'Pharmacies',
                value: _pharmaciesProches.length.toString(),
                subtitle: 'proches',
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.medication,
                title: 'Médicaments',
                value: _medicamentsPopulaires.length.toString(),
                subtitle: 'populaires',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                title: 'Ouvertes',
                value: _pharmaciesProches.where((p) => p.estOuverteActuellement).length.toString(),
                subtitle: '24h/24',
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Catégories
        const Text(
          'Catégories',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = category['name'];
                  });
                  _loadMedicamentsPopulaires(); // Recharger avec le filtre
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? category['color'] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: category['color'],
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: category['color'].withOpacity(0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        color: isSelected ? Colors.white : category['color'],
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category['name'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : category['color'],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Médicaments populaires
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Médicaments populaires',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/client/pharmacies');
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingMedicaments)
          const Center(
            child: CircularProgressIndicator(),
          )
        else
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _medicamentsPopulaires.length,
              itemBuilder: (context, index) {
                return _buildMedicamentPopulaireCard(_medicamentsPopulaires[index]);
              },
            ),
          ),
        const SizedBox(height: 24),

        // Actions rapides
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.local_pharmacy,
                title: 'Pharmacies',
                subtitle: 'Toutes les pharmacies',
                onTap: () {
                  Navigator.pushNamed(context, '/client/pharmacies');
                },
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.emergency,
                title: 'Urgence',
                subtitle: 'Pharmacies de garde',
                onTap: () {
                  _showUrgenceDialog();
                },
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Pharmacies proches
        const Text(
          'Pharmacies proches de vous',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoadingLocation) ...[
          const Center(
            child: CircularProgressIndicator(),
          ),
        ] else if (_currentPosition == null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Localisation non disponible',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Activez la géolocalisation pour voir les pharmacies proches',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _getCurrentLocation,
                    child: const Text('Activer'),
                  ),
                ],
              ),
            ),
          ),
        ] else if (_pharmaciesProches.isNotEmpty) ...[
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 4),
              itemBuilder: (context, index) {
                return _buildPharmacieCard(_pharmaciesProches[index]);
              },
              itemCount: _pharmaciesProches.length,
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.local_pharmacy_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucune pharmacie proche',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Il n\'y a pas de pharmacies dans un rayon de 10km. Créez des données de test ou consultez toutes les pharmacies.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _createTestData,
                        child: const Text('Données test'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/client/pharmacies');
                        },
                        child: const Text('Voir toutes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 9,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicamentPopulaireCard(Map<String, dynamic> medicament) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Créer un medicament fictif pour la navigation
            // TODO: Remplacer par de vrais objets Medicament depuis Firebase
            Navigator.pushNamed(
              context,
              '/client/medicament-details',
              arguments: {
                'medicament': medicament, // C'est pour l'instant un Map, il faudra le convertir
                'pharmacie': null, // Pas de pharmacie spécifique pour les médicaments populaires
              },
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du médicament
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Container(
                  height: 80,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.network(
                    medicament['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.medication,
                        size: 40,
                        color: Colors.grey[400],
                      );
                    },
                  ),
                ),
              ),
              // Informations
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicament['nom'],
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (medicament['ordonnance'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Ordonnance',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${medicament['prix']} FCFA',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PharmacieModel pharmacie) {
    switch (pharmacie.couleurStatut) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPharmacieCard(PharmacieModel pharmacie) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/client/pharmacy-details',
              arguments: pharmacie,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_pharmacy,
                      color: const Color(0xFF2E7D32),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pharmacie.nomPharmacie,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    pharmacie.adresse,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(pharmacie),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    pharmacie.statutTexte,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pharmacie.note.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildMedicamentCard(Map<String, dynamic> resultat) {
    return Card(
      child: ListTile(
        title: Text(resultat['medicament'].nom),
        subtitle: Text(resultat['pharmacie'].nomPharmacie),
        trailing: Text('${resultat['medicament'].prix} FCFA'),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/client/medicament-details',
            arguments: {
              'medicament': resultat['medicament'],
              'pharmacie': resultat['pharmacie'],
            },
          );
        },
      ),
    );
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Service de localisation'),
          content: const Text('Veuillez activer le service de localisation pour voir les pharmacies proches de vous.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission de localisation'),
          content: const Text('L\'autorisation de localisation est nécessaire pour trouver les pharmacies proches de vous.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Méthode pour corriger les champs manquants dans les pharmacies existantes  
  Future<void> _fixMissingFields() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔧 Correction des champs manquants en cours...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final success = await _pharmacieService.corrigerChampsManquants();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Correction des pharmacies terminée !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Recharger les pharmacies
        await _loadPharmaciesProches();
        setState(() {});
      } else {
        throw Exception('Erreur lors de la correction');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la correction: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _createTestData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🧪 Création des données de test en cours...'),
          backgroundColor: Colors.blue,
        ),
      );

      await _createCompleteTestData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Données de test créées avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Recharger les données
      await _loadPharmaciesProches();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createTestDataSilently() async {
    try {
      await TestDataUtils.createAllTestData();
      await _loadPharmaciesProches();
    } catch (e) {
      print('Erreur création données test: $e');
    }
  }

  Future<void> _createTestDataWithLocation() async {
    if (_currentPosition == null) return;
    
    try {
      print('🧪 Création de pharmacies de test près de votre position...');
      
      // Créer des pharmacies à proximité de la position actuelle
      final pharmaciesTestData = [
        {
          'nomPharmacie': 'Pharmacie du Centre',
          'adresse': 'Centre-ville, près de vous',
          'telephone': '+221701234567',
          'email': 'centre@pharmacie.sn',
          'latitude': _currentPosition!.latitude + 0.01, // ~1km
          'longitude': _currentPosition!.longitude + 0.01,
          'estOuverte': true,
          'note': 4.5,
          'horairesOuverture': '08:00-20:00',
          'horaires24h': false,
          'joursGarde': ['lundi', 'mercredi'],
        },
        {
          'nomPharmacie': 'Pharmacie Express',
          'adresse': 'Avenue principale, à proximité',
          'telephone': '+221701234568',
          'email': 'express@pharmacie.sn',
          'latitude': _currentPosition!.latitude - 0.02, // ~2km
          'longitude': _currentPosition!.longitude + 0.015,
          'estOuverte': true,
          'note': 4.2,
          'horairesOuverture': '07:00-22:00',
          'horaires24h': false,
          'joursGarde': ['mardi', 'vendredi'],
        },
        {
          'nomPharmacie': 'Pharmacie 24h',
          'adresse': 'Rond-point, service continu',
          'telephone': '+221701234569',
          'email': '24h@pharmacie.sn',
          'latitude': _currentPosition!.latitude + 0.005, // ~500m
          'longitude': _currentPosition!.longitude - 0.008,
          'estOuverte': true,
          'note': 4.8,
          'horairesOuverture': '24h/24',
          'horaires24h': true,
          'joursGarde': ['dimanche'],
        },
      ];

      // Ajouter les pharmacies à Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      
      for (var pharmacieData in pharmaciesTestData) {
        final dataToSave = {
          'userId': 'test_user_pharmacie',
          'nomPharmacie': pharmacieData['nomPharmacie'],
          'adresse': pharmacieData['adresse'],
          'ville': 'Dakar',
          'telephone': pharmacieData['telephone'],
          'email': pharmacieData['email'],
          'localisation': GeoPoint(
            pharmacieData['latitude'] as double,
            pharmacieData['longitude'] as double,
          ),
          'numeroLicense': 'LIC${DateTime.now().millisecondsSinceEpoch}',
          'heuresOuverture': '08:00',
          'heuresFermeture': '20:00',
          'horairesOuverture': pharmacieData['horairesOuverture'],
          'horaires24h': pharmacieData['horaires24h'],
          'joursGarde': pharmacieData['joursGarde'],
          'note': pharmacieData['note'],
          'nombreAvis': 15,
          'estOuverte': pharmacieData['estOuverte'],
          'photoUrl': null,
          'horairesDetailles': {
            'lundi': '08:00-20:00',
            'mardi': '08:00-20:00',
            'mercredi': '08:00-20:00',
            'jeudi': '08:00-20:00',
            'vendredi': '08:00-20:00',
            'samedi': '08:00-18:00',
            'dimanche': pharmacieData['horaires24h'] == true ? '24h/24' : 'Fermé',
          },
          'updated_v2': true, // Flag pour éviter la boucle infinie
          'dateCreation': Timestamp.now(),
        };
        
        print('💾 Sauvegarde pharmacie ${pharmacieData['nomPharmacie']} avec joursGarde: ${pharmacieData['joursGarde']}');
        print('📋 Données complètes à sauvegarder: ${dataToSave.keys.toList()}');
        print('📋 JoursGarde dans dataToSave: ${dataToSave['joursGarde']}');
        print('📋 HorairesOuverture dans dataToSave: ${dataToSave['horairesOuverture']}');
        
        final docRef = await firestore.collection('pharmacies').add(dataToSave);
        print('✅ Document créé avec ID: ${docRef.id}');
      }
      
      print('✅ ${pharmaciesTestData.length} pharmacies de test créées avec succès !');
      
      // Créer également quelques médicaments de test
      await TestDataUtils.createAllTestData();
      
      // Recharger les pharmacies proches
      await Future.delayed(const Duration(seconds: 1)); // Attendre que Firestore se synchronise
      await _loadPharmaciesProches();
      
    } catch (e) {
      print('❌ Erreur création pharmacies test avec localisation: $e');
    }
  }

  Future<void> _cleanAndRecreateTestData() async {
    if (_currentPosition == null) return;
    
    try {
      print('🧹 Nettoyage des anciennes données...');
      
      // Supprimer toutes les anciennes pharmacies
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('pharmacies').get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print('🗑️ Supprimé: ${doc.data()['nomPharmacie'] ?? 'Pharmacie'}');
      }
      
      print('✅ Anciennes données supprimées');
      
      // Recréer avec les bons champs
      await _createTestDataWithLocation();
      
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  Future<void> _createCompleteTestData() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    
    print('🚀 Création de données complètes...');
    
    // 1. Créer des pharmacies complètes avec tous les champs
    final pharmaciesData = [
      {
        'userId': 'user_pharmacie_1',
        'nomPharmacie': 'Pharmacie du Centre',
        'adresse': '15 Avenue Bourguiba',
        'ville': 'Dakar',
        'telephone': '+221773456789',
        'email': 'centre@pharmacie.sn',
        'latitude': 14.7167 + (math.Random().nextDouble() - 0.5) * 0.02,
        'longitude': -17.4677 + (math.Random().nextDouble() - 0.5) * 0.02,
        'numeroLicense': 'PH001',
        'heuresOuverture': '08:00',
        'heuresFermeture': '20:00',
        'horairesOuverture': '08:00-20:00',
        'horaires24h': false,
        'joursGarde': ['lundi', 'jeudi'],
        'note': 4.5,
        'nombreAvis': 25,
        'estOuverte': true,
        'photoUrl': null,
        'horairesDetailles': {
          'lundi': '08:00-20:00',
          'mardi': '08:00-20:00', 
          'mercredi': '08:00-20:00',
          'jeudi': '08:00-20:00',
          'vendredi': '08:00-20:00',
          'samedi': '08:00-18:00',
          'dimanche': 'Fermé',
        },
      },
      {
        'userId': 'user_pharmacie_2',
        'nomPharmacie': 'Pharmacie Express',
        'adresse': '67 Rue de la Paix',
        'ville': 'Dakar',
        'telephone': '+221776543210',
        'email': 'express@pharmacie.sn',
        'latitude': 14.7167 + (math.Random().nextDouble() - 0.5) * 0.02,
        'longitude': -17.4677 + (math.Random().nextDouble() - 0.5) * 0.02,
        'numeroLicense': 'PH002',
        'heuresOuverture': '07:00',
        'heuresFermeture': '22:00',
        'horairesOuverture': '07:00-22:00',
        'horaires24h': false,
        'joursGarde': ['mardi', 'vendredi'],
        'note': 4.2,
        'nombreAvis': 18,
        'estOuverte': true,
        'photoUrl': null,
        'horairesDetailles': {
          'lundi': '07:00-22:00',
          'mardi': '07:00-22:00',
          'mercredi': '07:00-22:00',
          'jeudi': '07:00-22:00',
          'vendredi': '07:00-22:00',
          'samedi': '07:00-20:00',
          'dimanche': 'Fermé',
        },
      },
      {
        'userId': 'user_pharmacie_3',
        'nomPharmacie': 'Pharmacie 24h Plateau',
        'adresse': '12 Place de l\'Indépendance',
        'ville': 'Dakar',
        'telephone': '+221789012345',
        'email': '24h@pharmacie.sn',
        'latitude': 14.7167 + (math.Random().nextDouble() - 0.5) * 0.02,
        'longitude': -17.4677 + (math.Random().nextDouble() - 0.5) * 0.02,
        'numeroLicense': 'PH003',
        'heuresOuverture': '00:00',
        'heuresFermeture': '23:59',
        'horairesOuverture': '24h/24',
        'horaires24h': true,
        'joursGarde': ['dimanche'],
        'note': 4.8,
        'nombreAvis': 42,
        'estOuverte': true,
        'photoUrl': null,
        'horairesDetailles': {
          'lundi': '24h/24',
          'mardi': '24h/24',
          'mercredi': '24h/24', 
          'jeudi': '24h/24',
          'vendredi': '24h/24',
          'samedi': '24h/24',
          'dimanche': '24h/24',
        },
      },
      {
        'userId': 'user_pharmacie_4',
        'nomPharmacie': 'Pharmacie de la Médina',
        'adresse': '89 Rue 25',
        'ville': 'Dakar',
        'telephone': '+221798765432',
        'email': 'medina@pharmacie.sn',
        'latitude': 14.7167 + (math.Random().nextDouble() - 0.5) * 0.02,
        'longitude': -17.4677 + (math.Random().nextDouble() - 0.5) * 0.02,
        'numeroLicense': 'PH004',
        'heuresOuverture': '08:30',
        'heuresFermeture': '19:30',
        'horairesOuverture': '08:30-19:30',
        'horaires24h': false,
        'joursGarde': ['mercredi', 'samedi'],
        'note': 4.1,
        'nombreAvis': 16,
        'estOuverte': true,
        'photoUrl': null,
        'horairesDetailles': {
          'lundi': '08:30-19:30',
          'mardi': '08:30-19:30',
          'mercredi': '08:30-19:30',
          'jeudi': '08:30-19:30',
          'vendredi': '08:30-19:30',
          'samedi': '08:30-17:00',
          'dimanche': 'Fermé',
        },
      },
    ];

    final List<String> pharmacieIds = [];

    // Créer les pharmacies
    for (var pharmacieData in pharmaciesData) {
      final docRef = await firestore.collection('pharmacies').add({
        'userId': pharmacieData['userId'],
        'nomPharmacie': pharmacieData['nomPharmacie'],
        'adresse': pharmacieData['adresse'],
        'ville': pharmacieData['ville'],
        'telephone': pharmacieData['telephone'],
        'email': pharmacieData['email'],
        'localisation': GeoPoint(
          pharmacieData['latitude'] as double,
          pharmacieData['longitude'] as double,
        ),
        'numeroLicense': pharmacieData['numeroLicense'],
        'heuresOuverture': pharmacieData['heuresOuverture'],
        'heuresFermeture': pharmacieData['heuresFermeture'],
        'horairesOuverture': pharmacieData['horairesOuverture'],
        'horaires24h': pharmacieData['horaires24h'],
        'joursGarde': pharmacieData['joursGarde'],
        'note': pharmacieData['note'],
        'nombreAvis': pharmacieData['nombreAvis'],
        'estOuverte': pharmacieData['estOuverte'],
        'photoUrl': pharmacieData['photoUrl'],
        'horairesDetailles': pharmacieData['horairesDetailles'],
        'dateCreation': Timestamp.now(),
      });
      
      pharmacieIds.add(docRef.id);
      print('✅ Pharmacie créée: ${pharmacieData['nomPharmacie']} (ID: ${docRef.id})');
    }

    // 2. Créer des médicaments complets avec catégories
    final medicamentsData = [
      // Antibiotiques
      {
        'nom': 'Amoxicilline 500mg',
        'description': 'Antibiotique à large spectre pour infections bactériennes',
        'prix': 2500.0,
        'imageUrl': 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Amoxicilline',
        'laboratoire': 'Pfizer',
        'stock': 50,
        'categorie': 'antibiotiques',
        'necessite0rdonnance': true,
        'estDisponible': true,
        'dosage': '500mg',
        'formePharmaceutique': 'Comprimés',
        'dateExpiration': DateTime.now().add(const Duration(days: 730)),
        'modeEmploi': 'Prendre 1 comprimé 3 fois par jour pendant 7 jours',
        'contreIndications': ['Allergie à la pénicilline', 'Insuffisance rénale sévère'],
      },
      {
        'nom': 'Azithromycine 250mg',
        'description': 'Antibiotique macrolide pour infections respiratoires',
        'prix': 3200.0,
        'imageUrl': 'https://via.placeholder.com/300x200/2196F3/FFFFFF?text=Azithromycine',
        'laboratoire': 'Sanofi',
        'stock': 30,
        'categorie': 'antibiotiques', 
        'necessite0rdonnance': true,
        'estDisponible': true,
        'dosage': '250mg',
        'formePharmaceutique': 'Comprimés',
        'dateExpiration': DateTime.now().add(const Duration(days: 700)),
        'modeEmploi': 'Prendre 1 comprimé par jour pendant 5 jours',
        'contreIndications': ['Troubles hépatiques', 'Arythmie cardiaque'],
      },
      // Antalgiques
      {
        'nom': 'Paracétamol 1000mg',
        'description': 'Antalgique et antipyrétique pour douleurs et fièvre',
        'prix': 800.0,
        'imageUrl': 'https://via.placeholder.com/300x200/FF9800/FFFFFF?text=Paracetamol',
        'laboratoire': 'Doliprane',
        'stock': 100,
        'categorie': 'antalgiques',
        'necessite0rdonnance': false,
        'estDisponible': true,
        'dosage': '1000mg',
        'formePharmaceutique': 'Comprimés effervescents',
        'dateExpiration': DateTime.now().add(const Duration(days: 800)),
        'modeEmploi': 'Dissoudre 1 comprimé dans un verre d\'eau, 3 fois par jour',
        'contreIndications': ['Insuffisance hépatique', 'Allergie au paracétamol'],
      },
      {
        'nom': 'Ibuprofène 400mg',
        'description': 'Anti-inflammatoire non stéroïdien contre douleurs et inflammation',
        'prix': 1200.0,
        'imageUrl': 'https://via.placeholder.com/300x200/E91E63/FFFFFF?text=Ibuprofene',
        'laboratoire': 'Advil',
        'stock': 75,
        'categorie': 'antalgiques',
        'necessite0rdonnance': false,
        'estDisponible': true,
        'dosage': '400mg',
        'formePharmaceutique': 'Comprimés',
        'dateExpiration': DateTime.now().add(const Duration(days: 850)),
        'modeEmploi': 'Prendre 1 comprimé 2 à 3 fois par jour avec les repas',
        'contreIndications': ['Ulcère gastrique', 'Insuffisance cardiaque', 'Grossesse'],
      },
      // Vitamines
      {
        'nom': 'Vitamine C 500mg',
        'description': 'Complément vitaminique pour renforcer les défenses immunitaires',
        'prix': 1500.0,
        'imageUrl': 'https://via.placeholder.com/300x200/4CAF50/FFFFFF?text=Vitamine+C',
        'laboratoire': 'Bayer',
        'stock': 60,
        'categorie': 'vitamines',
        'necessite0rdonnance': false,
        'estDisponible': true,
        'dosage': '500mg',
        'formePharmaceutique': 'Comprimés à croquer',
        'dateExpiration': DateTime.now().add(const Duration(days: 900)),
        'modeEmploi': 'Croquer 1 comprimé par jour de préférence le matin',
        'contreIndications': ['Calculs rénaux', 'Hémochromatose'],
      },
      {
        'nom': 'Complexe Vitamine B',
        'description': 'Association de vitamines B pour le système nerveux',
        'prix': 2200.0,
        'imageUrl': 'https://via.placeholder.com/300x200/9C27B0/FFFFFF?text=Vitamine+B',
        'laboratoire': 'Roche',
        'stock': 40,
        'categorie': 'vitamines',
        'necessite0rdonnance': false,
        'estDisponible': true,
        'dosage': 'Complexe B',
        'formePharmaceutique': 'Gélules',
        'dateExpiration': DateTime.now().add(const Duration(days: 750)),
        'modeEmploi': 'Prendre 1 gélule par jour au cours d\'un repas',
        'contreIndications': ['Hypersensibilité aux vitamines B'],
      },
      // Digestifs
      {
        'nom': 'Smecta sachets',
        'description': 'Traitement symptomatique de la diarrhée et des douleurs abdominales',
        'prix': 1800.0,
        'imageUrl': 'https://via.placeholder.com/300x200/795548/FFFFFF?text=Smecta',
        'laboratoire': 'Ipsen',
        'stock': 45,
        'categorie': 'digestif',
        'necessite0rdonnance': false,
        'estDisponible': true,
        'dosage': '3g',
        'formePharmaceutique': 'Poudre en sachet',
        'dateExpiration': DateTime.now().add(const Duration(days: 600)),
        'modeEmploi': 'Diluer 1 sachet dans un verre d\'eau, 3 fois par jour',
        'contreIndications': ['Occlusion intestinale', 'Constipation chronique'],
      },
      // Respiratoires
      {
        'nom': 'Ventoline spray',
        'description': 'Bronchodilatateur pour traitement de l\'asthme et BPCO',
        'prix': 4500.0,
        'imageUrl': 'https://via.placeholder.com/300x200/03A9F4/FFFFFF?text=Ventoline',
        'laboratoire': 'GSK',
        'stock': 25,
        'categorie': 'respiratoire',
        'necessite0rdonnance': true,
        'estDisponible': true,
        'dosage': '100µg/dose',
        'formePharmaceutique': 'Spray inhalateur',
        'dateExpiration': DateTime.now().add(const Duration(days: 650)),
        'modeEmploi': 'Inhaler 1 à 2 bouffées selon les besoins',
        'contreIndications': ['Hypersensibilité au salbutamol', 'Tachycardie'],
      },
    ];

    // Créer les médicaments pour chaque pharmacie
    for (String pharmacieId in pharmacieIds) {
      for (var medicamentData in medicamentsData) {
        await firestore.collection('medicaments').add({
          'pharmacieId': pharmacieId,
          'nom': medicamentData['nom'],
          'description': medicamentData['description'],
          'prix': medicamentData['prix'],
          'imageUrl': medicamentData['imageUrl'],
          'laboratoire': medicamentData['laboratoire'],
          'stock': medicamentData['stock'],
          'categorie': medicamentData['categorie'],
          'necessite0rdonnance': medicamentData['necessite0rdonnance'],
          'estDisponible': medicamentData['estDisponible'],
          'dosage': medicamentData['dosage'],
          'formePharmaceutique': medicamentData['formePharmaceutique'],
          'dateExpiration': Timestamp.fromDate(medicamentData['dateExpiration'] as DateTime),
          'modeEmploi': medicamentData['modeEmploi'],
          'contreIndications': medicamentData['contreIndications'],
          'dateAjout': Timestamp.now(),
        });
      }
      print('✅ ${medicamentsData.length} médicaments créés pour pharmacie ID: $pharmacieId');
    }

    print('🎉 Données complètes créées: ${pharmaciesData.length} pharmacies, ${medicamentsData.length * pharmacieIds.length} médicaments');
  }

  void _showUrgenceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 10),
              Text('Pharmacies de garde'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Numéros d\'urgence :',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text('🚑 SAMU: 15'),
              Text('🚨 Police: 17'),
              Text('🚒 Pompiers: 18'),
              Text('☎️ Urgences médicales: 15'),
              SizedBox(height: 15),
              Text(
                'Pour trouver une pharmacie de garde, contactez le 3237 ou consultez notre liste des pharmacies 24h/24.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(
                  context, 
                  '/client/pharmacies',
                  arguments: {'filter': 'De garde'}
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir pharmacies de garde'),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).deconnexion();
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }
}