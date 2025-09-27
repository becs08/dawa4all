import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/firebase/pharmacie_service.dart';
import 'medicaments_screen.dart';
import 'commandes_screen.dart';
import 'livreurs_screen.dart';
import 'profile_screen.dart';

class PharmacieDashboardScreen extends StatefulWidget {
  const PharmacieDashboardScreen({Key? key}) : super(key: key);

  @override
  _PharmacieDashboardScreenState createState() => _PharmacieDashboardScreenState();
}

class _PharmacieDashboardScreenState extends State<PharmacieDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardHomeWidget(),
    const MedicamentsScreen(),
    const CommandesScreen(),
    const LivreursScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Tableau de bord',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Médicaments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Commandes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.delivery_dining),
            label: 'Livreurs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
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
  final PharmacieService _pharmacieService = PharmacieService();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
    _initializeNotifications();
  }

  void _initializeNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final notificationProvider = context.read<NotificationProvider>();
      
      if (authProvider.isAuthenticated && authProvider.currentUser?.id != null) {
        notificationProvider.initialize(
          authProvider.currentUser!.id, 
          'pharmacie'
        );
      }
    });
  }

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await _pharmacieService.getDashboardStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar compact moderne
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Colors.green.shade600,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Text(
                    'Bonjour ${authProvider.currentUser?.nom?.split(' ').first ?? ""}!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  );
                },
              ),
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
                    // Motif décoratif simplifié
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
              // Indicateur de notifications
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, _) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                          ),
                          onPressed: () => _showNotificationsDialog(context),
                        ),
                        if (notificationProvider.hasUnreadNotifications)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${notificationProvider.nombreNonLues > 9 ? '9+' : notificationProvider.nombreNonLues}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'logout') {
                    context.read<AuthProvider>().deconnexion();
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

          // Contenu du tableau de bord
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
                    // Message de bienvenue compact
                    Container(
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
                              Icons.local_pharmacy,
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
                                  'Gérez efficacement',
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
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  color: Colors.white,
                                  size: 8,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'En ligne',
                                  style: TextStyle(
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
                    ),
                    const SizedBox(height: 20),

                    // Statistiques modernes
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

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: Colors.green),
                        ),
                      )
                    else
                      SizedBox(
                        height: 115,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCompactStatCard(
                              title: 'Commandes\nAujourd\'hui',
                              value: '${_stats?['commandesAujourdhui'] ?? 0}',
                              icon: Icons.shopping_bag_outlined,
                              gradient: [Colors.blue.shade400, Colors.blue.shade600],
                            ),
                            const SizedBox(width: 12),
                            _buildCompactStatCard(
                              title: 'Total\nMédicaments',
                              value: '${_stats?['totalMedicaments'] ?? 0}',
                              icon: Icons.medication_outlined,
                              gradient: [Colors.green.shade400, Colors.green.shade600],
                            ),
                            const SizedBox(width: 12),
                            _buildCompactStatCard(
                              title: 'Revenus\ndu Mois',
                              value: '${(_stats?['revenusMois'] ?? 0.0).toStringAsFixed(0)}',
                              icon: Icons.attach_money,
                              gradient: [Colors.orange.shade400, Colors.orange.shade600],
                              suffix: 'k',
                            ),
                            const SizedBox(width: 12),
                            _buildCompactStatCard(
                              title: 'Note\nMoyenne',
                              value: '${(_stats?['noteMoyenne'] ?? 0.0).toStringAsFixed(1)}',
                              icon: Icons.star_outline,
                              gradient: [Colors.amber.shade400, Colors.amber.shade600],
                              suffix: '/5',
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Actions rapides compactes
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: Colors.green.shade700,
                          size: 18,
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
                    const SizedBox(height: 5),

                    // Actions compactes 2x2
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.3,
                      children: [
                        _buildCompactActionCard(
                          title: 'Ajouter\nMédicament',
                          icon: Icons.add_box_outlined,
                          gradient: [Colors.green.shade400, Colors.green.shade600],
                          onTap: () {
                            final dashboardState = context.findAncestorStateOfType<_PharmacieDashboardScreenState>();
                            dashboardState?.setState(() {
                              dashboardState._selectedIndex = 1;
                            });
                          },
                        ),
                        _buildCompactActionCard(
                          title: 'Voir\nCommandes',
                          icon: Icons.receipt_long_outlined,
                          gradient: [Colors.blue.shade400, Colors.blue.shade600],
                          onTap: () {
                            final dashboardState = context.findAncestorStateOfType<_PharmacieDashboardScreenState>();
                            dashboardState?.setState(() {
                              dashboardState._selectedIndex = 2;
                            });
                          },
                        ),
                        _buildCompactActionCard(
                          title: 'Gérer\nStock',
                          icon: Icons.inventory_2_outlined,
                          gradient: [Colors.orange.shade400, Colors.orange.shade600],
                          onTap: () {
                            final dashboardState = context.findAncestorStateOfType<_PharmacieDashboardScreenState>();
                            dashboardState?.setState(() {
                              dashboardState._selectedIndex = 1;
                            });
                          },
                        ),
                        _buildCompactActionCard(
                          title: 'Mon\nProfil',
                          icon: Icons.store_outlined,
                          gradient: [Colors.purple.shade400, Colors.purple.shade600],
                          onTap: () {
                            final dashboardState = context.findAncestorStateOfType<_PharmacieDashboardScreenState>();
                            dashboardState?.setState(() {
                              dashboardState._selectedIndex = 3;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section des dernières commandes
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dernières commandes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildRecentOrdersSection(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
  );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required String percentage,
    required bool isPositive,
    String suffix = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      percentage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value + suffix,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    String suffix = '',
  }) {
    return Container(
      width: 135,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value + suffix,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionCard({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: gradient[0].withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.grey.shade800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection() {
    return StreamBuilder<List<dynamic>>(
      stream: _pharmacieService.getCommandesPharmacie(
        _pharmacieService.currentPharmacieId ?? ''
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(color: Colors.green),
            ),
          );
        }

        final commandes = snapshot.data ?? [];
        final recentCommandes = commandes.take(3).toList();

        if (recentCommandes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune commande récente',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: recentCommandes.asMap().entries.map((entry) {
              final index = entry.key;
              final commande = entry.value;
              final isLast = index == recentCommandes.length - 1;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: !isLast ? Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ) : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_bag,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${commande.id?.substring(0, 8) ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            commande.clientNom ?? 'Client',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(commande.statutCommande).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getStatusLabel(commande.statutCommande),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(commande.statutCommande),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${commande.montantTotal?.toStringAsFixed(0) ?? '0'} FCFA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'en_attente': return Colors.orange;
      case 'validee': return Colors.blue;
      case 'en_preparation': return Colors.purple;
      case 'prete': return Colors.green;
      case 'en_route_pharmacie': return Colors.lightBlue;
      case 'recuperee': return Colors.cyan;
      case 'en_route_client':
      case 'en_livraison': return Colors.indigo;
      case 'livree': return Colors.teal;
      case 'annulee':
      case 'refusee': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'en_attente': return 'En attente';
      case 'validee': return 'Validée';
      case 'en_preparation': return 'Préparation';
      case 'prete': return 'Prête';
      case 'en_route_pharmacie': return 'Livreur en route';
      case 'recuperee': return 'Récupérée';
      case 'en_route_client': return 'Chez client';
      case 'en_livraison': return 'Livraison';
      case 'livree': return 'Livrée';
      case 'annulee': return 'Annulée';
      case 'refusee': return 'Refusée';
      default: return 'Inconnue';
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxHeight: 600,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Consumer<NotificationProvider>(
                        builder: (context, notificationProvider, _) {
                          return notificationProvider.hasUnreadNotifications
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${notificationProvider.nombreNonLues}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Consumer<NotificationProvider>(
                    builder: (context, notificationProvider, _) {
                      if (notificationProvider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(color: Colors.green),
                          ),
                        );
                      }

                      final notifications = notificationProvider.notifications;

                      if (notifications.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 60,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune notification',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Vous recevrez ici les notifications de nouvelles commandes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: notification.lue 
                                  ? Colors.grey.shade50 
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: notification.lue 
                                  ? null 
                                  : Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: notification.lue 
                                      ? Colors.grey.shade300 
                                      : Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  notification.getIcon(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              title: Text(
                                notification.titre,
                                style: TextStyle(
                                  fontWeight: notification.lue 
                                      ? FontWeight.normal 
                                      : FontWeight.bold,
                                  fontSize: 14,
                                  color: notification.lue 
                                      ? Colors.grey.shade700 
                                      : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.message,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: notification.lue 
                                          ? Colors.grey.shade600 
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDateTime(notification.dateCreation),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey.shade600,
                                  size: 16,
                                ),
                                onSelected: (value) async {
                                  switch (value) {
                                    case 'marquer_lue':
                                      if (!notification.lue) {
                                        await notificationProvider
                                            .marquerCommeLue(notification.id!);
                                      }
                                      break;
                                    case 'supprimer':
                                      await notificationProvider
                                          .supprimerNotification(notification.id!);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  if (!notification.lue)
                                    const PopupMenuItem(
                                      value: 'marquer_lue',
                                      child: Row(
                                        children: [
                                          Icon(Icons.mark_email_read, size: 16),
                                          SizedBox(width: 8),
                                          Text('Marquer comme lue'),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'supprimer',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () async {
                                if (!notification.lue) {
                                  await notificationProvider
                                      .marquerCommeLue(notification.id!);
                                }
                                
                                Navigator.of(context).pop();
                                
                                if (notification.commandeId != null) {
                                  final dashboardState = context
                                      .findAncestorStateOfType<_PharmacieDashboardScreenState>();
                                  dashboardState?.setState(() {
                                    dashboardState._selectedIndex = 2;
                                  });
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            return TextButton.icon(
                              onPressed: notificationProvider.hasUnreadNotifications
                                  ? () async {
                                      await notificationProvider.marquerToutesCommeLues();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Toutes les notifications marquées comme lues'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                Icons.done_all,
                                size: 16,
                                color: notificationProvider.hasUnreadNotifications
                                    ? Colors.green.shade600
                                    : Colors.grey.shade400,
                              ),
                              label: Text(
                                'Tout marquer lu',
                                style: TextStyle(
                                  color: notificationProvider.hasUnreadNotifications
                                      ? Colors.green.shade600
                                      : Colors.grey.shade400,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, _) {
                            return TextButton.icon(
                              onPressed: () async {
                                await notificationProvider.rafraichir();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notifications actualisées'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.refresh,
                                size: 16,
                                color: Colors.green.shade600,
                              ),
                              label: Text(
                                'Actualiser',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
