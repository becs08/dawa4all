import 'package:flutter/material.dart';

class AvailableDeliveriesScreen extends StatelessWidget {
  const AvailableDeliveriesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraisons disponibles'),
      ),
      body: const Center(
        child: Text('Livraisons disponibles - À implémenter'),
      ),
    );
  }
}