import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';
import '../../models/client_model.dart';
import 'firebase_auth_wrapper.dart';

/// Service d'authentification utilisant la méthode KayFoot
class AuthServiceV2 {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instance unique (Singleton)
  static final AuthServiceV2 _instance = AuthServiceV2._internal();
  factory AuthServiceV2() => _instance;
  AuthServiceV2._internal();

  // Stream de l'utilisateur actuel
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Utilisateur actuel
  User? get currentUser => _auth.currentUser;

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
      print('📝 === INSCRIPTION CLIENT ===');
      
      // Étape 1: Créer le compte avec le wrapper
      final uid = await FirebaseAuthWrapper.createAccount(email, password);
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }

      // Étape 2: Créer l'objet UserModel
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'client',
        dateCreation: DateTime.now(),
      );

      // Étape 3: Créer les documents dans Firestore
      final success = await FirebaseAuthWrapper.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'client',
        dateCreation: user.dateCreation,
        additionalData: {
          'nomComplet': nomComplet,
          'adresse': adresse,
          'ville': ville,
          'quartier': quartier,
        },
      );

      if (!success) {
        // Si l'écriture échoue, supprimer le compte
        await currentUser?.delete();
        throw 'Erreur lors de la création du profil.';
      }

      print('✅ Inscription client réussie');
      return user;
    } catch (e) {
      print('❌ Erreur inscription client: $e');
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
      print('📝 === INSCRIPTION PHARMACIE ===');
      
      // Étape 1: Créer le compte avec le wrapper
      final uid = await FirebaseAuthWrapper.createAccount(email, password);
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }

      // Étape 2: Créer l'objet UserModel
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomGerant,
        telephone: telephone,
        typeUtilisateur: 'pharmacie',
        dateCreation: DateTime.now(),
      );

      // Étape 3: Créer les documents dans Firestore
      final success = await FirebaseAuthWrapper.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomGerant,
        telephone: telephone,
        typeUtilisateur: 'pharmacie',
        dateCreation: user.dateCreation,
        additionalData: {
          'nomPharmacie': nomPharmacie,
          'adresse': adresse,
          'ville': ville,
          'latitude': latitude,
          'longitude': longitude,
          'numeroLicense': numeroLicense,
          'heuresOuverture': heuresOuverture,
          'heuresFermeture': heuresFermeture,
        },
      );

      if (!success) {
        // Si l'écriture échoue, supprimer le compte
        await currentUser?.delete();
        throw 'Erreur lors de la création du profil.';
      }

      print('✅ Inscription pharmacie réussie');
      return user;
    } catch (e) {
      print('❌ Erreur inscription pharmacie: $e');
      rethrow;
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
      print('📝 === INSCRIPTION LIVREUR ===');
      
      // Étape 1: Créer le compte avec le wrapper
      final uid = await FirebaseAuthWrapper.createAccount(email, password);
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }

      // Étape 2: Créer l'objet UserModel
      final user = UserModel(
        id: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'livreur',
        dateCreation: DateTime.now(),
      );

      // Étape 3: Créer les documents dans Firestore
      final success = await FirebaseAuthWrapper.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'livreur',
        dateCreation: user.dateCreation,
        additionalData: {
          'nomComplet': nomComplet,
          'numeroPermis': numeroPermis,
          'typeVehicule': typeVehicule,
          'numeroVehicule': numeroVehicule,
        },
      );

      if (!success) {
        // Si l'écriture échoue, supprimer le compte
        await currentUser?.delete();
        throw 'Erreur lors de la création du profil.';
      }

      print('✅ Inscription livreur réussie');
      return user;
    } catch (e) {
      print('❌ Erreur inscription livreur: $e');
      rethrow;
    }
  }

  // Connexion générale
  Future<UserModel?> connexion({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 === CONNEXION ===');
      
      // Étape 1: Se connecter avec le wrapper
      final uid = await FirebaseAuthWrapper.signIn(email, password);
      
      if (uid == null) {
        throw 'Email ou mot de passe incorrect.';
      }

      // Étape 2: Récupérer les données utilisateur
      final user = await FirebaseAuthWrapper.getUserFromFirestore(uid);
      
      if (user == null) {
        throw 'Profil utilisateur non trouvé.';
      }

      print('✅ Connexion réussie: ${user.typeUtilisateur}');
      return user;
    } catch (e) {
      print('❌ Erreur connexion: $e');
      rethrow;
    }
  }

  // Récupérer l'utilisateur actuel depuis Firestore
  Future<UserModel?> getCurrentUserFromFirestore() async {
    try {
      final uid = FirebaseAuthWrapper.getCurrentUserId();
      if (uid == null) return null;

      return await FirebaseAuthWrapper.getUserFromFirestore(uid);
    } catch (e) {
      print('❌ Erreur getCurrentUserFromFirestore: $e');
      return null;
    }
  }

  // Récupérer le profil spécifique de l'utilisateur
  Future<dynamic> getUserProfile(String uid, String typeUtilisateur) async {
    try {
      return await FirebaseAuthWrapper.getSpecificProfile(uid, typeUtilisateur);
    } catch (e) {
      print('❌ Erreur getUserProfile: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> deconnexion() async {
    try {
      await FirebaseAuthWrapper.signOut();
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
      rethrow;
    }
  }

  // Réinitialiser le mot de passe
  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await FirebaseAuthWrapper.resetPassword(email);
    } catch (e) {
      print('❌ Erreur réinitialisation mot de passe: $e');
      rethrow;
    }
  }

  // Vérifier si un email existe déjà
  Future<bool> emailExiste(String email) async {
    try {
      return await FirebaseAuthWrapper.emailExists(email);
    } catch (e) {
      print('❌ Erreur vérification email: $e');
      return false;
    }
  }

  // Mettre à jour le mot de passe
  Future<void> changerMotDePasse(String nouveauMotDePasse) async {
    try {
      if (currentUser != null) {
        await currentUser!.updatePassword(nouveauMotDePasse);
      } else {
        throw 'Aucun utilisateur connecté.';
      }
    } catch (e) {
      print('❌ Erreur changement mot de passe: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'weak-password') {
          throw 'Le mot de passe doit contenir au moins 6 caractères.';
        } else if (e.code == 'requires-recent-login') {
          throw 'Veuillez vous reconnecter pour changer votre mot de passe.';
        }
      }
      rethrow;
    }
  }
}