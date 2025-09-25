import 'package:flutter/material.dart';
import '../../services/auth/auth_service_alternative.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({Key? key}) : super(key: key);

  @override
  _FirebaseTestScreenState createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final AuthServiceAlternative _authService = AuthServiceAlternative();
  List<String> _logs = [];
  bool _isTesting = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
    });
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _logs.clear();
    });

    _addLog('Début des tests Firebase...');

    // Test 1: Connexion Firebase
    _addLog('Test 1: Test de connexion Firebase...');
    try {
      final connected = await _authService.testFirebaseConnection();
      _addLog('✓ Connexion Firebase: ${connected ? "OK" : "ÉCHEC"}');
    } catch (e) {
      _addLog('✗ Erreur connexion Firebase: $e');
    }

    // Test 2: État Auth actuel
    _addLog('Test 2: Vérification de l\'état Auth...');
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _addLog('✓ Utilisateur connecté: ${currentUser.email}');
      } else {
        _addLog('✓ Aucun utilisateur connecté');
      }
    } catch (e) {
      _addLog('✗ Erreur Auth: $e');
    }

    // Test 3: Création d'un compte test
    _addLog('Test 3: Création d\'un compte test...');
    final testEmail = 'test${DateTime.now().millisecondsSinceEpoch}@test.com';
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: testEmail,
        password: 'test123456',
      );
      _addLog('✓ Compte test créé: $testEmail');
      
      // Supprimer immédiatement
      await FirebaseAuth.instance.currentUser?.delete();
      _addLog('✓ Compte test supprimé');
    } catch (e) {
      _addLog('✗ Erreur création compte: $e');
      if (e.toString().contains('PigeonUserDetails')) {
        _addLog('⚠️ Erreur PigeonUserDetails détectée!');
      }
    }

    // Test 4: Firestore
    _addLog('Test 4: Test Firestore...');
    try {
      final testDoc = FirebaseFirestore.instance.collection('_test').doc('test');
      await testDoc.set({'timestamp': FieldValue.serverTimestamp()});
      _addLog('✓ Écriture Firestore OK');
      
      final doc = await testDoc.get();
      _addLog('✓ Lecture Firestore OK: ${doc.exists}');
      
      await testDoc.delete();
      _addLog('✓ Suppression Firestore OK');
    } catch (e) {
      _addLog('✗ Erreur Firestore: $e');
    }

    // Test 5: Version Firebase
    _addLog('Test 5: Informations système...');
    try {
      _addLog('Platform: ${Theme.of(context).platform}');
      _addLog('Flutter: ${DateTime.now().toString()}');
    } catch (e) {
      _addLog('✗ Erreur système: $e');
    }

    setState(() {
      _isTesting = false;
    });
    _addLog('Tests terminés.');
  }

  Future<void> _clearFirebaseCache() async {
    _addLog('Nettoyage du cache Firebase...');
    try {
      await FirebaseAuth.instance.signOut();
      _addLog('✓ Déconnexion réussie');
      
      // Attendre un peu
      await Future.delayed(const Duration(seconds: 1));
      
      _addLog('✓ Cache nettoyé');
    } catch (e) {
      _addLog('✗ Erreur nettoyage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Diagnostics Firebase',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isTesting ? null : _runTests,
                      child: const Text('Lancer les tests'),
                    ),
                    ElevatedButton(
                      onPressed: _isTesting ? null : _clearFirebaseCache,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Nettoyer le cache'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: Container(
              color: Colors.black87,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color textColor = Colors.white;
                  
                  if (log.contains('✓')) {
                    textColor = Colors.green;
                  } else if (log.contains('✗')) {
                    textColor = Colors.red;
                  } else if (log.contains('⚠️')) {
                    textColor = Colors.orange;
                  }
                  
                  return Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: textColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}