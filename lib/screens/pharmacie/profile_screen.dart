import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../models/pharmacie_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PharmacieService _pharmacieService = PharmacieService();
  PharmacieModel? _pharmacie;
  bool _isLoading = true;
  bool _isUpdating = false;

  final _nomPharmacieController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _licenseController = TextEditingController();

  final List<String> _joursSemaine = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];

  final List<String> _joursGardeOptions = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];

  Map<String, String> _horairesDetailles = {};
  Set<String> _joursGarde = {};
  bool _horaires24h = false;
  bool _estOuverte = true;

  @override
  void initState() {
    super.initState();
    _loadPharmacieProfile();
  }

  Future<void> _loadPharmacieProfile() async {
    try {
      final pharmacieId = _pharmacieService.currentPharmacieId;
      if (pharmacieId != null) {
        _pharmacieService.getPharmacie(pharmacieId).listen((pharmacie) {
          if (pharmacie != null && mounted) {
            setState(() {
              _pharmacie = pharmacie;
              _nomPharmacieController.text = pharmacie.nomPharmacie;
              _adresseController.text = pharmacie.adresse;
              _telephoneController.text = pharmacie.telephone ?? '';
              _licenseController.text = pharmacie.numeroLicense;
              
              _horairesDetailles = Map<String, String>.from(
                pharmacie.horairesDetailles ?? _getDefaultHoraires()
              );
              _joursGarde = Set<String>.from(pharmacie.joursGarde);
              _horaires24h = pharmacie.horaires24h;
              _estOuverte = pharmacie.estOuverte;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, String> _getDefaultHoraires() {
    return {
      'lundi': '08:00-20:00',
      'mardi': '08:00-20:00',
      'mercredi': '08:00-20:00',
      'jeudi': '08:00-20:00',
      'vendredi': '08:00-20:00',
      'samedi': '08:00-20:00',
      'dimanche': 'Fermé',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isUpdating ? null : _saveProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildStatusCard(),
            const SizedBox(height: 20),

            // Informations générales
            _buildSectionCard(
              'Informations générales',
              Icons.info,
              _buildGeneralInfo(),
            ),
            const SizedBox(height: 16),

            // Horaires
            _buildSectionCard(
              'Horaires d\'ouverture',
              Icons.access_time,
              _buildHorairesSection(),
            ),
            const SizedBox(height: 16),

            // Jours de garde
            _buildSectionCard(
              'Jours de garde',
              Icons.medical_services,
              _buildJoursGardeSection(),
            ),
            const SizedBox(height: 16),

            // Paramètres
            _buildSectionCard(
              'Paramètres',
              Icons.settings,
              _buildParametresSection(),
            ),
            const SizedBox(height: 16),

            // Actions
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _estOuverte ? Colors.green : Colors.red,
                  child: Icon(
                    Icons.local_pharmacy,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pharmacie?.nomPharmacie ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _estOuverte ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _estOuverte ? 'Ouvert' : 'Fermé',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_horaires24h)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '24h/24',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _estOuverte,
                  onChanged: (value) {
                    setState(() {
                      _estOuverte = value;
                    });
                    _updateStatutOuverture(value);
                  },
                  activeColor: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    return Column(
      children: [
        TextFormField(
          controller: _nomPharmacieController,
          decoration: const InputDecoration(
            labelText: 'Nom de la pharmacie',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _adresseController,
          decoration: const InputDecoration(
            labelText: 'Adresse',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _telephoneController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _licenseController,
          decoration: const InputDecoration(
            labelText: 'Numéro de licence',
            border: OutlineInputBorder(),
          ),
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildHorairesSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Ouvert 24h/24'),
          subtitle: const Text('Pharmacie ouverte en continu'),
          value: _horaires24h,
          onChanged: (value) {
            setState(() {
              _horaires24h = value;
              if (value) {
                // Si 24h/24, mettre tous les jours à 24h/24
                for (String jour in _joursSemaine) {
                  _horairesDetailles[jour] = '24h/24';
                }
              } else {
                // Revenir aux horaires par défaut
                _horairesDetailles = _getDefaultHoraires();
              }
            });
          },
          activeColor: Colors.green,
        ),
        if (!_horaires24h) ...[
          const SizedBox(height: 12),
          const Text(
            'Horaires par jour',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._joursSemaine.map((jour) => 
            _buildHoraireItem(jour, _horairesDetailles[jour] ?? 'Fermé')
          ).toList(),
        ],
      ],
    );
  }

  Widget _buildHoraireItem(String jour, String horaire) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              jour.capitalize(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _editHoraire(jour, horaire),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(horaire),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoursGardeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez les jours où votre pharmacie est de garde',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _joursGardeOptions.map((jour) => FilterChip(
            label: Text(jour.capitalize()),
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
            selectedColor: Colors.green.withOpacity(0.3),
            checkmarkColor: Colors.green,
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildParametresSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Gérer les notifications push'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Naviguer vers les paramètres de notification
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité en développement'),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.help),
          title: const Text('Aide & Support'),
          subtitle: const Text('Centre d\'aide et contact'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            // TODO: Naviguer vers l'aide
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fonctionnalité en développement'),
              ),
            );
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('À propos'),
          subtitle: const Text('Version de l\'application'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Dawa4All Pharmacie',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.local_pharmacy),
              children: [
                const Text('Application de gestion pour pharmacies partenaires Dawa4All'),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUpdating ? null : _saveProfile,
            icon: _isUpdating 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isUpdating ? 'Sauvegarde...' : 'Sauvegarder les modifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateStatutOuverture(bool ouvert) async {
    try {
      await _pharmacieService.changerStatutOuverture(ouvert);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ouvert ? 'Pharmacie ouverte' : 'Pharmacie fermée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
      // Revenir à l'état précédent
      setState(() {
        _estOuverte = !ouvert;
      });
    }
  }

  Future<void> _editHoraire(String jour, String horaireActuel) async {
    String? nouvelHoraire = await showDialog<String>(
      context: context,
      builder: (context) => _HoraireDialog(jour: jour, horaire: horaireActuel),
    );

    if (nouvelHoraire != null) {
      setState(() {
        _horairesDetailles[jour] = nouvelHoraire;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updates = {
        'nomPharmacie': _nomPharmacieController.text.trim(),
        'adresse': _adresseController.text.trim(),
        'telephonePharmacie': _telephoneController.text.trim(),
        'horairesDetailles': _horairesDetailles,
        'joursGarde': _joursGarde.toList(),
        'horaires24h': _horaires24h,
        'horairesOuverture': _horaires24h 
            ? '24h/24' 
            : _generateHorairesOuverture(),
        'estOuverte': _estOuverte,
      };

      await _pharmacieService.updatePharmacieProfil(updates);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  String _generateHorairesOuverture() {
    final joursOuverts = _horairesDetailles.entries
        .where((entry) => entry.value != 'Fermé' && entry.value != '24h/24')
        .toList();

    if (joursOuverts.isEmpty) return 'Fermé';
    
    // Prendre le premier horaire comme référence
    return joursOuverts.first.value;
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).deconnexion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomPharmacieController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}

class _HoraireDialog extends StatefulWidget {
  final String jour;
  final String horaire;

  const _HoraireDialog({
    required this.jour,
    required this.horaire,
  });

  @override
  __HoraireDialogState createState() => __HoraireDialogState();
}

class __HoraireDialogState extends State<_HoraireDialog> {
  late String _selectedHoraire;
  final _customController = TextEditingController();

  final List<String> _horairesPredefinis = [
    'Fermé',
    '08:00-20:00',
    '09:00-21:00',
    '08:00-22:00',
    '24h/24',
    'Personnalisé',
  ];

  @override
  void initState() {
    super.initState();
    _selectedHoraire = widget.horaire;
    if (!_horairesPredefinis.contains(widget.horaire)) {
      _selectedHoraire = 'Personnalisé';
      _customController.text = widget.horaire;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Horaires - ${widget.jour.capitalize()}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._horairesPredefinis.map((horaire) => RadioListTile<String>(
            title: Text(horaire),
            value: horaire,
            groupValue: _selectedHoraire,
            onChanged: (value) {
              setState(() {
                _selectedHoraire = value!;
              });
            },
          )).toList(),
          if (_selectedHoraire == 'Personnalisé')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _customController,
                decoration: const InputDecoration(
                  labelText: 'Horaire personnalisé',
                  hintText: 'Ex: 10:00-18:00',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            String result = _selectedHoraire;
            if (_selectedHoraire == 'Personnalisé') {
              result = _customController.text.trim();
            }
            Navigator.pop(context, result);
          },
          child: const Text('Valider'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}