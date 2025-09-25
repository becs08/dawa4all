import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../models/pharmacie_model.dart';
import '../../models/medicament_model.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../providers/panier_provider.dart';
import 'package:intl/intl.dart';

class PharmacyDetailsScreen extends StatefulWidget {
  final PharmacieModel pharmacie;

  const PharmacyDetailsScreen({
    Key? key,
    required this.pharmacie,
  }) : super(key: key);

  @override
  State<PharmacyDetailsScreen> createState() => _PharmacyDetailsScreenState();
}

class _PharmacyDetailsScreenState extends State<PharmacyDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Medicament> _medicaments = [];
  bool _loadingMedicaments = true;
  String _selectedCategory = 'Tous';

  final PharmacieService _pharmacieService = PharmacieService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMedicaments();
    
    // Debug pour voir les données de la pharmacie
    print('🏥 Pharmacie ${widget.pharmacie.nomPharmacie}:');
    print('   - Horaires24h: ${widget.pharmacie.horaires24h}');
    print('   - HorairesOuverture: ${widget.pharmacie.horairesOuverture}');
    print('   - JoursGarde: ${widget.pharmacie.joursGarde}');
    print('   - JoursGarde.length: ${widget.pharmacie.joursGarde.length}');
    print('   - HorairesDetailles: ${widget.pharmacie.horairesDetailles}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMedicaments() async {
    try {
      _pharmacieService.getMedicamentsPharmacie(widget.pharmacie.id).listen((medicaments) {
        if (mounted) {
          setState(() {
            _medicaments = medicaments;
            _loadingMedicaments = false;
          });
        }
      });
    } catch (e) {
      print('Erreur lors du chargement des médicaments: $e');
      setState(() => _loadingMedicaments = false);
    }
  }

  List<Medicament> get _filteredMedicaments {
    if (_selectedCategory == 'Tous') return _medicaments;
    return _medicaments.where((m) => m.categorieEnum.nom == _selectedCategory).toList();
  }

  void _openMaps() async {
    final lat = widget.pharmacie.localisation.latitude;
    final lng = widget.pharmacie.localisation.longitude;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir Google Maps')),
      );
    }
  }

  void _callPharmacy() async {
    if (widget.pharmacie.telephone != null) {
      final url = 'tel:${widget.pharmacie.telephone}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  Color _getStatusColor() {
    switch (widget.pharmacie.couleurStatut) {
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'red': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar avec image de la pharmacie
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    if (widget.pharmacie.photoUrl != null)
                      Positioned.fill(
                        child: Image.network(
                          widget.pharmacie.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pharmacie.nomPharmacie,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.pharmacie.statutTexte,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < widget.pharmacie.note.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.pharmacie.nombreAvis})',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
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
          // Contenu principal
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Informations de contact
                _buildContactSection(),
                // Horaires et jours de garde
                _buildScheduleSection(),
                // Onglets
                _buildTabSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A47),
              ),
            ),
            const SizedBox(height: 16),
            // Adresse
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.pharmacie.adresse,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2E3A47),
                        ),
                      ),
                      Text(
                        widget.pharmacie.ville,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map, color: Color(0xFF2E7D32)),
                  tooltip: 'Voir sur la carte',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Téléphone
            if (widget.pharmacie.telephone != null)
              Row(
                children: [
                  const Icon(Icons.phone, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.pharmacie.telephone!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2E3A47),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _callPharmacy,
                    icon: const Icon(Icons.call, color: Color(0xFF2E7D32)),
                    tooltip: 'Appeler',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Horaires et jours de garde',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A47),
              ),
            ),
            const SizedBox(height: 16),
            // Horaires généraux
            if (widget.pharmacie.horaires24h)
              _buildScheduleRow('Horaires', 'Ouvert 24h/24', Icons.access_time)
            else if (widget.pharmacie.horairesOuverture != null && widget.pharmacie.horairesOuverture!.isNotEmpty)
              _buildScheduleRow('Horaires', widget.pharmacie.horairesOuverture!, Icons.access_time)
            else
              _buildScheduleRow('Horaires', '${widget.pharmacie.heuresOuverture} - ${widget.pharmacie.heuresFermeture}', Icons.access_time),

            const SizedBox(height: 8),

            // Jours de garde
            if (widget.pharmacie.joursGarde.isNotEmpty)
              _buildScheduleRow(
                'Jours de garde',
                widget.pharmacie.joursGarde.join(', '),
                Icons.medical_services,
                isGuardDay: true,
              ),

            // Prochains jours de garde
            if (widget.pharmacie.prochainsJoursGarde.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildScheduleRow(
                'Prochainement de garde',
                widget.pharmacie.prochainsJoursGarde.take(2).join(', '),
                Icons.upcoming,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleRow(String title, String value, IconData icon, {bool isGuardDay = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isGuardDay ? Colors.orange : const Color(0xFF2E7D32),
            size: 20
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isGuardDay ? Colors.orange : const Color(0xFF2E3A47),
                    fontWeight: isGuardDay ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              tabs: const [
                Tab(text: 'Catalogue'),
                Tab(text: 'À propos'),
              ],
            ),
          ),
          // Tab Content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCatalogTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    if (_loadingMedicaments) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
      );
    }

    if (_medicaments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Aucun médicament disponible',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _medicaments.length,
      itemBuilder: (context, index) {
        final medicament = _medicaments[index];
        return _buildMedicamentCard(medicament);
      },
    );
  }

  Widget _buildMedicamentCard(Medicament medicament) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/client/medicament-details',
          arguments: {
            'medicament': medicament,
            'pharmacie': widget.pharmacie,
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du médicament
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  medicament.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.medication, color: Colors.grey),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Informations du médicament
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicament.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E3A47),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      medicament.laboratoire,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (medicament.dosage != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        medicament.dosage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${medicament.prix.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton d'ajout au panier
              Consumer<PanierProvider>(
                builder: (context, panierProvider, child) {
                  return ElevatedButton(
                    onPressed: medicament.estDisponible && medicament.stock > 0
                        ? () {
                            panierProvider.ajouterAuPanier(medicament, widget.pharmacie);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${medicament.nom} ajouté au panier'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFF2E7D32),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: const Size(60, 36),
                    ),
                    child: const Icon(Icons.add_shopping_cart, size: 18, color: Colors.white),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Nom', widget.pharmacie.nomPharmacie),
          _buildInfoRow('Numéro de licence', widget.pharmacie.numeroLicense),
          if (widget.pharmacie.email != null)
            _buildInfoRow('Email', widget.pharmacie.email!),
          _buildInfoRow('Ville', widget.pharmacie.ville),
          if (widget.pharmacie.dateCreation != null)
            _buildInfoRow(
              'Créée le',
              DateFormat('dd/MM/yyyy').format(widget.pharmacie.dateCreation!),
            ),
          const SizedBox(height: 16),
          const Text(
            'Services disponibles',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A47),
            ),
          ),
          const SizedBox(height: 12),
          _buildServiceItem('Vente de médicaments', true),
          _buildServiceItem('Conseil pharmaceutique', true),
          _buildServiceItem('Livraison à domicile', true),
          if (widget.pharmacie.horaires24h)
            _buildServiceItem('Service 24h/24', true),
          if (widget.pharmacie.joursGarde.isNotEmpty)
            _buildServiceItem('Service de garde', true),
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
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2E3A47),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String service, bool available) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            service,
            style: TextStyle(
              fontSize: 14,
              color: available ? const Color(0xFF2E3A47) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
