import 'package:flutter/material.dart';

class OrdersManagementScreen extends StatelessWidget {
  const OrdersManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion commandes'),
      ),
      body: const Center(
        child: Text('Gestion des commandes - À implémenter'),
      ),
    );
  }
}