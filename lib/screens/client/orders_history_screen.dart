import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/commande_model.dart';
import '../../services/firebase/client_service.dart';

class OrdersHistoryScreen extends StatefulWidget {
  const OrdersHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrdersHistoryScreenState createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen>
    with TickerProviderStateMixin {
  final ClientService _clientService = ClientService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar moderne
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mes Commandes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.green,
                indicatorWeight: 3,
                labelColor: Colors.green.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                tabs: const [
                  Tab(text: 'En cours'),
                  Tab(text: 'Terminées'),
                  Tab(text: 'Annulées'),
                ],
              ),
            ),
          ),

          // Contenu des tabs
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Commandes en cours
                _buildOrdersList(
                  authProvider.currentUser?.id ?? '',
                  ['en_attente', 'validee', 'en_preparation', 'prete', 'en_route_pharmacie', 'recuperee', 'en_route_client', 'en_livraison'],
                ),
                // Commandes terminées
                _buildOrdersList(
                  authProvider.currentUser?.id ?? '',
                  ['livree'],
                ),
                // Commandes annulées/refusées
                _buildOrdersList(
                  authProvider.currentUser?.id ?? '',
                  ['annulee', 'refusee'],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String clientId, List<String> statuts) {
    return StreamBuilder<List<CommandeModel>>(
      stream: _clientService.getCommandesClient(clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.green),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(statuts);
        }

        final allCommandes = snapshot.data!;
        final filteredCommandes = allCommandes
            .where((c) => statuts.contains(c.statutCommande))
            .toList()
          ..sort((a, b) => b.dateCommande.compareTo(a.dateCommande));

        if (filteredCommandes.isEmpty) {
          return _buildEmptyState(statuts);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCommandes.length,
          itemBuilder: (context, index) {
            return _buildOrderCard(filteredCommandes[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(List<String> statuts) {
    IconData icon;
    String message;

    if (statuts.contains('en_attente')) {
      icon = Icons.shopping_bag_outlined;
      message = 'Aucune commande en cours';
    } else if (statuts.contains('livree')) {
      icon = Icons.check_circle_outline;
      message = 'Aucune commande terminée';
    } else {
      icon = Icons.cancel_outlined;
      message = 'Aucune commande annulée';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(CommandeModel commande) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(commande),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec numéro et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande #${commande.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(commande.dateCommande),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(commande.statutCommande),
                  ],
                ),
                const Divider(height: 24),

                // Pharmacie
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.local_pharmacy,
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
                            commande.pharmacieNom,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${commande.items.length} article${commande.items.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Timeline de statut
                if (commande.statutCommande != 'annulee' &&
                    commande.statutCommande != 'refusee')
                  _buildStatusTimeline(commande.statutCommande),

                const SizedBox(height: 12),

                // Montant et action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Montant total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '${commande.montantTotal.toStringAsFixed(0)} FCFA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => _showOrderDetails(commande),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
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

  Widget _buildStatusBadge(String statut) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (statut) {
      case 'en_attente':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case 'validee':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Validée';
        icon = Icons.check_circle;
        break;
      case 'en_preparation':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Préparation';
        icon = Icons.pending_actions;
        break;
      case 'prete':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        label = 'Prête';
        icon = Icons.inventory_2;
        break;
      case 'en_route_pharmacie':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Livreur en route';
        icon = Icons.directions_car;
        break;
      case 'en_livraison':
      case 'recuperee':
      case 'en_route_client':
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        label = 'En livraison';
        icon = Icons.local_shipping;
        break;
      case 'livree':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Livrée';
        icon = Icons.check_circle;
        break;
      case 'annulee':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Annulée';
        icon = Icons.cancel;
        break;
      case 'refusee':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Refusée';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = [
      {
        'status': 'en_attente',
        'label': 'En attente',
        'icon': Icons.schedule,
        'color': Colors.orange.shade600
      },
      {
        'status': 'validee',
        'label': 'Validée',
        'icon': Icons.check_circle,
        'color': Colors.blue.shade600
      },
      {
        'status': 'en_preparation',
        'label': 'Préparation',
        'icon': Icons.medical_services,
        'color': Colors.purple.shade600
      },
      {
        'status': 'prete',
        'label': 'Prête',
        'icon': Icons.inventory_2,
        'color': Colors.teal.shade600
      },
      {
        'status': 'en_livraison',
        'label': 'Livraison',
        'icon': Icons.local_shipping,
        'color': Colors.indigo.shade600
      },
      {
        'status': 'livree',
        'label': 'Livrée',
        'icon': Icons.done_all,
        'color': Colors.green.shade600
      },
    ];

    // Gestion des statuts spéciaux
    String normalizedStatus = currentStatus;
    if (['en_route_pharmacie', 'recuperee', 'en_route_client'].contains(currentStatus)) {
      normalizedStatus = 'en_livraison';
    }

    final currentIndex = steps.indexWhere((s) => s['status'] == normalizedStatus);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Ligne de connexion animée
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentIndex;
            final isNext = stepIndex == currentIndex;

            return Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: isCompleted
                      ? LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600,
                          ],
                        )
                      : isNext
                          ? LinearGradient(
                              colors: [
                                Colors.green.shade300,
                                Colors.grey.shade300,
                              ],
                            )
                          : null,
                  color: !isCompleted && !isNext ? Colors.grey.shade300 : null,
                ),
              ),
            );
          } else {
            // Cercle de statut amélioré
            final stepIndex = index ~/ 2;
            final step = steps[stepIndex];
            final isCompleted = stepIndex <= currentIndex;
            final isCurrent = stepIndex == currentIndex;
            final statusColor = step['color'] as Color;
            final iconData = step['icon'] as IconData;

            return Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? statusColor
                    : Colors.grey.shade200,
                border: isCurrent
                    ? Border.all(color: statusColor, width: 3)
                    : Border.all(
                        color: isCompleted ? statusColor : Colors.grey.shade300,
                        width: 1.5,
                      ),
                boxShadow: isCompleted || isCurrent
                    ? [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isCompleted ? Icons.check : iconData,
                size: isCompleted ? 16 : 14,
                color: isCompleted
                    ? Colors.white
                    : isCurrent
                        ? statusColor
                        : Colors.grey.shade400,
              ),
            );
          }
        }),
      ),
    );
  }

  void _showOrderDetails(CommandeModel commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderDetailsModal(
        commande: commande,
        onCancel: _cancelOrder,
      ),
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Hier à ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(date.weekday)} à ${_formatTime(date)}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getWeekday(int weekday) {
    const weekdays = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    return weekdays[weekday - 1];
  }

  Future<void> _cancelOrder(CommandeModel commande) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Annuler la commande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette commande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _clientService.annulerCommande(commande.id);
        Navigator.of(context).pop(); // Fermer le modal de détails

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande annulée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Modal avec onglets pour les détails de commande
class _OrderDetailsModal extends StatefulWidget {
  final CommandeModel commande;
  final Function(CommandeModel) onCancel;

