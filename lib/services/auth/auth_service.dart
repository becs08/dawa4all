import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';
import '../../models/client_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream de l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir le type d'utilisateur actuel
  Future<String?> getUserType() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        return doc.data()?['typeUtilisateur'];
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du type d\'utilisateur: $e');
      return null;
    }
  }

  // Inscription d'un client
  Future<UserModel?> inscriptionClient({
    required String email,
    required String password,
    required String nomComplet,
    required String telephone,
    required String adresse,
    required String ville,
    String? quartier,
  }) async {
    try {
      // Solution de contournement pour l'erreur PigeonUserDetails
      User? firebaseUser;
      
      try {
        // Tenter de créer l'utilisateur
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        // Si l'erreur PigeonUserDetails se produit
        if (e.toString().contains('PigeonUserDetails')) {
          print('Erreur PigeonUserDetails détectée, tentative de récupération...');
          
          // Attendre un peu pour que Firebase se synchronise
          await Future.delayed(const Duration(seconds: 1));
          
          // Essayer de se connecter avec les mêmes identifiants
          try {
            final loginResult = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            firebaseUser = loginResult.user;
            print('Utilisateur récupéré avec succès après connexion');
          } catch (loginError) {
            // Si la connexion échoue aussi, vérifier si l'utilisateur existe
            if (loginError.toString().contains('user-not-found')) {
              // L'utilisateur n'a pas été créé, réessayer
              throw 'Erreur lors de la création du compte. Veuillez réessayer.';
            } else if (loginError.toString().contains('wrong-password')) {
              // L'utilisateur existe mais on ne peut pas se connecter
              throw 'Un problème est survenu. Veuillez contacter le support.';
            }
            throw 'Erreur de connexion: $loginError';
          }
        } else if (e is FirebaseAuthException) {
          // Gérer les erreurs Firebase normales
          if (e.code == 'weak-password') {
            throw 'Le mot de passe doit contenir au moins 6 caractères.';
          } else if (e.code == 'email-already-in-use') {
            throw 'Un compte existe déjà avec cette adresse email.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          } else {
            throw e.message ?? 'Erreur lors de l\'inscription';
          }
        } else {
          // Autre erreur inconnue
          rethrow;
        }
      }

      if (firebaseUser == null) {
        throw 'Impossible de créer le compte.';
      }

      final uid = firebaseUser.uid;

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

      // Sauvegarder dans Firestore avec retry
      try {
        await _firestore.collection('users').doc(uid).set(user.toMap());
        await _firestore.collection('clients').doc(uid).set(client.toMap());
      } catch (firestoreError) {
        // Si Firestore échoue, supprimer le compte Firebase
        await firebaseUser.delete();
        throw 'Erreur lors de la sauvegarde des données. Veuillez réessayer.';
      }

      return user;
    } catch (e) {
      print('Erreur finale dans inscriptionClient: $e');
      rethrow;
    }
  }

  // Inscription d'une pharmacie
  Future<UserModel?> inscriptionPharmacie({
    required String email,
    required String password,
    required String nomGerant,
    required String telephone,
    required String nomPharmacie,
    required String adresse,
    required String ville,
    required double latitude,
    required double longitude,
    required String numeroLicense,
    required String heuresOuverture,
    required String heuresFermeture,
  }) async {
    try {
      // Solution de contournement pour l'erreur PigeonUserDetails
      User? firebaseUser;
      
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        if (e.toString().contains('PigeonUserDetails')) {
          print('Erreur PigeonUserDetails détectée, tentative de récupération...');
          await Future.delayed(const Duration(seconds: 1));
          
          try {
            final loginResult = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            firebaseUser = loginResult.user;
            print('Utilisateur récupéré avec succès après connexion');
          } catch (loginError) {
            throw 'Erreur lors de la création du compte. Veuillez réessayer.';
          }
        } else if (e is FirebaseAuthException) {
          if (e.code == 'weak-password') {
            throw 'Le mot de passe doit contenir au moins 6 caractères.';
          } else if (e.code == 'email-already-in-use') {
            throw 'Un compte existe déjà avec cette adresse email.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          } else {
            throw e.message ?? 'Erreur lors de l\'inscription';
          }
        } else {
          rethrow;
        }
      }

      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;

      // Créer le document utilisateur
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomGerant,
        telephone: telephone,
        typeUtilisateur: 'pharmacie',
        dateCreation: DateTime.now(),
      );

      // Créer le profil pharmacie
      final pharmacie = PharmacieModel(
        id: uid,
        userId: uid,
        nomPharmacie: nomPharmacie,
        adresse: adresse,
        ville: ville,
        localisation: GeoPoint(latitude, longitude),
        numeroLicense: numeroLicense,
        heuresOuverture: heuresOuverture,
        heuresFermeture: heuresFermeture,
      );

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      await _firestore.collection('pharmacies').doc(pharmacie.id).set(pharmacie.toMap());

      return user;
    } catch (e) {
      print('Erreur lors de l\'inscription de la pharmacie: $e');
      return null;
    }
  }

  // Inscription d'un livreur
  Future<UserModel?> inscriptionLivreur({
    required String email,
    required String password,
    required String nomComplet,
    required String telephone,
    required String numeroPermis,
    required String typeVehicule,
    required String numeroVehicule,
  }) async {
    try {
      // Solution de contournement pour l'erreur PigeonUserDetails
      User? firebaseUser;
      
      try {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        if (e.toString().contains('PigeonUserDetails')) {
          print('Erreur PigeonUserDetails détectée, tentative de récupération...');
          await Future.delayed(const Duration(seconds: 1));
          
          try {
            final loginResult = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            firebaseUser = loginResult.user;
            print('Utilisateur récupéré avec succès après connexion');
          } catch (loginError) {
            throw 'Erreur lors de la création du compte. Veuillez réessayer.';
          }
        } else if (e is FirebaseAuthException) {
          if (e.code == 'weak-password') {
            throw 'Le mot de passe doit contenir au moins 6 caractères.';
          } else if (e.code == 'email-already-in-use') {
            throw 'Un compte existe déjà avec cette adresse email.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          } else {
            throw e.message ?? 'Erreur lors de l\'inscription';
          }
        } else {
          rethrow;
        }
      }

      if (firebaseUser == null) return null;

      final uid = firebaseUser.uid;

      // Créer le document utilisateur
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'livreur',
        dateCreation: DateTime.now(),
      );

      // Créer le profil livreur
      final livreur = LivreurModel(
        id: uid,
        userId: uid,
        nomComplet: nomComplet,
        numeroPermis: numeroPermis,
        typeVehicule: typeVehicule,
        numeroVehicule: numeroVehicule,
      );

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      await _firestore.collection('livreurs').doc(livreur.id).set(livreur.toMap());

      return user;
    } catch (e) {
      print('Erreur lors de l\'inscription du livreur: $e');
      return null;
    }
  }

  // Connexion générale
  Future<UserModel?> connexion({
    required String email,
    required String password,
  }) async {
    try {
      // Solution de contournement pour l'erreur PigeonUserDetails
      User? firebaseUser;
      
      try {
        // Tenter de se connecter
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        firebaseUser = userCredential.user;
      } catch (e) {
        // Si l'erreur PigeonUserDetails se produit
        if (e.toString().contains('PigeonUserDetails')) {
          print('Erreur PigeonUserDetails détectée lors de la connexion, tentative de récupération...');
          
          // Attendre un peu pour que Firebase se synchronise
          await Future.delayed(const Duration(seconds: 1));
          
          // Vérifier si l'utilisateur est déjà connecté
          final currentUser = _auth.currentUser;
          if (currentUser != null) {
            firebaseUser = currentUser;
            print('Utilisateur déjà connecté, récupération réussie');
          } else {
            // Réessayer la connexion
            try {
              await Future.delayed(const Duration(milliseconds: 500));
              final retryResult = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              firebaseUser = retryResult.user;
              print('Connexion réussie après nouvelle tentative');
            } catch (retryError) {
              throw 'Erreur de connexion. Veuillez réessayer.';
            }
          }
        } else if (e is FirebaseAuthException) {
          // Gérer les erreurs Firebase normales
          if (e.code == 'user-not-found') {
            throw 'Aucun utilisateur trouvé avec cette adresse email.';
          } else if (e.code == 'wrong-password') {
            throw 'Mot de passe incorrect.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          } else if (e.code == 'user-disabled') {
            throw 'Ce compte a été désactivé.';
          } else {
            throw e.message ?? 'Erreur lors de la connexion';
          }
        } else {
          // Autre erreur inconnue
          rethrow;
        }
      }

      if (firebaseUser == null) {
        throw 'Impossible de se connecter.';
      }

      // Récupérer les informations de l'utilisateur depuis Firestore
      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (doc.exists) {
          return UserModel.fromMap(doc.data()!);
        } else {
          // L'utilisateur existe dans Auth mais pas dans Firestore
          throw 'Profil utilisateur non trouvé. Veuillez contacter le support.';
        }
      } catch (firestoreError) {
        if (firestoreError is String) {
          rethrow;
        }
        throw 'Erreur lors de la récupération du profil utilisateur.';
      }
    } catch (e) {
      print('Erreur finale dans connexion: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> deconnexion() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialiser le mot de passe
  Future<bool> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      print('Erreur lors de la réinitialisation du mot de passe: $e');
      return false;
    }
  }

  // Mettre à jour le mot de passe
  Future<bool> changerMotDePasse(String nouveauMotDePasse) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(nouveauMotDePasse);
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors du changement de mot de passe: $e');
      return false;
    }
  }
}