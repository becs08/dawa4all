import 'package:dawa4all/pages/accueil_page.dart';
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


void main() {
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
      },
    );
  }
}