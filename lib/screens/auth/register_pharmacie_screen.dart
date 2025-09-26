import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';

class RegisterPharmacieScreen extends StatefulWidget {
  const RegisterPharmacieScreen({Key? key}) : super(key: key);

  @override
  _RegisterPharmacieScreenState createState() => _RegisterPharmacieScreenState();
}

class _RegisterPharmacieScreenState extends State<RegisterPharmacieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomGerantController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nomPharmacieController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _licenseController = TextEditingController();
  final _heuresOuvertureController = TextEditingController();
  final _heuresFermetureController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _mapsUrlController = TextEditingController();
  final _telephonePharmacieController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _est24h = false;
  bool _useGpsCoordinates = true; // true pour GPS, false pour Maps URL
  bool _useManualCoords = false; // Pour forcer la saisie manuelle avec URL courte
  
  // Horaires détaillés par jour
  final Map<String, String> _horairesDetailles = {
    'lundi': '08:00-22:00',
    'mardi': '08:00-22:00',
    'mercredi': '08:00-22:00',
    'jeudi': '08:00-22:00',
    'vendredi': '08:00-22:00',
    'samedi': '08:00-22:00',
    'dimanche': 'Fermé',
  };
  
  // Jours de garde
  final Set<String> _joursGarde = {};

  // Extraire les coordonnées depuis une URL Google Maps
  void _extractCoordinatesFromUrl(String url) {
    try {
      // Si c'est un lien court (maps.app.goo.gl), on informe l'utilisateur
      if (url.contains('maps.app.goo.gl') || url.contains('goo.gl')) {
        // Stocker l'URL pour l'utiliser plus tard
        _mapsUrlController.text = url;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ Lien court détecté. Veuillez saisir manuellement les coordonnées GPS.\nVous pouvez ouvrir le lien dans Google Maps pour les obtenir.'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Basculer en mode saisie manuelle
        setState(() {
          _useManualCoords = true;
        });
        return;
      }
      
      // Pattern pour Google Maps: https://maps.google.com/?q=lat,lng
      // ou https://www.google.com/maps/place/.../@lat,lng,zoom...
      // Supporte les coordonnées négatives
      RegExp latLngRegex = RegExp(r'[@/](-?\d+\.?\d*),\s*(-?\d+\.?\d*)');
      RegExp qRegex = RegExp(r'[?&]q=(-?\d+\.?\d*),\s*(-?\d+\.?\d*)');
      
      Match? match = latLngRegex.firstMatch(url) ?? qRegex.firstMatch(url);
      
      if (match != null) {
        _latitudeController.text = match.group(1) ?? '';
        _longitudeController.text = match.group(2) ?? '';
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Coordonnées extraites avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Impossible d\'extraire les coordonnées de cette URL'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur lors de l\'extraction des coordonnées'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Écouter les changements de l'URL pour afficher/cacher le message
    _mapsUrlController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nomGerantController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _nomPharmacieController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _licenseController.dispose();
    _heuresOuvertureController.dispose();
    _heuresFermetureController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _mapsUrlController.dispose();
    _telephonePharmacieController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inscription Pharmacie'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_pharmacy,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Inscription Pharmacie',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Inscrivez votre pharmacie sur la plateforme',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Section Gérant
                const Text(
                  'Informations du gérant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom du gérant
                TextFormField(
                  controller: _nomGerantController,
                  decoration: InputDecoration(
                    labelText: 'Nom complet du gérant',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom du gérant';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email et Téléphone
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email requis';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _telephoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Téléphone requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Section Pharmacie
                const Text(
                  'Informations de la pharmacie',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom de la pharmacie
                TextFormField(
                  controller: _nomPharmacieController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la pharmacie',
                    prefixIcon: const Icon(Icons.store),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom de la pharmacie';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Adresse et Ville
                TextFormField(
                  controller: _adresseController,
                  decoration: InputDecoration(
                    labelText: 'Adresse complète',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer l\'adresse';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _villeController,
                  decoration: InputDecoration(
                    labelText: 'Ville',
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la ville';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Téléphone de la pharmacie
                TextFormField(
                  controller: _telephonePharmacieController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone de la pharmacie',
                    prefixIcon: const Icon(Icons.phone_in_talk),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Téléphone de la pharmacie requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Choix méthode localisation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Localisation de la pharmacie',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('Coordonnées GPS'),
                              value: true,
                              groupValue: _useGpsCoordinates,
                              onChanged: (value) {
                                setState(() {
                                  _useGpsCoordinates = value!;
                                });
                              },
                              activeColor: const Color(0xFF2E7D32),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: const Text('URL Maps'),
                              value: false,
                              groupValue: _useGpsCoordinates,
                              onChanged: (value) {
                                setState(() {
                                  _useGpsCoordinates = value!;
                                });
                              },
                              activeColor: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Position GPS ou URL Maps
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Localisation de la pharmacie',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _useGpsCoordinates ? Icons.gps_fixed : Icons.link,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _useGpsCoordinates ? 'Mode GPS' : 'Mode URL Maps',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _useGpsCoordinates = !_useGpsCoordinates;
                                    });
                                  },
                                  child: Text(
                                    _useGpsCoordinates ? 'Changer vers URL' : 'Changer vers GPS',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _useGpsCoordinates 
                            ? 'Entrez directement les coordonnées GPS (supporte les valeurs négatives)'
                            : 'Collez l\'URL Google Maps de votre pharmacie ou entrez les coordonnées manuellement',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _useGpsCoordinates ? Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitudeController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          hintText: 'Ex: 14.7167 ou -14.7167',
                          prefixIcon: const Icon(Icons.gps_fixed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Latitude requise';
                          }
                          final lat = double.tryParse(value);
                          if (lat == null) {
                            return 'Latitude invalide';
                          }
                          if (lat < -90 || lat > 90) {
                            return 'Latitude doit être entre -90 et 90';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _longitudeController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          hintText: 'Ex: -17.4677 ou 17.4677',
                          prefixIcon: const Icon(Icons.gps_fixed),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Longitude requise';
                          }
                          final lng = double.tryParse(value);
                          if (lng == null) {
                            return 'Longitude invalide';
                          }
                          if (lng < -180 || lng > 180) {
                            return 'Longitude doit être entre -180 et 180';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ) : Column(
                  children: [
                    TextFormField(
                      controller: _mapsUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL Google Maps',
                        hintText: 'Ex: https://maps.app.goo.gl/...',
                        prefixIcon: const Icon(Icons.link),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Extraire coordonnées',
                          onPressed: () {
                            if (_mapsUrlController.text.isNotEmpty) {
                              _extractCoordinatesFromUrl(_mapsUrlController.text);
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ),
                    if (_mapsUrlController.text.contains('maps.app.goo.gl'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: InkWell(
                          onTap: () async {
                            final url = _mapsUrlController.text.trim();
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Lien court détecté. Tapez ici pour ouvrir dans Maps et récupérer les coordonnées.',
                                    style: TextStyle(fontSize: 12, color: Colors.blue),
                                  ),
                                ),
                                const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Latitude',
                              hintText: 'Ex: 14.7167',
                              prefixIcon: const Icon(Icons.gps_fixed),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Latitude requise';
                              }
                              final lat = double.tryParse(value);
                              if (lat == null) {
                                return 'Latitude invalide';
                              }
                              if (lat < -90 || lat > 90) {
                                return 'Latitude doit être entre -90 et 90';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: InputDecoration(
                              labelText: 'Longitude',
                              hintText: 'Ex: -17.4677',
                              prefixIcon: const Icon(Icons.gps_fixed),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Longitude requise';
                              }
                              final lng = double.tryParse(value);
                              if (lng == null) {
                                return 'Longitude invalide';
                              }
                              if (lng < -180 || lng > 180) {
                                return 'Longitude doit être entre -180 et 180';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Numéro de license
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de licence',
                    prefixIcon: const Icon(Icons.verified),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le numéro de licence';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Option 24h/24
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Horaires de fonctionnement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: const Text('Pharmacie 24h/24'),
                        subtitle: const Text('Ouverte en permanence'),
                        value: _est24h,
                        onChanged: (value) {
                          setState(() {
                            _est24h = value!;
                            if (_est24h) {
                              _heuresOuvertureController.text = '00:00';
                              _heuresFermetureController.text = '23:59';
                              // Mettre à jour tous les horaires détaillés
                              for (String jour in _horairesDetailles.keys) {
                                _horairesDetailles[jour] = '24h/24';
                              }
                            } else {
                              _heuresOuvertureController.text = '08:00';
                              _heuresFermetureController.text = '22:00';
                              // Remettre les horaires normaux
                              for (String jour in _horairesDetailles.keys) {
                                if (jour != 'dimanche') {
                                  _horairesDetailles[jour] = '08:00-22:00';
                                } else {
                                  _horairesDetailles[jour] = 'Fermé';
                                }
                              }
                            }
                          });
                        },
                        activeColor: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Horaires généraux (si pas 24h)
                if (!_est24h) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heuresOuvertureController,
                          decoration: InputDecoration(
                            labelText: 'Heure d\'ouverture générale',
                            prefixIcon: const Icon(Icons.access_time),
                            hintText: 'Ex: 08:00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                            ),
                          ),
                          validator: (value) {
                            if (!_est24h && (value == null || value.isEmpty)) {
                              return 'Heure requise';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _heuresFermetureController,
                          decoration: InputDecoration(
                            labelText: 'Heure de fermeture générale',
                            prefixIcon: const Icon(Icons.access_time),
                            hintText: 'Ex: 22:00',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                            ),
                          ),
                          validator: (value) {
                            if (!_est24h && (value == null || value.isEmpty)) {
                              return 'Heure requise';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Jours de garde
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jours de garde',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sélectionnez les jours où votre pharmacie assure la garde (service d\'urgence)',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        children: [
                          'dimanche', 'lundi', 'mardi', 'mercredi', 
                          'jeudi', 'vendredi', 'samedi'
                        ].map((jour) => Padding(
                          padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                          child: FilterChip(
                            label: Text(jour.toUpperCase()),
                            selected: _joursGarde.contains(jour),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _joursGarde.add(jour);
                                } else {
                                  _joursGarde.remove(jour);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF2E7D32).withOpacity(0.3),
                            checkmarkColor: const Color(0xFF2E7D32),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Section Sécurité
                const Text(
                  'Sécurité du compte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),

                // Mot de passe
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmation mot de passe
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Bouton d'inscription
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  // Validation des coordonnées GPS
                                  if (_latitudeController.text.isEmpty || _longitudeController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Veuillez saisir les coordonnées GPS ou extraire depuis une URL Maps'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }
                                  
                                  final success = await authProvider.inscriptionPharmacie(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text,
                                    nomGerant: _nomGerantController.text.trim(),
                                    telephone: _telephoneController.text.trim(),
                                    nomPharmacie: _nomPharmacieController.text.trim(),
                                    adresse: _adresseController.text.trim(),
                                    ville: _villeController.text.trim(),
                                    latitude: double.parse(_latitudeController.text),
                                    longitude: double.parse(_longitudeController.text),
                                    numeroLicense: _licenseController.text.trim(),
                                    heuresOuverture: _heuresOuvertureController.text.trim(),
                                    heuresFermeture: _heuresFermetureController.text.trim(),
                                    telephonePharmacie: _telephonePharmacieController.text.trim(),
                                    est24h: _est24h,
                                    horairesDetailles: Map<String, String>.from(_horairesDetailles),
                                    joursGarde: Set<String>.from(_joursGarde),
                                  );

                                  if (success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('🎉 Inscription pharmacie réussie ! Bienvenue sur Dawa4All'),
                                        backgroundColor: Colors.green,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                    
                                    // Attendre un peu pour que l'utilisateur voie le message
                                    await Future.delayed(const Duration(milliseconds: 1500));
                                    
                                    // Navigation vers le dashboard pharmacie
                                    if (mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/pharmacie/dashboard',
                                        (route) => false,
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(authProvider.errorMessage ??
                                            'Erreur lors de l\'inscription'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    authProvider.clearError();
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authProvider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'INSCRIRE LA PHARMACIE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Lien connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ? '),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
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
}