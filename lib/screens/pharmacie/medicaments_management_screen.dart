import 'package:flutter/material.dart';

class MedicamentsManagementScreen extends StatelessWidget {
  const MedicamentsManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion médicaments'),
      ),
      body: const Center(
        child: Text('Gestion des médicaments - À implémenter'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Ajouter un médicament
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}