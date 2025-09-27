import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../models/commande_model.dart';
import '../../services/firebase/livreur_service.dart';
import '../../services/geolocalisation_service.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  const ActiveDeliveryScreen({Key? key}) : super(key: key);

  @override
  _ActiveDeliveryScreenState createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final LivreurService _livreurService = LivreurService();
  final GeolocationService _geoService = GeolocationService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  CommandeModel? _currentDelivery;
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await _geoService.getCurrentPosition();
      if (mounted) {
        setState(() {});
        _updateMarkers();
      }
    } catch (e) {
      print('Erreur géolocalisation: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _getCurrentLocation();
    });
  }

  void _updateMarkers() {
    if (_currentPosition == null || _currentDelivery == null || !mounted) return;

    setState(() {
      _markers.clear();
      
      // Marqueur position livreur
      _markers.add(
        Marker(
          markerId: const MarkerId('livreur'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Ma position',
            snippet: 'Livreur',
          ),
        ),
      );

      // Marqueur pharmacie (utiliser adresse comme fallback)
      if (_currentDelivery!.pharmaciePosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pharmacie'),
            position: LatLng(
              _currentDelivery!.pharmaciePosition!.latitude,
              _currentDelivery!.pharmaciePosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: _currentDelivery!.pharmacieNom,
              snippet: 'Pharmacie',
            ),
          ),
        );
      }

      // Marqueur client (utiliser adresse comme fallback)
      if (_currentDelivery!.clientPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('client'),
            position: LatLng(
              _currentDelivery!.clientPosition!.latitude,
              _currentDelivery!.clientPosition!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: '${_currentDelivery!.clientNom} ${_currentDelivery!.clientPrenom}',
              snippet: 'Client',
            ),
          ),
        );
      }
    });
  }

  Future<void> _confirmPickup() async {
    if (_currentDelivery == null) return;

    try {
      await _livreurService.confirmerRecuperationCommande(_currentDelivery!.id);
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

  Future<void> _confirmDelivery() async {
    if (_currentDelivery == null) return;

    // Dialog de confirmation
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
        await _livreurService.confirmerLivraison(_currentDelivery!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Livraison confirmée avec succès !'),
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
  }

  Future<void> _callClient() async {
    if (_currentDelivery?.clientTelephone != null) {
      final url = 'tel:${_currentDelivery!.clientTelephone}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  Future<void> _openMaps() async {
    if (_currentDelivery?.clientPosition != null) {
      final lat = _currentDelivery!.clientPosition!.latitude;
      final lng = _currentDelivery!.clientPosition!.longitude;
      final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('commandes')
            .where('livreurId', isEqualTo: authProvider.currentUser?.id)
            .where('statut', whereIn: ['en_route_pharmacie', 'recuperee', 'en_route_client'])
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorScreen();
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          final commandes = snapshot.data?.docs
              .map((doc) => CommandeModel.fromMap(
                  doc.data() as Map<String, dynamic>, doc.id))
              .toList() ?? [];

          if (commandes.isEmpty) {
            return _buildNoDeliveryScreen();
          }

          _currentDelivery = commandes.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMarkers();
          });

          return _buildActiveDeliveryScreen();
        },
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.red.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Erreur', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade700, Colors.red.shade500],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur de chargement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.green.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Chargement...', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade500],
                  ),
                ),
              ),
            ),
          ),
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDeliveryScreen() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.grey.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Aucune livraison', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade700, Colors.grey.shade500],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping_outlined, 
                         size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune livraison en cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Acceptez une livraison pour commencer',
                      style: TextStyle(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDeliveryScreen() {
    if (_currentDelivery == null) {
      return _buildLoadingScreen();
    }
    
    final isPickedUp = _currentDelivery!.statut == 'recuperee' || _currentDelivery!.statut == 'en_route_client';
    
    return Scaffold(
      body: Column(
        children: [
          // Carte Google Maps
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                _currentPosition != null 
                  ? GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          ),
                        );
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                        zoom: 15,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                
                // Status overlay
                Positioned(
                  top: 50,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isPickedUp ? Colors.blue.shade100 : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isPickedUp ? Icons.navigation : Icons.local_pharmacy,
                            color: isPickedUp ? Colors.blue.shade600 : Colors.green.shade600,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPickedUp ? 'Livraison en cours' : 'Récupération en cours',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                isPickedUp 
                                    ? 'Direction: ${_currentDelivery?.clientNom}'
                                    : 'Direction: ${_currentDelivery?.pharmacieNom}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Informations de livraison
          Expanded(
            flex: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header avec prix
                    Row(
                      children: [
                        const Text(
                          'Commande en cours',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentDelivery?.total.toStringAsFixed(0) ?? "0"} FCFA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Informations client
                    _buildInfoCard(
                      'Client',
                      Icons.person,
                      Colors.orange,
                      [
                        _buildInfoRow('Nom', '${_currentDelivery?.clientNom} ${_currentDelivery?.clientPrenom}'),
                        _buildInfoRow('Téléphone', _currentDelivery?.clientTelephone ?? ''),
                        _buildInfoRow('Adresse', _currentDelivery?.adresseLivraison ?? ''),
                      ],
                      actions: [
                        IconButton(
                          onPressed: _callClient,
                          icon: const Icon(Icons.phone),
                          color: Colors.green.shade600,
                          tooltip: 'Appeler le client',
                        ),
                        IconButton(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.navigation),
                          color: Colors.blue.shade600,
                          tooltip: 'Ouvrir dans Maps',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Informations pharmacie
                    if (!isPickedUp) ...[
                      _buildInfoCard(
                        'Pharmacie',
                        Icons.local_pharmacy,
                        Colors.green,
                        [
                          _buildInfoRow('Nom', _currentDelivery?.pharmacieNom ?? ''),
                          _buildInfoRow('Adresse', _currentDelivery?.pharmacieAdresse ?? ''),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Boutons d'action
                    if (!isPickedUp) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmPickup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirmer la récupération',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _confirmDelivery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirmer la livraison',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, Color color, List<Widget> children, {List<Widget>? actions}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
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