import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/user_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';
import '../../models/client_model.dart';

class AuthServiceAlternative {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final AuthServiceAlternative _instance = AuthServiceAlternative._internal();
  factory AuthServiceAlternative() => _instance;
  AuthServiceAlternative._internal();

  // Stream de l'utilisateur actuel
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Méthode alternative pour créer un compte
  Future<UserModel?> inscriptionClientAlternative({
    required String email,
    required String password,
    required String nomComplet,
    required String telephone,
    required String adresse,
    required String ville,
    String? quartier,
  }) async {
    try {
      print('Tentative d\'inscription alternative pour: $email');
      
      // Méthode 1: Essayer la création normale
      User? firebaseUser;
      String? errorMessage;
      
      try {
        // Déconnecter tout utilisateur existant
        await _auth.signOut();
        
        // Attendre un peu
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Créer le compte
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        firebaseUser = credential.user;
      } catch (e) {
        print('Erreur lors de la création normale: $e');
        errorMessage = e.toString();
      }

      // Méthode 2: Si échec, essayer avec un délai plus long
      if (firebaseUser == null && errorMessage != null && errorMessage.contains('PigeonUserDetails')) {
        print('Tentative avec méthode de récupération...');
        
        // Attendre plus longtemps
        await Future.delayed(const Duration(seconds: 2));
        
        // Vérifier si l'utilisateur existe déjà
        try {
          // Essayer de se connecter
          final credential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          
          if (credential.user != null) {
            firebaseUser = credential.user;
            print('Utilisateur récupéré après connexion');
          }
        } catch (e) {
          print('L\'utilisateur n\'existe pas encore: $e');
          
          // Dernière tentative de création
          try {
            await Future.delayed(const Duration(seconds: 1));
            
            // Nettoyer l'état
            await _auth.signOut();
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Réessayer la création
            final retryCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            firebaseUser = retryCredential.user;
            print('Création réussie après nouvelle tentative');
          } catch (retryError) {
            print('Échec de la création après nouvelle tentative: $retryError');
            throw 'Impossible de créer le compte. Veuillez réessayer dans quelques instants.';
          }
        }
      }

      // Si toujours pas d'utilisateur, lever une exception
      if (firebaseUser == null) {
        if (errorMessage != null && errorMessage.contains('email-already-in-use')) {
          throw 'Un compte existe déjà avec cette adresse email.';
        } else if (errorMessage != null && errorMessage.contains('weak-password')) {
          throw 'Le mot de passe doit contenir au moins 6 caractères.';
        } else if (errorMessage != null && errorMessage.contains('invalid-email')) {
          throw 'L\'adresse email n\'est pas valide.';
        }
        throw 'Erreur lors de la création du compte. Veuillez réessayer.';
      }

      final uid = firebaseUser.uid;
      print('Utilisateur Firebase créé avec succès: $uid');

      // Créer le document utilisateur
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'client',
        dateCreation: DateTime.now(),
      );

      // Créer le profil client
      final client = ClientModel(
        id: uid,
        userId: uid,
        nomComplet: nomComplet,
        adresse: adresse,
        ville: ville,
        quartier: quartier,
      );

      // Sauvegarder dans Firestore avec plusieurs tentatives
      int maxRetries = 3;
      for (int i = 0; i < maxRetries; i++) {
        try {
          await _firestore.collection('users').doc(uid).set(user.toMap());
          await _firestore.collection('clients').doc(uid).set(client.toMap());
          print('Données sauvegardées dans Firestore');
          return user;
        } catch (firestoreError) {
          print('Erreur Firestore tentative ${i + 1}: $firestoreError');
          if (i == maxRetries - 1) {
            // Dernière tentative échouée, supprimer le compte
            await firebaseUser.delete();
            throw 'Erreur lors de la sauvegarde des données. Le compte n\'a pas été créé.';
          }
          // Attendre avant de réessayer
          await Future.delayed(Duration(seconds: i + 1));
        }
      }

      return null;
    } catch (e) {
      print('Erreur finale dans inscriptionClientAlternative: $e');
      rethrow;
    }
  }

  // Méthode alternative pour la connexion
  Future<UserModel?> connexionAlternative({
    required String email,
    required String password,
  }) async {
    try {
      print('Tentative de connexion alternative pour: $email');
      
      // Déconnecter tout utilisateur existant
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 500));
      
      User? firebaseUser;
      String? errorMessage;
      
      // Tentative 1: Connexion normale
      try {
        final credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = credential.user;
      } catch (e) {
        print('Erreur lors de la connexion normale: $e');
        errorMessage = e.toString();
      }

      // Tentative 2: Si PigeonUserDetails, réessayer
      if (firebaseUser == null && errorMessage != null && errorMessage.contains('PigeonUserDetails')) {
        print('Réessai après erreur PigeonUserDetails...');
        
        await Future.delayed(const Duration(seconds: 2));
        
        // Vérifier si déjà connecté
        firebaseUser = _auth.currentUser;
        
        if (firebaseUser == null) {
          // Réessayer la connexion
          try {
            final retryCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            firebaseUser = retryCredential.user;
          } catch (retryError) {
            print('Échec de la connexion après nouvelle tentative: $retryError');
          }
        }
      }

      if (firebaseUser == null) {
        if (errorMessage != null && errorMessage.contains('user-not-found')) {
          throw 'Aucun compte trouvé avec cette adresse email.';
        } else if (errorMessage != null && errorMessage.contains('wrong-password')) {
          throw 'Mot de passe incorrect.';
        } else if (errorMessage != null && errorMessage.contains('invalid-email')) {
          throw 'L\'adresse email n\'est pas valide.';
        }
        throw 'Erreur de connexion. Veuillez réessayer.';
      }

      print('Connexion Firebase réussie: ${firebaseUser.uid}');

      // Récupérer les données utilisateur
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        } else {
          throw 'Profil utilisateur non trouvé.';
        }
      } catch (firestoreError) {
        throw 'Erreur lors de la récupération du profil: $firestoreError';
      }
    } catch (e) {
      print('Erreur finale dans connexionAlternative: $e');
      rethrow;
    }
  }

  // Test de connexion Firebase
  Future<bool> testFirebaseConnection() async {
    try {
      // Test 1: Vérifier la connexion Auth
      await _auth.signOut();
      
      // Test 2: Vérifier la connexion Firestore
      await _firestore.collection('test').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Test 3: Lire le document
      await _firestore.collection('test').doc('test').get();
      
      // Test 4: Supprimer le document de test
      await _firestore.collection('test').doc('test').delete();
      
      print('Tous les tests Firebase ont réussi');
      return true;
    } catch (e) {
      print('Erreur lors du test Firebase: $e');
      return false;
    }
  }
}