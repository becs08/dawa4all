import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/commande_model.dart';
import '../../models/livreur_model.dart';
import '../../models/notification_model.dart';
import '../../services/firebase/livreur_service.dart';
import '../../services/firebase/commande_service.dart';
import '../../services/firebase/notification_service.dart';

class AttributionLivreurScreen extends StatefulWidget {
  final CommandeModel commande;

  const AttributionLivreurScreen({
    Key? key,
    required this.commande,
  }) : super(key: key);

  @override
  _AttributionLivreurScreenState createState() => _AttributionLivreurScreenState();
}

class _AttributionLivreurScreenState extends State<AttributionLivreurScreen> {
  final LivreurService _livreurService = LivreurService();
  final CommandeService _commandeService = CommandeService();
  final NotificationService _notificationService = NotificationService();
  
  List<LivreurModel> _livreurs = [];
  List<LivreurModel> _filteredLivreurs = [];
  List<String> _livreursFavoris = [];
  LivreurModel? _selectedLivreur;
  bool _isLoading = true;
  bool _isAttributing = false;
  String _filterType = 'all'; // all, disponible, favoris
  String _searchQuery = '';
  
  // Note pour la commande
  String _notePosologie = '';
  String _noteSpeciale = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les livreurs disponibles
      final livreurs = await _livreurService.getLivreursDisponibles();
      
      // Charger les favoris
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser?.id != null) {
        final pharmacieDoc = await FirebaseFirestore.instance
            .collection('pharmacies')
            .doc(authProvider.currentUser!.id)
            .get();
        
        if (pharmacieDoc.exists) {
          final data = pharmacieDoc.data()!;
          _livreursFavoris = List<String>.from(data['livreursFavoris'] ?? []);
        }
      }
      
      setState(() {
        _livreurs = livreurs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _filteredLivreurs = _livreurs.where((livreur) {
      // Filtre par type
      bool typeMatch = true;
      switch (_filterType) {
        case 'disponible':
          typeMatch = livreur.estDisponible && livreur.statut == 'actif';
          break;
        case 'favoris':
          typeMatch = _livreursFavoris.contains(livreur.id);
          break;
        default:
          typeMatch = true;
      }

      // Filtre par recherche
      bool searchMatch = true;
      if (_searchQuery.isNotEmpty) {
        searchMatch = livreur.nomComplet.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     livreur.telephone.contains(_searchQuery) ||
                     livreur.ville.toLowerCase().contains(_searchQuery.toLowerCase());
      }

      return typeMatch && searchMatch;
    }).toList();

    // Trier : favoris d'abord, puis par note
    _filteredLivreurs.sort((a, b) {
      final aFavori = _livreursFavoris.contains(a.id);
      final bFavori = _livreursFavoris.contains(b.id);
      
      if (aFavori && !bFavori) return -1;
      if (!aFavori && bFavori) return 1;
      
      return b.note.compareTo(a.note);
    });
  }

  Future<void> _attribuerCommande() async {
    if (_selectedLivreur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un livreur'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAttributing = true);

    try {
      // 1. Mettre à jour la commande
      await _commandeService.updateCommande(
        widget.commande.id,
        {
          'livreurId': _selectedLivreur!.id,
          'livreurNom': _selectedLivreur!.nomComplet,
          'statutCommande': 'prete',
          'datePrete': Timestamp.now(),
          'notePosologie': _notePosologie,
          'noteSpeciale': _noteSpeciale,
        },
      );

      // 2. Créer la notification pour le livreur
      await _notificationService.createNotification(NotificationModel(
        id: '',
        destinataireId: _selectedLivreur!.id,
        typeDestinataire: 'livreur',
        titre: 'Nouvelle livraison disponible',
        message: 'Une nouvelle commande vous a été attribuée par ${widget.commande.pharmacieNom}',
        type: NotificationType.nouvelleLivraison,
        commandeId: widget.commande.id,
        pharmacieId: widget.commande.pharmacieId,
        dateCreation: DateTime.now(),
        lue: false,
        donnees: {
          'commandeId': widget.commande.id,
          'pharmacieNom': widget.commande.pharmacieNom,
          'fraisLivraison': widget.commande.fraisLivraison,
        },
      ));

      // 3. Notifier le client
      await _notificationService.createNotification(NotificationModel(
        id: '',
        destinataireId: widget.commande.clientId,
        typeDestinataire: 'client',
        titre: 'Livreur attribué',
        message: 'Un livreur a été attribué à votre commande. Il sera bientôt en route !',
        type: NotificationType.livreurAttribue,
        commandeId: widget.commande.id,
        pharmacieId: widget.commande.pharmacieId,
        dateCreation: DateTime.now(),
        lue: false,
        donnees: {
          'commandeId': widget.commande.id,
          'livreurNom': _selectedLivreur!.nomComplet,
        },
      ));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande attribuée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAttributing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attribuer un livreur'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Informations de la commande
          _buildCommandeInfo(),
          
          // Notes pour le livreur
          _buildNotesSection(),
          
          // Recherche et filtres
          _buildSearchAndFilters(),
          
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
                          return _buildLivreurItem(livreur);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCommandeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'Informations de la commande',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client: ${widget.commande.clientNom}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Adresse: ${widget.commande.adresseLivraison}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.commande.fraisLivraison.toInt()} FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes pour le livreur',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => _notePosologie = value,
            decoration: InputDecoration(
              labelText: 'Précisions sur la posologie',
              hintText: 'Ex: Prendre 2 comprimés matin et soir...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.medical_services),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => _noteSpeciale = value,
            decoration: InputDecoration(
              labelText: 'Note spéciale (optionnelle)',
              hintText: 'Instructions particulières...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.note),
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                child: _buildFilterChip('favoris', 'Favoris', Icons.star),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filterType == value;
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterType = value;
          _applyFilters();
        });
      },
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16),
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
            'Aucun livreur disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos filtres',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivreurItem(LivreurModel livreur) {
    final isSelected = _selectedLivreur?.id == livreur.id;
    final isFavori = _livreursFavoris.contains(livreur.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedLivreur = livreur;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? Colors.green : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.green.shade700,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                
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
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Note
                          if (livreur.note > 0) ...[
                            Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${livreur.note.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          
                          // Livraisons
                          Icon(
                            Icons.local_shipping,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${livreur.nombreLivraisons} livraisons',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Distance approximative (à implémenter avec géolocalisation)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '~15 min',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Livreur sélectionné
          Expanded(
            child: _selectedLivreur == null
                ? Text(
                    'Aucun livreur sélectionné',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Livreur sélectionné:',
                        style: TextStyle(fontSize: 12),
                      ),
                      Text(
                        _selectedLivreur!.nomComplet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          
          // Bouton attribuer
          ElevatedButton(
            onPressed: _isAttributing || _selectedLivreur == null
                ? null
                : _attribuerCommande,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            child: _isAttributing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Attribuer',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}