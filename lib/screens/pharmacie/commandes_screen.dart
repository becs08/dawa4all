import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../models/commande_model.dart';

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
    'en_livraison': 'En livraison',
    'livree': 'Livrée',
    'annulee': 'Annulée',
    'refusee': 'Refusée',
  };

  final Map<String, Color> _statusColors = {
    'en_attente': Colors.orange,
    'validee': Colors.blue,
    'en_preparation': Colors.purple,
    'prete': Colors.green,
    'en_livraison': Colors.indigo,
    'livree': Colors.teal,
    'annulee': Colors.red,
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
          _buildCommandesList(['validee', 'en_preparation', 'prete', 'en_livraison']),
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
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(
            _getStatusIcon(commande.statutCommande),
            color: statusColor,
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
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
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
        return Icons.pending;
      case 'validee':
        return Icons.check;
      case 'en_preparation':
        return Icons.build;
      case 'prete':
        return Icons.check_circle;
      case 'en_livraison':
        return Icons.local_shipping;
      case 'livree':
        return Icons.done_all;
      case 'annulee':
      case 'refusee':
        return Icons.cancel;
      default:
        return Icons.help;
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

  void _assignLivreur(CommandeModel commande) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAvailableLivreurs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                content: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AlertDialog(
                title: const Text('Aucun livreur disponible'),
                content: const Text('Aucun livreur n\'est disponible pour le moment.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ],
              );
            }
            
            final livreurs = snapshot.data!;
            String? selectedLivreurId;
            String? selectedLivreurNom;
            
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: const Text('Attribuer un livreur'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sélectionnez un livreur pour cette commande:'),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedLivreurId,
                        decoration: const InputDecoration(
                          labelText: 'Livreur',
                          border: OutlineInputBorder(),
                        ),
                        items: livreurs.map((livreur) {
                          return DropdownMenuItem<String>(
                            value: livreur['id'] as String,
                            child: Text(livreur['nom'] as String),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLivreurId = value;
                            selectedLivreurNom = livreurs
                                .firstWhere((l) => l['id'] == value)['nom'];
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: selectedLivreurId == null
                          ? null
                          : () async {
                              final success = await _pharmacieService.attribuerLivreur(
                                commande.id,
                                selectedLivreurId!,
                                selectedLivreurNom!,
                              );
                              Navigator.pop(context);
                              _showResultSnackbar(success, 'Livreur attribué');
                            },
                      child: const Text('Attribuer'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableLivreurs() async {
    try {
      // Pour le moment, on retourne une liste statique de livreurs
      // Dans une vraie app, on récupérerait depuis Firestore
      return [
        {'id': 'livreur1', 'nom': 'Jean Dupont'},
        {'id': 'livreur2', 'nom': 'Marie Martin'},
        {'id': 'livreur3', 'nom': 'Pierre Durand'},
      ];
    } catch (e) {
      print('Erreur lors de la récupération des livreurs: $e');
      return [];
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