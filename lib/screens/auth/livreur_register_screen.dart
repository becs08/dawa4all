import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth/auth_service.dart';
import '../../services/geolocalisation_service.dart';
import '../../models/livreur_model.dart';
import '../../providers/auth_provider.dart';

class LivreurRegisterScreen extends StatefulWidget {
  const LivreurRegisterScreen({Key? key}) : super(key: key);

  @override
  _LivreurRegisterScreenState createState() => _LivreurRegisterScreenState();
}

class _LivreurRegisterScreenState extends State<LivreurRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final GeolocationService _geoService = GeolocationService();

  // Contrôleurs de texte
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _cniController = TextEditingController();
  final _numeroPermisController = TextEditingController();
  final _plaqueVehiculeController = TextEditingController();

  // Variables d'état
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _accepteTermes = false;
  Position? _currentPosition;
  String _typeVehicule = 'moto';

  final List<String> _typesVehicules = [
    'moto',
    'scooter',
    'vélo',
    'voiture',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _cniController.dispose();
    _numeroPermisController.dispose();
    _plaqueVehiculeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await _geoService.getCurrentPosition();
      setState(() {});
    } catch (e) {
      print('Erreur géolocalisation: $e');
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_accepteTermes) {
      _showErrorDialog('Veuillez accepter les conditions d\'utilisation');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Utiliser AuthProvider comme pour l'inscription pharmacie
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.inscriptionLivreur(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nomComplet: '${_nomController.text.trim()} ${_prenomController.text.trim()}',
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
        ville: _villeController.text.trim(),
        cni: _cniController.text.trim(),
        numeroPermis: _numeroPermisController.text.trim(),
        typeVehicule: _typeVehicule,
        numeroVehicule: _plaqueVehiculeController.text.trim(),
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Erreur lors de l\'inscription: ${authProvider.errorMessage}');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de l\'inscription: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        title: const Text('Inscription réussie !'),
        content: const Text(
          'Votre demande d\'inscription a été soumise. Vous recevrez une notification une fois votre compte validé par notre équipe.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade500,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Devenir livreur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rejoignez notre équipe',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Formulaire
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Section informations personnelles
                          _buildSectionTitle('Informations personnelles', Icons.person),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _nomController,
                                  label: 'Nom',
                                  icon: Icons.person_outline,
                                  validator: (value) => value?.isEmpty == true ? 'Nom requis' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  controller: _prenomController,
                                  label: 'Prénom',
                                  icon: Icons.person_outline,
                                  validator: (value) => value?.isEmpty == true ? 'Prénom requis' : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Email requis';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _telephoneController,
                            label: 'Téléphone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Téléphone requis';
                              if (value!.length < 9) return 'Numéro invalide';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _cniController,
                            label: 'Numéro CNI',
                            icon: Icons.credit_card_outlined,
                            validator: (value) => value?.isEmpty == true ? 'CNI requise' : null,
                          ),

                          const SizedBox(height: 24),

                          // Section adresse
                          _buildSectionTitle('Adresse', Icons.location_on),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _adresseController,
                            label: 'Adresse complète',
                            icon: Icons.home_outlined,
                            validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _villeController,
                            label: 'Ville',
                            icon: Icons.location_city_outlined,
                            validator: (value) => value?.isEmpty == true ? 'Ville requise' : null,
                          ),

                          const SizedBox(height: 24),

                          // Section véhicule
                          _buildSectionTitle('Informations véhicule', Icons.delivery_dining),
                          const SizedBox(height: 16),

                          _buildDropdownField(
                            value: _typeVehicule,
                            label: 'Type de véhicule',
                            icon: Icons.two_wheeler_outlined,
                            items: _typesVehicules,
                            onChanged: (value) => setState(() => _typeVehicule = value!),
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _numeroPermisController,
                            label: 'Numéro de permis',
                            icon: Icons.credit_card,
                            validator: (value) => value?.isEmpty == true ? 'Permis requis' : null,
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _plaqueVehiculeController,
                            label: 'Plaque d\'immatriculation',
                            icon: Icons.confirmation_number_outlined,
                            validator: (value) => value?.isEmpty == true ? 'Plaque requise' : null,
                          ),

                          const SizedBox(height: 24),

                          // Section mot de passe
                          _buildSectionTitle('Sécurité', Icons.security),
                          const SizedBox(height: 16),

                          _buildTextField(
                            controller: _passwordController,
                            label: 'Mot de passe',
                            icon: Icons.lock_outlined,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Mot de passe requis';
                              if (value!.length < 6) return 'Au moins 6 caractères';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmer le mot de passe',
                            icon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Confirmation requise';
                              if (value != _passwordController.text) return 'Mots de passe différents';
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Localisation
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentPosition != null ? Icons.location_on : Icons.location_off,
                                  color: _currentPosition != null ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Localisation',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      Text(
                                        _currentPosition != null
                                            ? 'Position détectée'
                                            : 'Position non détectée',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_currentPosition == null)
                                  TextButton(
                                    onPressed: _getCurrentLocation,
                                    child: const Text('Réessayer'),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Conditions d'utilisation
                          CheckboxListTile(
                            value: _accepteTermes,
                            onChanged: (value) => setState(() => _accepteTermes = value!),
                            title: const Text(
                              'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                              style: TextStyle(fontSize: 14),
                            ),
                            activeColor: Colors.green,
                            dense: true,
                          ),

                          const SizedBox(height: 32),

                          // Bouton d'inscription
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                shadowColor: Colors.green.withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      'S\'inscrire comme livreur',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.green.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        fillColor: Colors.grey.shade100,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        fillColor: Colors.grey.shade100,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
    );
  }
}
