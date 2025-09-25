import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../services/location_service.dart';
import '../../models/pharmacie_model.dart';

class PharmaciesListScreen extends StatefulWidget {
  const PharmaciesListScreen({Key? key}) : super(key: key);

  @override
  _PharmaciesListScreenState createState() => _PharmaciesListScreenState();
}

class _PharmaciesListScreenState extends State<PharmaciesListScreen> {
  final PharmacieService _pharmacieService = PharmacieService();
  final TextEditingController _searchController = TextEditingController();

  List<PharmacieModel> _pharmacies = [];
  List<PharmacieModel> _filteredPharmacies = [];
  bool _isLoading = true;
  Position? _currentPosition;
  String _selectedFilter = 'Toutes'; // Toutes, Ouvertes, Proches

  final List<String> _filterOptions = ['Toutes', 'Ouvertes', 'Proches', 'De garde'];

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Récupérer les arguments passés lors de la navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('filter')) {
      _selectedFilter = args['filter'];
      // Appliquer le filtre dès que les pharmacies sont chargées
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pharmacies.isNotEmpty) {
          _applyFilters();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await LocationService.getCurrentPosition();
      if (_currentPosition != null) {
        _sortPharmaciesByDistance();
      }
    } catch (e) {
      print('Erreur géolocalisation: $e');
    }
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pharmacies = await _pharmacieService.getAllPharmacies();
      setState(() {
        _pharmacies = pharmacies;
        _filteredPharmacies = pharmacies;
      });
    } catch (e) {
      print('Erreur chargement pharmacies: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors du chargement des pharmacies'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Color _getStatusColor(PharmacieModel pharmacie) {
    switch (pharmacie.couleurStatut) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getJourSemaine(int weekday) {
    const jours = [
      'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
    ];
    return jours[weekday - 1];
  }

  void _sortPharmaciesByDistance() {
    if (_currentPosition == null) return;

    setState(() {
      _pharmacies.sort((a, b) {
        final distanceA = LocationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          a.localisation.latitude,
          a.localisation.longitude,
        );
        final distanceB = LocationService.calculateDistance(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          b.localisation.latitude,
          b.localisation.longitude,
        );
        return distanceA.compareTo(distanceB);
      });
      _applyFilters();
    });
  }

  void _applyFilters() {
    String searchQuery = _searchController.text.toLowerCase();

    setState(() {
      _filteredPharmacies = _pharmacies.where((pharmacie) {
        // Filtre par recherche
        bool matchesSearch = pharmacie.nomPharmacie.toLowerCase().contains(searchQuery) ||
            pharmacie.adresse.toLowerCase().contains(searchQuery) ||
            pharmacie.ville.toLowerCase().contains(searchQuery);

        if (!matchesSearch) return false;

        // Filtre par statut
        switch (_selectedFilter) {
          case 'Ouvertes':
            return pharmacie.estOuverteActuellement;
          case 'Proches':
            if (_currentPosition == null) return true;
            final distance = LocationService.calculateDistance(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              pharmacie.localisation.latitude,
              pharmacie.localisation.longitude,
            );
            return distance <= 5.0; // 5 km maximum
          case 'De garde':
            // Vérifier si c'est un jour de garde pour cette pharmacie
            final now = DateTime.now();
            final jourActuel = _getJourSemaine(now.weekday);
            return pharmacie.joursGarde.contains(jourActuel) || pharmacie.horaires24h;
          default:
            return true;
        }
      }).toList();
    });
  }

  double? _getDistanceToPharmacy(PharmacieModel pharmacie) {
    if (_currentPosition == null) return null;
    return LocationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pharmacie.localisation.latitude,
      pharmacie.localisation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une pharmacie...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    hintStyle: const TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) => _applyFilters(),
                ),
                const SizedBox(height: 12),

                // Filtres
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _filterOptions.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return FilterChip(
                      label: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _applyFilters();
                      },
                      backgroundColor: const Color(0xFF2E7D32),
                      selectedColor:const Color(0xFF2E7D32),
                      checkmarkColor: Colors.white,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredPharmacies.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPharmacies,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPharmacies.length,
                    itemBuilder: (context, index) {
                      return _buildPharmacieCard(_filteredPharmacies[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Aucune pharmacie trouvée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _selectedFilter = 'Toutes';
                });
                _applyFilters();
              },
              child: const Text('Réinitialiser les filtres'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacieCard(PharmacieModel pharmacie) {
    final distance = _getDistanceToPharmacy(pharmacie);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/client/pharmacy-details',
              arguments: pharmacie,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec nom et statut
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pharmacie.nomPharmacie,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(pharmacie),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pharmacie.statutTexte,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Adresse
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pharmacie.adresse}, ${pharmacie.ville}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Informations supplémentaires
                Row(
                  children: [
                    // Note
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pharmacie.note.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          ' (${pharmacie.nombreAvis} avis)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Distance
                    if (distance != null) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_walk,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance < 1
                                ? '${(distance * 1000).toInt()}m'
                                : '${distance.toStringAsFixed(1)}km',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),

                // Horaires si ouverte
                if (pharmacie.estOuverteActuellement) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: _getStatusColor(pharmacie),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        pharmacie.horaires24h 
                          ? 'Ouvert 24h/24' 
                          : 'Ouvert: ${pharmacie.heuresOuverture} - ${pharmacie.heuresFermeture}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(pharmacie),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
