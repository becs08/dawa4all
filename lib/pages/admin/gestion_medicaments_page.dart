// lib/pages/admin/gestion_medicaments_page.dart
import 'package:flutter/material.dart';
import '../../models/medicament_model.dart';
import '../../services/medicament_service.dart';

class GestionMedicamentsPage extends StatefulWidget {
  @override
  _GestionMedicamentsPageState createState() => _GestionMedicamentsPageState();
}

class _GestionMedicamentsPageState extends State<GestionMedicamentsPage> {
  final MedicamentService _service = MedicamentService();
  List<Medicament> _medicaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicaments();
  }

  Future<void> _loadMedicaments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final medicaments = await _service.getMedicaments();
      setState(() {
        _medicaments = medicaments;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteMedicament(String id) async {
    try {
      await _service.deleteMedicament(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médicament supprimé avec succès')),
      );
      _loadMedicaments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Médicaments'),
        backgroundColor: Colors.green.shade900,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _medicaments.length,
        itemBuilder: (context, index) {
          final medicament = _medicaments[index];
          return ListTile(
            leading: medicament.image.startsWith('http')
                ? Image.network(medicament.image, width: 50, height: 50)
                : Image.asset(medicament.image, width: 50, height: 50),
            title: Text(medicament.nom),
            subtitle: Text(medicament.prixNouveau),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/admin/editer_medicament',
                      arguments: medicament,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Voulez-vous vraiment supprimer ce médicament?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (medicament.id != null) {
                                _deleteMedicament(medicament.id!);
                              }
                            },
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/admin/details_medicament',
                arguments: medicament,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green.shade900,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.pushNamed(context, '/admin/ajouter_medicament');
        },
      ),
    );
  }
}