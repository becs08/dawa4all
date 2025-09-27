import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../models/commande_model.dart';
import 'attribution_livreur_screen.dart';

class CommandesScreen extends StatefulWidget {
  const CommandesScreen({Key? key}) : super(key: key);

  @override
  _CommandesScreenState createState() => _CommandesScreenState();
}

class _CommandesScreenState extends State<CommandesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PharmacieService _pharmacieService = PharmacieService();

  final Map<String, String> _statusLabels = {
    'en_attente': 'En attente',
    'validee': 'Validée',
    'en_preparation': 'En préparation',
    'prete': 'Prête',
    'en_route_pharmacie': 'Livreur en route',
    'recuperee': 'Récupérée',
    'en_route_client': 'Vers le client',
    'en_livraison': 'En livraison',
    'livree': 'Livrée',
    'annulee': 'Annulée',
    'refusee': 'Refusée',
  };

  final Map<String, Color> _statusColors = {
    'en_attente': Colors.orange,
    'validee': Colors.blue,
    'en_preparation': Colors.purple,
    'prete': Colors.teal,
    'en_route_pharmacie': Colors.lightBlue,
    'recuperee': Colors.cyan,
    'en_route_client': Colors.indigo,
    'en_livraison': Colors.indigo,
    'livree': Colors.green,
    'annulee': Colors.grey,
    'refusee': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Commandes'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'En cours', icon: Icon(Icons.hourglass_empty)),
            Tab(text: 'Terminées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Toutes', icon: Icon(Icons.list)),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommandesList(['en_attente']),
          _buildCommandesList(['validee', 'en_preparation', 'prete', 'en_route_pharmacie', 'recuperee', 'en_route_client', 'en_livraison']),
          _buildCommandesList(['livree', 'annulee', 'refusee']),
          _buildCommandesList(null), // Toutes les commandes
        ],
      ),
    );
  }

  Widget _buildCommandesList(List<String>? statusFilter) {
    return StreamBuilder<List<CommandeModel>>(
      stream: _pharmacieService.getCommandesPharmacie(
        _pharmacieService.currentPharmacieId ?? ''
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Erreur: ${snapshot.error}'),
              ],
            ),
          );
        }

        final allCommandes = snapshot.data ?? [];
        final filteredCommandes = statusFilter != null
            ? allCommandes.where((cmd) => statusFilter.contains(cmd.statutCommande)).toList()
            : allCommandes;

        if (filteredCommandes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucune commande trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredCommandes.length,
          itemBuilder: (context, index) {
            final commande = filteredCommandes[index];
            return _buildCommandeCard(commande);
          },
        );
      },
    );
  }

  Widget _buildCommandeCard(CommandeModel commande) {
    final statusColor = _statusColors[commande.statutCommande] ?? Colors.grey;
    final statusLabel = _statusLabels[commande.statutCommande] ?? commande.statutCommande;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                statusColor.withOpacity(0.8),
                statusColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            _getStatusIcon(commande.statutCommande),
            color: Colors.white,
            size: 22,
          ),
        ),
        title: Text(
          'Commande #${commande.id.substring(0, 8)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(commande.statutCommande),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(commande.dateCommande),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Client: ${commande.clientNom}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Total: ${commande.montantTotal.toStringAsFixed(0)} FCFA',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de livraison
                if (commande.clientAdresse.isNotEmpty) ...[
                  const Text(
                    'Adresse de livraison:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(commande.clientAdresse),
                  const SizedBox(height: 8),
                ],

                // Téléphone client
                if (commande.clientTelephone.isNotEmpty) ...[
                  const Text(
                    'Téléphone:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(commande.clientTelephone),
                  const SizedBox(height: 8),
                ],

                // Mode de paiement
                const Text(
                  'Mode de paiement:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(commande.modePaiement.toUpperCase()),
                const SizedBox(height: 8),

                // Ordonnance
                if (commande.ordonnanceUrl != null && commande.ordonnanceUrl!.isNotEmpty) ...[
                  const Text(
                    'Ordonnance:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showOrdonnanceDialog(commande.ordonnanceUrl!),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Voir l\'ordonnance',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions selon le statut
                _buildActionButtons(commande),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CommandeModel commande) {
    List<Widget> buttons = [];

    switch (commande.statutCommande) {
      case 'en_attente':
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _validateCommande(commande),
            icon: const Icon(Icons.check),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _rejectCommande(commande),
            icon: const Icon(Icons.close),
            label: const Text('Refuser'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ]);
        break;

      case 'validee':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'en_preparation'),
            icon: const Icon(Icons.build),
            label: const Text('Préparer'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
          ),
        );
        break;

      case 'en_preparation':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _updateStatus(commande, 'prete'),
            icon: const Icon(Icons.check_circle),
            label: const Text('Marquer prête'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        );
        break;

      case 'prete':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => _assignLivreur(commande),
            icon: const Icon(Icons.local_shipping),
            label: const Text('Attribuer livreur'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        );
        break;
    }

    return buttons.isNotEmpty
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons,
          )
        : const SizedBox();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.schedule;
      case 'validee':
        return Icons.check_circle;
      case 'en_preparation':
        return Icons.medical_services;
      case 'prete':
        return Icons.inventory_2;
      case 'en_route_pharmacie':
        return Icons.directions_car;
      case 'recuperee':
        return Icons.inventory;
      case 'en_route_client':
        return Icons.navigation;
      case 'en_livraison':
        return Icons.local_shipping;
      case 'livree':
        return Icons.done_all;
      case 'annulee':
        return Icons.cancel_outlined;
      case 'refusee':
        return Icons.close_rounded;
      default:
        return Icons.help_outline;
    }
  }

  void _validateCommande(CommandeModel commande) {
    showDialog(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        return AlertDialog(
          title: const Text('Valider la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Êtes-vous sûr de vouloir valider cette commande ?'),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note de validation (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _pharmacieService.validerCommande(
                  commande.id,
                  noteController.text,
                );
                Navigator.pop(context);
                _showResultSnackbar(success, 'Commande validée');
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

  void _rejectCommande(CommandeModel commande) {
    showDialog(
      context: context,
      builder: (context) {
        final raisonController = TextEditingController();
        return AlertDialog(
          title: const Text('Refuser la commande'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pourquoi refusez-vous cette commande ?'),
              const SizedBox(height: 16),
              TextField(
                controller: raisonController,
                decoration: const InputDecoration(
                  labelText: 'Raison du refus',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (raisonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez indiquer une raison'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await _pharmacieService.refuserCommande(
                  commande.id,
                  raisonController.text,
                );
                Navigator.pop(context);
                _showResultSnackbar(success, 'Commande refusée');
              },
              child: const Text('Refuser'),
            ),
          ],
        );
      },
    );
  }

  void _updateStatus(CommandeModel commande, String newStatus) async {
    final success = await _pharmacieService.updateCommandeStatut(
      commande.id,
      newStatus,
    );
    _showResultSnackbar(success, 'Statut mis à jour');
  }

  void _assignLivreur(CommandeModel commande) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AttributionLivreurScreen(commande: commande),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande attribuée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  void _showResultSnackbar(bool success, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '$message avec succès' : 'Erreur lors de l\'opération'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  void _showOrdonnanceDialog(String ordonnanceUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Ordonnance'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Flexible(
              child: Image.network(
                ordonnanceUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Impossible de charger l\'image'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}