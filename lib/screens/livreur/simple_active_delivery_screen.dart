import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../models/commande_model.dart';
import '../../services/firebase/livreur_service.dart';

class SimpleActiveDeliveryScreen extends StatefulWidget {
  const SimpleActiveDeliveryScreen({Key? key}) : super(key: key);

  @override
  _SimpleActiveDeliveryScreenState createState() => _SimpleActiveDeliveryScreenState();
}

class _SimpleActiveDeliveryScreenState extends State<SimpleActiveDeliveryScreen> {
  final LivreurService _livreurService = LivreurService();

  Future<void> _confirmPickup(String commandeId) async {
    try {
      await _livreurService.confirmerRecuperationCommande(commandeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Récupération confirmée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery(String commandeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la livraison'),
        content: const Text('Avez-vous bien livré la commande au client ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _livreurService.confirmerLivraison(commandeId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison confirmée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          // Retourner à l'écran principal
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _callClient(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  String _getClientAddress(CommandeModel commande) {
    if (commande.adresseLivraison.isNotEmpty) {
      return commande.adresseLivraison;
    } else if (commande.clientAdresse.isNotEmpty) {
      return commande.clientAdresse;
    } else {
      return 'Adresse non renseignée';
    }
  }

  Future<void> _openPharmacyInMaps(CommandeModel commande) async {
    String url = '';
    
    if (commande.pharmacieLocalisation != null) {
      // Utiliser les coordonnées GPS si disponibles
      final lat = commande.pharmacieLocalisation.latitude;
      final lng = commande.pharmacieLocalisation.longitude;
      url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    } else if (commande.pharmacieAdresse.isNotEmpty) {
      // Utiliser l'adresse comme fallback
      final address = Uri.encodeComponent(commande.pharmacieAdresse);
      url = 'https://www.google.com/maps/search/?api=1&query=$address';
    }
    
    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openClientInMaps(CommandeModel commande) async {
    String url = '';
    
    if (commande.clientLocalisation != null) {
      // Utiliser les coordonnées GPS si disponibles
      final lat = commande.clientLocalisation.latitude;
      final lng = commande.clientLocalisation.longitude;
      url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    } else {
      // Utiliser l'adresse comme fallback
      final address = _getClientAddress(commande);
      if (address != 'Adresse non renseignée') {
        final encodedAddress = Uri.encodeComponent(address);
        url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
      }
    }
    
    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraison en cours'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('livreurId', isEqualTo: authProvider.currentUser?.id)
            .where('statutCommande', whereIn: ['en_route_pharmacie', 'recuperee', 'en_route_client'])
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text('Erreur de chargement'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final commandes = snapshot.data?.docs
              .map((doc) => CommandeModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList() ?? [];

          if (commandes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Aucune livraison active'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final commande = commandes.first;
          final isPickedUp = commande.statutCommande == 'recuperee' || commande.statutCommande == 'en_route_client';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isPickedUp ? Colors.blue.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPickedUp ? Colors.blue.shade200 : Colors.green.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isPickedUp ? Icons.navigation : Icons.local_pharmacy,
                        color: isPickedUp ? Colors.blue.shade600 : Colors.green.shade600,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPickedUp ? 'Livraison en cours' : 'Récupération en cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPickedUp ? Colors.blue.shade700 : Colors.green.shade700,
                        ),
                      ),
                      Text(
                        isPickedUp 
                            ? 'Direction: ${commande.clientNom}'
                            : 'Direction: ${commande.pharmacieNom}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Informations pharmacie
                _buildInfoCardWithActions(
                  'Pharmacie',
                  Icons.local_pharmacy,
                  Colors.green,
                  [
                    _buildInfoRow('Nom', commande.pharmacieNom),
                    _buildInfoRow('Adresse', commande.pharmacieAdresse.isNotEmpty 
                        ? commande.pharmacieAdresse 
                        : 'Adresse non renseignée'),
                    if (commande.pharmacieLocalisation != null)
                      _buildInfoRow('Position', 
                        'Lat: ${commande.pharmacieLocalisation.latitude.toStringAsFixed(6)}, '
                        'Lng: ${commande.pharmacieLocalisation.longitude.toStringAsFixed(6)}'),
                  ],
                  actions: [
                    IconButton(
                      onPressed: () => _openPharmacyInMaps(commande),
                      icon: const Icon(Icons.navigation),
                      color: Colors.green.shade600,
                      tooltip: 'Ouvrir dans Maps',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations client
                _buildInfoCardWithActions(
                  'Client',
                  Icons.person,
                  Colors.orange,
                  [
                    _buildInfoRow('Nom', '${commande.clientNom} ${commande.clientPrenom}'),
                    _buildInfoRow('Téléphone', commande.clientTelephone.isNotEmpty 
                        ? commande.clientTelephone 
                        : 'Non renseigné'),
                    _buildInfoRow('Adresse', _getClientAddress(commande)),
                    if (commande.clientLocalisation != null)
                      _buildInfoRow('Position', 
                        'Lat: ${commande.clientLocalisation.latitude.toStringAsFixed(6)}, '
                        'Lng: ${commande.clientLocalisation.longitude.toStringAsFixed(6)}'),
                  ],
                  actions: [
                    IconButton(
                      onPressed: () => _callClient(commande.clientTelephone),
                      icon: const Icon(Icons.phone),
                      color: Colors.green.shade600,
                      tooltip: 'Appeler le client',
                    ),
                    IconButton(
                      onPressed: () => _openClientInMaps(commande),
                      icon: const Icon(Icons.navigation),
                      color: Colors.green.shade600,
                      tooltip: 'Ouvrir dans Maps',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Informations commande
                _buildInfoCard(
                  'Commande',
                  Icons.shopping_bag,
                  Colors.orange,
                  [
                    _buildInfoRow('Total', '${commande.total.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Frais livraison', '${commande.fraisLivraison.toStringAsFixed(0)} FCFA'),
                    _buildInfoRow('Articles', '${commande.items.isNotEmpty ? commande.items.length : commande.medicaments.length} médicament(s)'),
                    _buildInfoRow('Type', commande.typeLivraison == 'urgente' ? 'Urgente' : 'Standard'),
                  ],
                ),

                const SizedBox(height: 24),

                // Actions principales
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isPickedUp
                        ? () => _confirmDelivery(commande.id)
                        : () => _confirmPickup(commande.id),
                    icon: Icon(isPickedUp ? Icons.check_circle : Icons.inventory),
                    label: Text(isPickedUp ? 'Confirmer la livraison' : 'Confirmer récupération'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPickedUp ? Colors.green.shade600 : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<Widget> children) {
    return _buildInfoCardWithActions(title, icon, color, children);
  }

  Widget _buildInfoCardWithActions(String title, IconData icon, Color color, List<Widget> children, {List<Widget>? actions}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (actions != null) ...actions,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}