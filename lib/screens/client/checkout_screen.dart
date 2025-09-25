import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/panier_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/client_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final PageController _pageController = PageController();
  final ClientService _clientService = ClientService();
  
  int _currentStep = 0;
  String _modePaiement = '';
  File? _ordonnanceImage;
  bool _isLoading = false;

  final List<String> _steps = [
    'Vérification',
    'Ordonnance',
    'Paiement',
    'Confirmation',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_steps.length, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index <= _currentStep
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade300,
                        ),
                        child: Center(
                          child: index < _currentStep
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: index <= _currentStep ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _steps[index],
                        style: TextStyle(
                          fontSize: 10,
                          color: index <= _currentStep
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildVerificationStep(),
          _buildOrdonnanceStep(),
          _buildPaiementStep(),
          _buildConfirmationStep(),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Consumer<PanierProvider>(
      builder: (context, panierProvider, _) {
        if (panierProvider.panier.isEmpty) {
          return const Center(
            child: Text('Panier vide'),
          );
        }

        final pharmacie = panierProvider.getPharmacie()!;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Information pharmacie
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_pharmacy,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacie.nomPharmacie,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              pharmacie.adresse,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text('${pharmacie.note}/5'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Résumé commande
              const Text(
                'Résumé de la commande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ...panierProvider.panier.map((item) => Card(
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.medicament.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.medication),
                        );
                      },
                    ),
                  ),
                  title: Text(item.medicament.nom),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantité: ${item.quantite}'),
                      if (item.medicament.necessite0rdonnance)
                        const Text(
                          'Ordonnance requise',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    '${item.sousTotal} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
              )).toList(),

              const SizedBox(height: 20),
              
              // Total
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total:'),
                          Text('${panierProvider.calculerTotal()} FCFA'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de livraison:'),
                          const Text('À calculer'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total estimé:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${panierProvider.calculerTotal()} FCFA +',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _nextStep(),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrdonnanceStep() {
    return Consumer<PanierProvider>(
      builder: (context, panierProvider, _) {
        final besoinOrdonnance = panierProvider.besoinOrdonnance();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (besoinOrdonnance) ...[
                const Icon(
                  Icons.medical_services,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ordonnance médicale requise',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Certains médicaments de votre commande nécessitent une ordonnance médicale. Veuillez prendre une photo claire de votre ordonnance.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),

                // Médicaments avec ordonnance
                const Text(
                  'Médicaments concernés:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                ...panierProvider.getMedicamentsAvecOrdonnance().map((item) =>
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.medication, color: Colors.orange),
                      title: Text(item.medicament.nom),
                      subtitle: Text('Quantité: ${item.quantite}'),
                    ),
                  ),
                ).toList(),

                const SizedBox(height: 30),

                // Upload ordonnance
                if (_ordonnanceImage == null)
                  SizedBox(
                    width: double.infinity,
                    height: 120,
                    child: OutlinedButton.icon(
                      onPressed: _pickOrdonnanceImage,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                      icon: const Icon(Icons.camera_alt, color: Colors.orange),
                      label: const Text(
                        'Prendre une photo de l\'ordonnance',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                          ),
                          child: Image.file(
                            _ordonnanceImage!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: _pickOrdonnanceImage,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Changer'),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _ordonnanceImage = null;
                                  });
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 80,
                        color: Colors.green,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Aucune ordonnance requise',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tous les médicaments de votre commande sont disponibles sans ordonnance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 40),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _previousStep(),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (besoinOrdonnance && _ordonnanceImage == null)
                          ? null
                          : () => _nextStep(),
                      child: const Text('Continuer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaiementStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode de paiement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // Options de paiement
          _buildPaymentOption(
            'Wave',
            'assets/wave.png',
            'wave',
          ),
          _buildPaymentOption(
            'Orange Money',
            'assets/orangemoney.png',
            'om',
          ),
          _buildPaymentOption(
            'Paiement à la livraison',
            null,
            'cash',
            icon: Icons.money,
          ),

          const Spacer(),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _previousStep(),
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _modePaiement.isEmpty ? null : () => _nextStep(),
                  child: const Text('Continuer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Consumer<PanierProvider>(
      builder: (context, panierProvider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Récapitulatif',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              _buildSummaryRow('Articles:', '${panierProvider.getNombreArticles()}'),
              _buildSummaryRow('Pharmacie:', panierProvider.getPharmacie()!.nomPharmacie),
              _buildSummaryRow('Mode de paiement:', _getPaymentMethodName()),
              if (_ordonnanceImage != null)
                _buildSummaryRow('Ordonnance:', 'Fournie ✓'),
              _buildSummaryRow('Montant:', '${panierProvider.calculerTotal()} FCFA'),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Votre commande sera transmise à la pharmacie pour validation. Vous recevrez une notification avec le montant final incluant les frais de livraison.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _previousStep(),
                      child: const Text('Retour'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _finaliserCommande,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Finaliser la commande'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOption(String title, String? assetPath, String value, {IconData? icon}) {
    return Card(
      child: RadioListTile<String>(
        value: value,
        groupValue: _modePaiement,
        onChanged: (String? val) {
          setState(() {
            _modePaiement = val!;
          });
        },
        title: Row(
          children: [
            if (assetPath != null)
              Image.asset(assetPath, height: 30, width: 30)
            else if (icon != null)
              Icon(icon, size: 30),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickOrdonnanceImage() async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _ordonnanceImage = File(image.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1000,
                    maxHeight: 1000,
                    imageQuality: 80,
                  );
                  if (image != null) {
                    setState(() {
                      _ordonnanceImage = File(image.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _finaliserCommande() async {
    print('🚀 Début finalisation commande...');
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final panierProvider = Provider.of<PanierProvider>(context, listen: false);
      
      print('👤 Vérification utilisateur connecté...');
      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final user = authProvider.currentUser!;
      print('✅ Utilisateur: ${user.id}');
      
      // Récupérer le ClientModel depuis Firebase
      print('📞 Récupération des données client...');
      final client = await _clientService.getClientById(user.id);
      if (client == null) {
        throw Exception('Données client non trouvées');
      }
      print('✅ Client trouvé: ${client.nomComplet}');
      
      final pharmacie = panierProvider.getPharmacie();
      if (pharmacie == null) {
        throw Exception('Aucune pharmacie sélectionnée');
      }
      print('✅ Pharmacie: ${pharmacie.nomPharmacie}');
      
      final items = panierProvider.getItemsCommande();
      if (items.isEmpty) {
        throw Exception('Panier vide');
      }
      print('✅ ${items.length} articles dans la commande');
      
      final montantTotal = panierProvider.calculerTotal();
      print('💰 Montant total: ${montantTotal}');
      
      // Frais de livraison par défaut (peut être calculé selon la distance)
      final fraisLivraison = 1000.0;
      
      // Créer d'abord la commande
      print('📝 Création de la commande...');
      final commandeId = await _clientService.creerCommande(
        clientId: user.id,
        client: client,
        pharmacieId: pharmacie.id,
        pharmacie: pharmacie,
        items: items,
        montantTotal: montantTotal,
        fraisLivraison: fraisLivraison,
        modePaiement: _modePaiement,
        paiementEffectue: _modePaiement != 'cash', // Si ce n'est pas cash, c'est "payé"
        ordonnanceUrl: null, // On va l'ajouter après
      );
      
      if (commandeId == null) {
        throw Exception('Erreur lors de la création de la commande');
      }
      print('✅ Commande créée: $commandeId');
      
      // Uploader l'ordonnance si nécessaire avec l'ID réel de la commande
      if (_ordonnanceImage != null) {
        print('📷 Upload ordonnance...');
        print('🗂️ Fichier ordonnance: ${_ordonnanceImage!.path}');
        print('📊 Taille fichier: ${await _ordonnanceImage!.length()} bytes');
        
        try {
          final ordonnanceUrl = await _clientService.uploaderOrdonnance(commandeId, _ordonnanceImage!);
          if (ordonnanceUrl == null) {
            print('⚠️ Erreur upload ordonnance, mais commande créée');
            // Continuer quand même, l'ordonnance peut être ajoutée plus tard
          } else {
            print('✅ Ordonnance uploadée: $ordonnanceUrl');
          }
        } catch (e) {
          print('⚠️ Erreur upload ordonnance (Firebase Storage): $e');
          print('📋 Commande créée sans ordonnance - peut être ajoutée plus tard');
          // Ne pas bloquer le processus de commande pour un problème d'upload
        }
      } else {
        print('📷 Aucune ordonnance à uploader');
      }

      // Vider le panier
      print('🧹 Vidage du panier...');
      panierProvider.viderPanier();

      print('🎉 Commande finalisée avec succès !');
      
      // Naviguer vers la confirmation
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/client/home');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erreur finalisation commande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // S'assurer que le loading se désactive même en cas d'erreur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPaymentMethodName() {
    switch (_modePaiement) {
      case 'wave':
        return 'Wave';
      case 'om':
        return 'Orange Money';
      case 'cash':
        return 'Paiement à la livraison';
      default:
        return '';
    }
  }
}