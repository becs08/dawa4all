import 'package:dawa4all/pages/accueil_page.dart';
import 'package:dawa4all/pages/admin/dashboard_page.dart';
import 'package:dawa4all/pages/admin/details_medicament_page.dart';
import 'package:dawa4all/pages/admin/form_medicament_page.dart';
import 'package:dawa4all/pages/admin/gestion_medicaments_page.dart';
import 'package:dawa4all/pages/connexion_page.dart';
import 'package:dawa4all/pages/inscription_page.dart';
import 'package:dawa4all/pages/list_page.dart';
import 'package:dawa4all/pages/loading_page.dart';
import 'package:dawa4all/pages/paiement_page.dart';
import 'package:dawa4all/pages/panier_provider.dart';
import 'package:dawa4all/pages/start_page.dart';
import 'package:dawa4all/pages/panier_page.dart';
import 'package:dawa4all/pages/verification_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'models/medicament_model.dart';

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => PanierProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dawa4All',
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingPage(),
        '/start': (context) => const StartPage(),
        '/connexion': (context) => const ConnexionPage(),
        '/inscription': (context) => const InscriptionPage(),
        '/accueil': (context) => const AccueilPage(),
        '/listeProduits': (context) => ListeProduitsPage(),
        '/panier': (context) => PanierPage(),
        '/verification': (context) => const VerificationPage(),
        '/paiement': (context) => const PaiementPage(),
        // Routes Admin
        '/admin/gestion_medicaments': (context) => GestionMedicamentsPage(),
        '/admin/ajouter_medicament': (context) => const FormMedicamentPage(),
        '/admin/dashboard': (context) => DashboardPage(),
        '/admin/editer_medicament': (context) => FormMedicamentPage(
          medicament: ModalRoute.of(context)?.settings.arguments as Medicament,
          isEditing: true,
        ),
        '/admin/details_medicament': (context) => DetailsMedicamentPage(
          medicament: ModalRoute.of(context)?.settings.arguments as Medicament,
          isAdmin: true,
        ),
      },
    );
  }
}