// lib/pages/admin/form_medicament_page.dart
import 'package:flutter/material.dart';
import '../../models/medicament_model.dart';
import '../../services/medicament_service.dart';

class FormMedicamentPage extends StatefulWidget {
  final Medicament? medicament;
  final bool isEditing;

  const FormMedicamentPage({Key? key, this.medicament, this.isEditing = false}) : super(key: key);

  @override
  _FormMedicamentPageState createState() => _FormMedicamentPageState();
}

class _FormMedicamentPageState extends State<FormMedicamentPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = MedicamentService();

  late TextEditingController _nomController;
  late TextEditingController _prixAncienController;
  late TextEditingController _prixNouveauController;
  late TextEditingController _quantiteController;
  late TextEditingController _descriptionController;
  String _categorie = 'Adulte';
  String _image = 'assets/medicament.png';

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.medicament != null) {
      _nomController = TextEditingController(text: widget.medicament!.nom);
      _prixAncienController = TextEditingController(text: widget.medicament!.prixAncien);
      _prixNouveauController = TextEditingController(text: widget.medicament!.prixNouveau);
      _quantiteController = TextEditingController(text: widget.medicament!.quantite.toString());
      _descriptionController = TextEditingController(text: widget.medicament!.description);
      _categorie = widget.medicament!.categorie;
      _image = widget.medicament!.image;
    } else {
      _nomController = TextEditingController();
      _prixAncienController = TextEditingController();
      _prixNouveauController = TextEditingController();
      _quantiteController = TextEditingController(text: '0');
      _descriptionController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prixAncienController.dispose();
    _prixNouveauController.dispose();
    _quantiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicament() async {
    if (_formKey.currentState!.validate()) {
      final medicament = Medicament(
        id: widget.isEditing ? widget.medicament!.id : null,
        nom: _nomController.text,
        image: _image,
        prixAncien: _prixAncienController.text,
        prixNouveau: _prixNouveauController.text,
        categorie: _categorie,
        quantite: int.parse(_quantiteController.text),
        description: _descriptionController.text,
      );

      try {
        if (widget.isEditing) {
          await _service.updateMedicament(widget.medicament!.id!, medicament);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médicament mis à jour avec succès')),
          );
        } else {
          await _service.addMedicament(medicament);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Médicament ajouté avec succès')),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier le médicament' : 'Ajouter un médicament'),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du médicament',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixAncienController,
                decoration: const InputDecoration(
                  labelText: 'Prix ancien (ex: 5000 XOF)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix ancien';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prixNouveauController,
                decoration: const InputDecoration(
                  labelText: 'Prix nouveau (ex: 4500 XOF)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix nouveau';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categorie,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: ['Adulte', 'Enfant'].map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _categorie = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantiteController,
                decoration: const InputDecoration(
                  labelText: 'Quantité en stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade900,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _saveMedicament,
                  child: Text(widget.isEditing ? 'Mettre à jour' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}