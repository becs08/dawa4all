import 'package:flutter/material.dart';

class ActiveDeliveryScreen extends StatelessWidget {
  const ActiveDeliveryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraison en cours'),
      ),
      body: const Center(
        child: Text('Livraison en cours - À implémenter'),
      ),
    );
  }
}