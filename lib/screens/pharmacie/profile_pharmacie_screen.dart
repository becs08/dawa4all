import 'package:flutter/material.dart';

class ProfilePharmacieScreen extends StatelessWidget {
  const ProfilePharmacieScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil pharmacie'),
      ),
      body: const Center(
        child: Text('Profil de la pharmacie - À implémenter'),
      ),
    );
  }
}