  const _OrderDetailsModal({
    required this.commande,
    required this.onCancel,
  });

  @override
  _OrderDetailsModalState createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<_OrderDetailsModal>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commande',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${widget.commande.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.green,
              indicatorWeight: 3,
              labelColor: Colors.green.shade700,
              unselectedLabelColor: Colors.grey.shade600,
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long),
                  text: 'Détails commande',
                ),
                Tab(
                  icon: Icon(Icons.track_changes),
                  text: 'Suivi commande',
                ),
              ],
            ),
          ),

          // Contenu des tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderDetailsTab(),
                _buildOrderTrackingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          _buildDetailSection(
            'Statut',
            child: Row(
              children: [
                _buildStatusBadge(widget.commande.statutCommande),
                if (widget.commande.raisonRefus != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.commande.raisonRefus!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Pharmacie
          _buildDetailSection(
            'Pharmacie',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_pharmacy,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.commande.pharmacieNom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.commande.pharmacieAdresse,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Articles
          _buildDetailSection(
            'Articles (${widget.commande.items.length})',
            child: Column(
              children: widget.commande.items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${item.quantite}x',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.medicamentNom,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${(item.prix * item.quantite).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Livraison
          if (widget.commande.typeLivraison != null)
            _buildDetailSection(
              'Livraison',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.commande.typeLivraison == 'express'
                            ? Icons.rocket_launch
                            : Icons.local_shipping,
                        size: 20,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.commande.typeLivraison == 'express'
                            ? 'Livraison Express (2h)'
                            : 'Livraison Standard (24h)',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Text(
                    '${widget.commande.fraisLivraison.toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // Paiement
          _buildDetailSection(
            'Paiement',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _getPaymentIcon(widget.commande.modePaiement),
                      size: 20,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPaymentLabel(widget.commande.modePaiement),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.commande.paiementEffectue
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.commande.paiementEffectue ? 'Payé' : 'En attente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: widget.commande.paiementEffectue
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.commande.montantTotalAvecLivraison.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          // Actions selon le statut
          if (widget.commande.statutCommande == 'en_attente' ||
              widget.commande.statutCommande == 'validee')
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: ElevatedButton.icon(
                onPressed: () => widget.onCancel(widget.commande),
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler la commande'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline détaillée
          _buildDetailSection(
            'Suivi de la commande',
            child: _buildDetailedTimeline(),
          ),

          const SizedBox(height: 20),

          // Informations de livraison
          if (widget.commande.livreurNom != null)
            _buildDetailSection(
              'Livreur',
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delivery_dining,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.commande.livreurNom!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Livreur assigné',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Date de commande
          _buildDetailSection(
            'Dates importantes',
            child: Column(
              children: [
                _buildDateRow(
                  'Commande passée',
                  widget.commande.dateCommande,
                  Icons.shopping_cart,
                  Colors.blue,
                ),
                if (widget.commande.dateValidation != null)
                  _buildDateRow(
                    'Validée',
                    widget.commande.dateValidation!,
                    Icons.check_circle,
                    Colors.green,
                  ),
                if (widget.commande.dateLivraison != null)
                  _buildDateRow(
                    'Livrée',
                    widget.commande.dateLivraison!,
                    Icons.local_shipping,
                    Colors.green,
                  ),
              ],
            ),
          ),

          // Note de validation
          if (widget.commande.noteValidation != null)
            _buildDetailSection(
              'Note de la pharmacie',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.commande.noteValidation!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedTimeline() {
    final steps = [
      {
        'status': 'en_attente',
        'label': 'En attente',
        'description': 'Commande transmise à la pharmacie',
        'icon': Icons.schedule,
        'color': Colors.orange.shade600,
      },
      {
        'status': 'validee',
        'label': 'Validée',
        'description': 'Pharmacie a validé votre commande',
        'icon': Icons.check_circle,
        'color': Colors.blue.shade600,
      },
      {
        'status': 'en_preparation',
        'label': 'En préparation',
        'description': 'Médicaments en cours de préparation',
        'icon': Icons.medical_services,
        'color': Colors.purple.shade600,
      },
      {
        'status': 'prete',
        'label': 'Prête',
        'description': 'Commande prête pour livraison',
        'icon': Icons.inventory_2,
        'color': Colors.teal.shade600,
      },
      {
        'status': 'en_livraison',
        'label': 'En livraison',
        'description': 'Livreur en route vers vous',
        'icon': Icons.local_shipping,
        'color': Colors.indigo.shade600,
      },
      {
        'status': 'livree',
        'label': 'Livrée',
        'description': 'Commande livrée avec succès',
        'icon': Icons.done_all,
        'color': Colors.green.shade600,
      },
    ];

    // Gestion des statuts spéciaux
    String normalizedStatus = widget.commande.statutCommande;
    if (['en_route_pharmacie', 'recuperee', 'en_route_client'].contains(widget.commande.statutCommande)) {
      normalizedStatus = 'en_livraison';
    }

    final currentIndex = steps.indexWhere((s) => s['status'] == normalizedStatus);

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentIndex;
        final isCurrent = index == currentIndex;
        final isLast = index == steps.length - 1;
        final stepColor = step['color'] as Color;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator amélioré
              Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? stepColor : Colors.grey.shade200,
                      border: isCurrent
                          ? Border.all(color: stepColor, width: 3)
                          : Border.all(
                              color: isCompleted ? stepColor : Colors.grey.shade300,
                              width: 1.5,
                            ),
                      boxShadow: isCompleted || isCurrent
                          ? [
                              BoxShadow(
                                color: stepColor.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step['icon'] as IconData,
                      size: isCompleted ? 24 : 20,
                      color: isCompleted
                          ? Colors.white
                          : isCurrent
                              ? stepColor
                              : Colors.grey.shade500,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 3,
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: isCompleted
                            ? LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  stepColor,
                                  stepColor.withOpacity(0.7),
                                ],
                              )
                            : null,
                        color: !isCompleted ? Colors.grey.shade300 : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content amélioré
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? stepColor.withOpacity(0.1)
                        : isCurrent
                            ? stepColor.withOpacity(0.05)
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrent
                        ? Border.all(color: stepColor.withOpacity(0.3), width: 1.5)
                        : Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isCompleted
                                    ? stepColor
                                    : isCurrent
                                        ? stepColor
                                        : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stepColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Terminé',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: stepColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'En cours',
                                style: TextStyle(
                                  color: stepColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['description'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCompleted
                              ? stepColor
                              : Colors.grey.shade600,
                        ),
                      ),
                      // Informations spéciales pour certains statuts
                      if (isCurrent && widget.commande.statutCommande == 'en_route_pharmacie')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.directions_car,
                                     size: 16, color: Colors.blue.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Le livreur se dirige vers la pharmacie',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isCurrent && widget.commande.statutCommande == 'en_route_client')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.indigo.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.navigation,
                                     size: 16, color: Colors.indigo.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Le livreur arrive vers vous',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.indigo.shade700,
                                    fontWeight: FontWeight.w500,
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
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRow(String label, DateTime date, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            _formatDateTime(date),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailSection(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String statut) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (statut) {
      case 'en_attente':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        label = 'En attente';
        icon = Icons.schedule;
        break;
      case 'validee':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Validée';
        icon = Icons.check_circle;
        break;
      case 'en_preparation':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade700;
        label = 'Préparation';
        icon = Icons.pending_actions;
        break;
      case 'prete':
        bgColor = Colors.teal.shade50;
        textColor = Colors.teal.shade700;
        label = 'Prête';
        icon = Icons.inventory_2;
        break;
      case 'en_route_pharmacie':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        label = 'Livreur en route';
        icon = Icons.directions_car;
        break;
      case 'en_livraison':
      case 'recuperee':
      case 'en_route_client':
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade700;
        label = 'En livraison';
        icon = Icons.local_shipping;
        break;
      case 'livree':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        label = 'Livrée';
        icon = Icons.check_circle;
        break;
      case 'annulee':
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Annulée';
        icon = Icons.cancel;
        break;
      case 'refusee':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        label = 'Refusée';
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        label = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String? modePaiement) {
    switch (modePaiement) {
      case 'wave':
        return Icons.phone_android;
      case 'orange_money':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentLabel(String? modePaiement) {
    switch (modePaiement) {
      case 'wave':
        return 'Wave';
      case 'orange_money':
        return 'Orange Money';
      case 'cash':
        return 'Espèces à la livraison';
      default:
        return 'Non spécifié';
    }
  }
}

// Delegate pour les headers persistants
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
