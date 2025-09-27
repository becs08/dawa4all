import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/livreur_service.dart';
import '../../models/livreur_model.dart';
import '../../models/commande_model.dart';
import 'available_deliveries_screen.dart';
import 'simple_active_delivery_screen.dart';
import 'delivery_history_screen.dart';
import 'livreur_profile_screen.dart';

class LivreurDashboardScreen extends StatefulWidget {
  const LivreurDashboardScreen({Key? key}) : super(key: key);

  @override
  _LivreurDashboardScreenState createState() => _LivreurDashboardScreenState();
}

class _LivreurDashboardScreenState extends State<LivreurDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHomeWidget(),
    const AvailableDeliveriesScreen(),
    const SimpleActiveDeliveryScreen(),
    const DeliveryHistoryScreen(),
    const LivreurProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade700,
              Colors.green.shade600,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Tableau de bord',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping),
              label: 'Disponibles',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation_outlined),
              activeIcon: Icon(Icons.navigation),
              label: 'En cours',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHomeWidget extends StatefulWidget {
  const _DashboardHomeWidget({Key? key}) : super(key: key);

  @override
  _DashboardHomeWidgetState createState() => _DashboardHomeWidgetState();
}

class _DashboardHomeWidgetState extends State<_DashboardHomeWidget> {
  final LivreurService _livreurService = LivreurService();
  LivreurModel? _livreur;
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser?.id != null) {
      try {
        final livreur = await _livreurService.getLivreurById(authProvider.currentUser!.id);
        final stats = await _livreurService.getStatistiquesLivreur(authProvider.currentUser!.id);
        
        setState(() {
          _livreur = livreur;
          _statistiques = stats;
          _isLoading = false;
        });
      } catch (e) {
        print('Erreur chargement données: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDisponibilite() async {
    if (_livreur == null) return;
    
    try {
      final newStatus = !_livreur!.estDisponible;
      await _livreurService.updateDisponibilite(_livreur!.id, newStatus);
      
      setState(() {
        _livreur = _livreur!.copyWith(estDisponible: newStatus);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? 'Vous êtes maintenant disponible' : 'Vous êtes maintenant indisponible'),
          backgroundColor: newStatus ? Colors.green : Colors.orange,
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
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderne
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.green.shade600,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: _buildTitle(),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade500,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) async {
                  if (value == 'logout') {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.deconnexion();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text('Déconnexion'),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Salutation et statut
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    
                    // Bouton de disponibilité
                    _buildAvailabilityToggle(),
                    const SizedBox(height: 24),
                    
                    // Statistiques
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Statistiques',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatsRow(),
                    
                    const SizedBox(height: 24),
                    
                    // Actions rapides
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Actions rapides',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Dernières courses
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dernières courses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentDeliveries(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        String displayName = '';
        
        if (_livreur != null) {
          displayName = _livreur!.prenom;
        } else if (authProvider.currentUser?.nom != null) {
          displayName = authProvider.currentUser!.nom.split(' ').first;
        } else {
          displayName = 'Livreur';
        }
        
        return Text(
          'Bonjour $displayName!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tableau de Bord',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  _getStatusMessage(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.circle,
                  color: Colors.white,
                  size: 8,
                ),
                const SizedBox(width: 4),
                Text(
                  _getStatusText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _livreur?.estDisponible == true ? Icons.online_prediction : Icons.offline_bolt,
            color: _livreur?.estDisponible == true ? Colors.green : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statut de disponibilité',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _livreur?.estDisponible == true 
                      ? 'Vous recevez les demandes de livraison'
                      : 'Vous ne recevez pas de demandes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _livreur?.estDisponible ?? false,
            onChanged: _livreur?.statut == 'actif' ? (_) => _toggleDisponibilite() : null,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return SizedBox(
      height: 85,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildStatCard(
            'Livraisons',
            '${_statistiques?['nombreLivraisons'] ?? 0}',
            Icons.local_shipping,
            Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Revenus',
            '${(_statistiques?['totalRevenus'] ?? 0).toStringAsFixed(0)} F',
            Icons.attach_money,
            Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Note',
            '${_livreur?.note.toStringAsFixed(1) ?? '0.0'}/5',
            Icons.star,
            Colors.orange,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            'Moy/Course',
            '${(_statistiques?['revenuMoyen'] ?? 0).toStringAsFixed(0)} F',
            Icons.trending_up,
            Colors.purple,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 100,
      height: 85,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Disponibles',
                'Voir demandes',
                Icons.local_shipping_outlined,
                Colors.blue,
                1,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'En cours',
                'Ma livraison',
                Icons.navigation,
                Colors.green,
                2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Historique',
                'Mes livraisons',
                Icons.history,
                Colors.purple,
                3,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Profil',
                'Paramètres',
                Icons.person,
                Colors.orange,
                4,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int tabIndex,
  ) {
    return InkWell(
      onTap: () {
        // Naviguer vers l'onglet correspondant
        final parent = context.findAncestorStateOfType<_LivreurDashboardScreenState>();
        parent?.setState(() {
          parent._selectedIndex = tabIndex;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDeliveries() {
    return StreamBuilder<List<CommandeModel>>(
      stream: _livreurService.getHistoriqueLivraisons(
        Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  color: Colors.grey.shade400,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune livraison récente',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final recentDeliveries = snapshot.data!.take(3).toList();

        return Column(
          children: recentDeliveries.map((commande) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getDeliveryStatusColor(commande.statutCommande).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDeliveryStatusIcon(commande.statutCommande),
                      color: _getDeliveryStatusColor(commande.statutCommande),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commande.pharmacieNom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${commande.fraisLivraison.toInt()} FCFA',
                          style: TextStyle(
                            color: Colors.green.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDateTime(commande.dateLivraison ?? commande.dateCommande),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _getStatusMessage() {
    if (_livreur == null) return 'Chargement...';
    
    switch (_livreur!.statut) {
      case 'en_attente_validation':
        return 'Votre compte est en attente de validation';
      case 'actif':
        return _livreur!.estDisponible 
            ? 'Vous êtes disponible pour les livraisons'
            : 'Vous êtes actuellement indisponible';
      case 'suspendu':
        return 'Votre compte a été suspendu';
      case 'en_livraison':
        return 'Vous avez une livraison en cours';
      default:
        return 'Statut inconnu';
    }
  }

  String _getStatusText() {
    if (_livreur == null) return 'Chargement';
    
    switch (_livreur!.statut) {
      case 'en_attente_validation':
        return 'En attente';
      case 'actif':
        return _livreur!.estDisponible ? 'Disponible' : 'Indisponible';
      case 'suspendu':
        return 'Suspendu';
      case 'en_livraison':
        return 'En livraison';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor() {
    if (_livreur == null) return Colors.grey;
    
    switch (_livreur!.statut) {
      case 'en_attente_validation':
        return Colors.orange;
      case 'actif':
        return _livreur!.estDisponible ? Colors.green : Colors.grey;
      case 'suspendu':
        return Colors.red;
      case 'en_livraison':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'livree':
        return Colors.green;
      case 'en_livraison':
      case 'en_route_client':
        return Colors.blue;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getDeliveryStatusIcon(String status) {
    switch (status) {
      case 'livree':
        return Icons.check_circle;
      case 'en_livraison':
      case 'en_route_client':
        return Icons.local_shipping;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}min';
    }
  }
}