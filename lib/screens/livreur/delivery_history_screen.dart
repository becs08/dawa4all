import 'package:flutter/material.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique livraisons'),
      ),
      body: const Center(
        child: Text('Historique des livraisons - À implémenter'),
      ),
    );
  }
}