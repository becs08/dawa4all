import 'package:flutter/material.dart';
import '../../services/firebase/pharmacie_service.dart';
import '../../models/medicament_model.dart';

class AddMedicamentScreen extends StatefulWidget {
  const AddMedicamentScreen({Key? key}) : super(key: key);

  @override
  _AddMedicamentScreenState createState() => _AddMedicamentScreenState();
}

class _AddMedicamentScreenState extends State<AddMedicamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final PharmacieService _pharmacieService = PharmacieService();
  bool _isLoading = false;
  
  // Controllers pour tous les champs
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _stockController = TextEditingController();
  final _laboratoireController = TextEditingController();
  final _dosageController = TextEditingController();
  final _modeEmploiController = TextEditingController();
  final _contreIndicationsController = TextEditingController();
  final _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'Antalgiques';
  String _formePharmaceutique = 'Comprimé';
  bool _ordonnanceRequise = false;
  DateTime? _dateExpiration;
  
  final List<String> _categories = [
    'Antalgiques',
    'Antibiotiques',
    'Anti-inflammatoires',
    'Vitamines',
    'Digestifs',
    'Cardiovasculaires',
    'Respiratoires',
    'Dermatologiques',
    'Ophtalmologiques',
    'Autres'
  ];

  final List<String> _formesPharmaceutiques = [
    'Comprimé',
    'Gélule', 
    'Sirop',
    'Solution buvable',
    'Ampoule injectable',
    'Suppositoire',
    'Pommade',
    'Crème',
    'Gel',
    'Collyre',
    'Spray nasal',
    'Inhalateur',
    'Patch',
    'Autre'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar moderne avec gradient
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.green.shade600,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Nouveau Médicament',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green.shade700,
                      Colors.green.shade500,
                      Colors.green.shade400,
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveMedicament,
                ),
            ],
          ),

          // Contenu du formulaire
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Informations de base
                      _buildSectionHeader(
                        'Informations de base',
                        Icons.info_outline,
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),

                      // Layout responsive
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Layout tablet/desktop
                            return _buildDesktopLayout();
                          } else {
                            // Layout mobile
                            return _buildMobileLayout();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        // Première ligne - nom et catégorie
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildModernTextField(
                controller: _nomController,
                label: 'Nom du médicament',
                icon: Icons.medication,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernDropdown(
                value: _selectedCategory,
                label: 'Catégorie',
                icon: Icons.category,
                items: _categories,
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Deuxième ligne - laboratoire et dosage
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _laboratoireController,
                label: 'Laboratoire',
                icon: Icons.business,
                hint: 'Ex: Pfizer, Sanofi, etc.',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _dosageController,
                label: 'Dosage',
                icon: Icons.science,
                hint: 'Ex: 500mg, 10ml, etc.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Description
        _buildModernTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          maxLines: 3,
          hint: 'Décrivez brièvement le médicament et ses indications',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Détails pharmaceutiques',
          Icons.medical_services,
          Colors.purple,
        ),
        const SizedBox(height: 16),

        // Ligne forme et prix
        Row(
          children: [
            Expanded(
              child: _buildModernDropdown(
                value: _formePharmaceutique,
                label: 'Forme pharmaceutique',
                icon: Icons.medical_services,
                items: _formesPharmaceutiques,
                onChanged: (value) {
                  setState(() {
                    _formePharmaceutique = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _prixController,
                label: 'Prix (FCFA)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stock et URL image
        Row(
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: _stockController,
                label: 'Stock initial',
                icon: Icons.inventory,
                keyboardType: TextInputType.number,
                required: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ce champ est obligatoire';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Nombre entier requis';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: _imageUrlController,
                label: 'URL de l\'image',
                icon: Icons.image,
                hint: 'Lien vers l\'image du médicament',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Mode d'emploi
        _buildModernTextField(
          controller: _modeEmploiController,
          label: 'Mode d\'emploi',
          icon: Icons.help_outline,
          maxLines: 3,
          hint: 'Instructions d\'utilisation du médicament',
        ),
        const SizedBox(height: 16),

        // Contre-indications
        _buildModernTextField(
          controller: _contreIndicationsController,
          label: 'Contre-indications',
          icon: Icons.warning,
          maxLines: 3,
          hint: 'Situations où le médicament ne doit pas être utilisé (séparées par des virgules)',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Options avancées',
          Icons.settings,
          Colors.orange,
        ),
        const SizedBox(height: 16),

        // Date expiration et ordonnance
        Row(
          children: [
            Expanded(
              child: _buildDateField(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOrdonnanceSwitch(),
            ),
          ],
        ),
        const SizedBox(height: 30),

        // Bouton sauvegarder
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildModernTextField(
          controller: _nomController,
          label: 'Nom du médicament',
          icon: Icons.medication,
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildModernDropdown(
          value: _selectedCategory,
          label: 'Catégorie',
          icon: Icons.category,
          items: _categories,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _laboratoireController,
          label: 'Laboratoire',
          icon: Icons.business,
          hint: 'Ex: Pfizer, Sanofi, etc.',
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          maxLines: 3,
          hint: 'Décrivez brièvement le médicament et ses indications',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Détails pharmaceutiques',
          Icons.medical_services,
          Colors.purple,
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _dosageController,
          label: 'Dosage',
          icon: Icons.science,
          hint: 'Ex: 500mg, 10ml, etc.',
        ),
        const SizedBox(height: 16),

        _buildModernDropdown(
          value: _formePharmaceutique,
          label: 'Forme pharmaceutique',
          icon: Icons.medical_services,
          items: _formesPharmaceutiques,
          onChanged: (value) {
            setState(() {
              _formePharmaceutique = value!;
            });
          },
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _prixController,
          label: 'Prix (FCFA)',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            if (double.tryParse(value) == null) {
              return 'Nombre invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _stockController,
          label: 'Stock initial',
          icon: Icons.inventory,
          keyboardType: TextInputType.number,
          required: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ce champ est obligatoire';
            }
            if (int.tryParse(value) == null) {
              return 'Nombre entier requis';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _modeEmploiController,
          label: 'Mode d\'emploi',
          icon: Icons.help_outline,
          maxLines: 3,
          hint: 'Instructions d\'utilisation du médicament',
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _contreIndicationsController,
          label: 'Contre-indications',
          icon: Icons.warning,
          maxLines: 3,
          hint: 'Situations où le médicament ne doit pas être utilisé',
        ),
        const SizedBox(height: 16),

        _buildModernTextField(
          controller: _imageUrlController,
          label: 'URL de l\'image',
          icon: Icons.image,
          hint: 'Lien vers l\'image du médicament',
        ),
        const SizedBox(height: 20),

        _buildSectionHeader(
          'Options avancées',
          Icons.settings,
          Colors.orange,
        ),
        const SizedBox(height: 16),

        _buildDateField(),
        const SizedBox(height: 16),

        _buildOrdonnanceSwitch(),
        const SizedBox(height: 30),

        _buildSaveButton(),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.green.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green.shade600),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: Colors.green.shade600),
        title: Text(
          'Date d\'expiration',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _dateExpiration != null
              ? '${_dateExpiration!.day}/${_dateExpiration!.month}/${_dateExpiration!.year}'
              : 'Non définie',
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _dateExpiration ?? DateTime.now().add(const Duration(days: 365)),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
          );
          if (date != null) {
            setState(() {
              _dateExpiration = date;
            });
          }
        },
      ),
    );
  }

  Widget _buildOrdonnanceSwitch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SwitchListTile(
        title: Text(
          'Ordonnance requise',
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text('Ce médicament nécessite une prescription médicale'),
        secondary: Icon(
          Icons.medical_information,
          color: Colors.green.shade600,
        ),
        value: _ordonnanceRequise,
        activeColor: Colors.green,
        onChanged: (value) {
          setState(() {
            _ordonnanceRequise = value;
          });
        },
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMedicament,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Enregistrement...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.save,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Enregistrer le médicament',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _saveMedicament() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final pharmacieId = _pharmacieService.currentPharmacieId;
        if (pharmacieId == null) {
          throw Exception('Pharmacie non connectée');
        }

        final contreIndications = _contreIndicationsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final medicament = Medicament(
          id: '',
          nom: _nomController.text.trim(),
          description: _descriptionController.text.trim(),
          prix: double.parse(_prixController.text),
          stock: int.parse(_stockController.text),
          categorie: _selectedCategory,
          necessite0rdonnance: _ordonnanceRequise,
          estDisponible: int.parse(_stockController.text) > 0,
          pharmacieId: pharmacieId,
          imageUrl: _imageUrlController.text.trim(),
          laboratoire: _laboratoireController.text.trim(),
          dateAjout: DateTime.now(),
          dosage: _dosageController.text.trim(),
          formePharmaceutique: _formePharmaceutique,
          contreIndications: contreIndications,
          modeEmploi: _modeEmploiController.text.trim(),
          dateExpiration: _dateExpiration,
        );

        final success = await _pharmacieService.ajouterMedicament(
          pharmacieId,
          medicament,
        );

        if (success) {
          Navigator.pop(context, true); // Retourner true pour indiquer le succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('✅ Médicament ajouté avec succès'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          throw Exception('Erreur lors de l\'ajout');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('❌ Erreur: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    _stockController.dispose();
    _laboratoireController.dispose();
    _dosageController.dispose();
    _modeEmploiController.dispose();
    _contreIndicationsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}