import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/livreur_model.dart';
import '../../models/commande_model.dart';
import '../../services/firebase/livreur_service.dart';

class LivreurDetailsScreen extends StatefulWidget {
  final LivreurModel livreur;

  const LivreurDetailsScreen({
    Key? key,
    required this.livreur,
  }) : super(key: key);

  @override
  _LivreurDetailsScreenState createState() => _LivreurDetailsScreenState();
}

class _LivreurDetailsScreenState extends State<LivreurDetailsScreen> {
  final LivreurService _livreurService = LivreurService();
  List<CommandeModel> _historiqueCommandes = [];
  Map<String, dynamic>? _statistiques;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await _livreurService.getStatistiquesLivreur(widget.livreur.id);
      final historique = await _livreurService.getHistoriqueLivraisons(widget.livreur.id).first;
      
      setState(() {
        _statistiques = stats;
        _historiqueCommandes = historique.take(5).toList(); // Dernières 5 commandes
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement données: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _callLivreur() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.livreur.telephone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _showNotationDialog() {
    double note = 5.0;
    String commentaire = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Noter ${widget.livreur.prenom}'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Donnez une note sur 5 étoiles :'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        note = index + 1.0;
                      });
                    },
                    icon: Icon(
                      index < note ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => commentaire = value,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _noterLivreur(note, commentaire);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Noter'),
          ),
        ],
      ),
    );
  }

  Future<void> _noterLivreur(double note, String commentaire) async {
    try {
      // Calculer la nouvelle note moyenne
      final ancienneNote = widget.livreur.note;
      final nombreAvis = widget.livreur.nombreAvis;
      final nouvelleNote = ((ancienneNote * nombreAvis) + note) / (nombreAvis + 1);

      // Mettre à jour dans Firestore
      await FirebaseFirestore.instance
          .collection('livreurs')
          .doc(widget.livreur.id)
          .update({
        'note': nouvelleNote,
        'nombreAvis': nombreAvis + 1,
      });

      // Sauvegarder le commentaire si fourni
      if (commentaire.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('avis_livreurs')
            .add({
          'livreurId': widget.livreur.id,
          'note': note,
          'commentaire': commentaire,
          'date': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note enregistrée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      _loadData(); // Recharger les données
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
        title: Text(widget.livreur.prenom),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _callLivreur,
            icon: const Icon(Icons.phone),
          ),
          IconButton(
            onPressed: _showNotationDialog,
            icon: const Icon(Icons.star_border),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header avec photo et infos principales
                  _buildHeader(),
                  
                  // Statistiques
                  _buildStatistiques(),
                  
                  // Informations détaillées
                  _buildInformations(),
                  
                  // Historique récent
                  _buildHistorique(),
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
        ),
      ),
      child: Column(
        children: [
          // Photo de profil
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Nom et statut
          Text(
            widget.livreur.nomComplet,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Note et livraisons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.livreur.note.toStringAsFixed(1)} (${widget.livreur.nombreAvis} avis)',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 20),
              Icon(Icons.local_shipping, color: Colors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.livreur.nombreLivraisons} livraisons',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistiques() {
    if (_statistiques == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques de performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Revenus totaux',
                  '${_statistiques!['totalRevenus']?.toInt() ?? 0} FCFA',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Revenu moyen',
                  '${_statistiques!['revenuMoyen']?.toInt() ?? 0} FCFA',
                  Icons.trending_up,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Temps moyen',
                  '${_statistiques!['tempsMoyen']?.toInt() ?? 0} min',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Taux succès',
                  '${(_statistiques!['tauxReussite'] ?? 0).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInformations() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations détaillées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(Icons.email, 'Email', widget.livreur.email),
          _buildInfoRow(Icons.phone, 'Téléphone', widget.livreur.telephone),
          _buildInfoRow(Icons.location_on, 'Adresse', widget.livreur.adresse),
          _buildInfoRow(Icons.location_city, 'Ville', widget.livreur.ville),
          _buildInfoRow(Icons.credit_card, 'CNI', widget.livreur.cni),
          _buildInfoRow(Icons.two_wheeler, 'Véhicule', '${widget.livreur.typeVehicule} - ${widget.livreur.plaqueVehicule}'),
          _buildInfoRow(Icons.credit_card_outlined, 'Permis', widget.livreur.numeroPermis),
          _buildInfoRow(Icons.calendar_today, 'Inscrit le', _formatDate(widget.livreur.dateInscription)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.green.shade600, size: 20),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorique() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Livraisons récentes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_historiqueCommandes.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: Voir tout l'historique
                  },
                  child: const Text('Voir tout'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_historiqueCommandes.isEmpty)
            const Center(
              child: Text(
                'Aucune livraison récente',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(_historiqueCommandes.map((commande) => _buildCommandeItem(commande))),
        ],
      ),
    );
  }

  Widget _buildCommandeItem(CommandeModel commande) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getCommandeStatusColor(commande.statutCommande),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCommandeStatusIcon(commande.statutCommande),
              color: Colors.white,
              size: 16,
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${commande.fraisLivraison.toInt()} FCFA',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          Text(
            _formatDate(commande.dateLivraison ?? commande.dateCommande),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
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
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _callLivreur,
              icon: const Icon(Icons.phone),
              label: const Text('Appeler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green.shade600),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          if (widget.livreur.estDisponible && widget.livreur.statut == 'actif')
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Attribuer une commande
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fonctionnalité d\'attribution à venir'),
                    ),
                  );
                },
                icon: const Icon(Icons.local_shipping),
                label: const Text('Attribuer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (widget.livreur.statut != 'actif') return Colors.grey;
    return widget.livreur.estDisponible ? Colors.green : Colors.orange;
  }

  String _getStatusText() {
    switch (widget.livreur.statut) {
      case 'en_attente_validation':
        return 'En attente de validation';
      case 'actif':
        return widget.livreur.estDisponible ? 'Disponible' : 'Indisponible';
      case 'suspendu':
        return 'Suspendu';
      case 'en_livraison':
        return 'En livraison';
      default:
        return 'Inconnu';
    }
  }

  Color _getCommandeStatusColor(String status) {
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

  IconData _getCommandeStatusIcon(String status) {
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 7) {
      return 'Il y a ${difference.inDays} jours';
    } else if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return 'Récemment';
    }
  }
}