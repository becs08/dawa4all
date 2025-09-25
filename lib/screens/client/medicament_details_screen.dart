import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/medicament_model.dart';
import '../../models/pharmacie_model.dart';
import '../../providers/panier_provider.dart';

class MedicamentDetailsScreen extends StatefulWidget {
  final dynamic medicament; // Peut être Medicament ou Map<String, dynamic>
  final PharmacieModel? pharmacie;

  const MedicamentDetailsScreen({
    Key? key,
    required this.medicament,
    this.pharmacie,
  }) : super(key: key);

  @override
  State<MedicamentDetailsScreen> createState() => _MedicamentDetailsScreenState();
}

class _MedicamentDetailsScreenState extends State<MedicamentDetailsScreen> {
  
  // Helpers pour accéder aux propriétés selon le type
  String get _nom {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).nom
        : widget.medicament['nom'] ?? 'Médicament';
  }
  
  String get _imageUrl {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).imageUrl
        : widget.medicament['image'] ?? '';
  }
  
  double get _prix {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).prix
        : (widget.medicament['prix'] ?? 0).toDouble();
  }
  
  String get _laboratoire {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).laboratoire
        : 'Laboratoire';
  }
  
  String get _description {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).description
        : 'Description du médicament';
  }
  
  bool get _necessiteOrdonnance {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).necessite0rdonnance
        : widget.medicament['ordonnance'] ?? false;
  }
  
  String get _categorie {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).categorieEnum.nom
        : widget.medicament['category'] ?? 'Autre';
  }
  
  bool get _estDisponible {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).estDisponible
        : true; // Les médicaments populaires sont considérés comme disponibles
  }
  
  int get _stock {
    return widget.medicament is Medicament 
        ? (widget.medicament as Medicament).stock
        : 10; // Stock fictif pour les médicaments populaires
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar avec image du médicament
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Consumer<PanierProvider>(
                builder: (context, panierProvider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white),
                        onPressed: () {
                          Navigator.pushNamed(context, '/client/cart');
                        },
                      ),
                      if (panierProvider.panier.isNotEmpty)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '${panierProvider.panier.length}',
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
                  );
                },
              ),
            ],
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    // Image du médicament
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.medication,
                                size: 80,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nom du médicament
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _nom,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Laboratoire
                    Text(
                      _laboratoire,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contenu principal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut et prix
                  _buildStatusPriceCard(),
                  const SizedBox(height: 16),
                  
                  // Informations détaillées
                  _buildDetailsCard(),
                  const SizedBox(height: 16),
                  
                  // Description
                  _buildDescriptionCard(),
                  const SizedBox(height: 16),
                  
                  // Instructions et contre-indications
                  if ((widget.medicament is Medicament && 
                      ((widget.medicament as Medicament).modeEmploi != null || 
                       (widget.medicament as Medicament).contreIndications.isNotEmpty)))
                    _buildInstructionsCard(),
                  
                  const SizedBox(height: 100), // Espace pour le bouton fixe
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildStatusPriceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Prix',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_prix.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          
          // Statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _estDisponible ? const Color(0xFF2E7D32) : Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _estDisponible ? 'En stock' : 'Indisponible',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Stock: ${_stock}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations détaillées',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A47),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildDetailRow('Catégorie', _categorie),
          if (widget.medicament is Medicament && (widget.medicament as Medicament).dosage != null)
            _buildDetailRow('Dosage', (widget.medicament as Medicament).dosage!),
          if (widget.medicament is Medicament && (widget.medicament as Medicament).formePharmaceutique != null)
            _buildDetailRow('Forme', (widget.medicament as Medicament).formePharmaceutique!),
          _buildDetailRow(
            'Ordonnance requise', 
            _necessiteOrdonnance ? 'Oui' : 'Non'
          ),
          if (widget.medicament is Medicament && (widget.medicament as Medicament).dateExpiration != null)
            _buildDetailRow(
              'Expiration', 
              '${(widget.medicament as Medicament).dateExpiration!.day}/${(widget.medicament as Medicament).dateExpiration!.month}/${(widget.medicament as Medicament).dateExpiration!.year}'
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A47),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions et précautions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A47),
            ),
          ),
          const SizedBox(height: 16),
          
          // Mode d'emploi (seulement pour les vrais objets Medicament)
          if (widget.medicament is Medicament && (widget.medicament as Medicament).modeEmploi != null) ...[
            const Text(
              'Mode d\'emploi:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (widget.medicament as Medicament).modeEmploi!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Contre-indications (seulement pour les vrais objets Medicament)
          if (widget.medicament is Medicament && (widget.medicament as Medicament).contreIndications.isNotEmpty) ...[
            const Text(
              'Contre-indications:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            ...(widget.medicament as Medicament).contreIndications.map((contraIndication) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.red)),
                    Expanded(
                      child: Text(
                        contraIndication,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).toList(),
          ],
        ],
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
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<PanierProvider>(
          builder: (context, panierProvider, child) {
            return SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _estDisponible && _stock > 0
                    ? () {
                        if (widget.pharmacie != null && widget.medicament is Medicament) {
                          // Ajouter au panier depuis une pharmacie spécifique
                          panierProvider.ajouterAuPanier(widget.medicament as Medicament, widget.pharmacie!);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${_nom} ajouté au panier'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFF2E7D32),
                              action: SnackBarAction(
                                label: 'Voir panier',
                                textColor: Colors.white,
                                onPressed: () {
                                  Navigator.pushNamed(context, '/client/cart');
                                },
                              ),
                            ),
                          );
                        } else {
                          // Médicament populaire - rediriger vers les pharmacies
                          Navigator.pushNamed(context, '/client/pharmacies');
                        }
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  _estDisponible && _stock > 0
                      ? widget.pharmacie != null && widget.medicament is Medicament
                          ? 'Ajouter au panier'
                          : 'Voir pharmacies'
                      : _stock == 0 
                          ? 'Rupture de stock'
                          : 'Non disponible',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _estDisponible && _stock > 0 
                      ? const Color(0xFF2E7D32)
                      : Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}