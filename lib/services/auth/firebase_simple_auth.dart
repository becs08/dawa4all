import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';

/// Service d'authentification simplifié pour éviter le bug PigeonUserDetails
class FirebaseSimpleAuth {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un compte avec gestion d'erreur simplifiée
  static Future<String?> createAccountSimple({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 === CRÉATION COMPTE SIMPLIFIÉ ===');
      print('🚀 Email: $email');
      
      // Vérifier si email existe déjà
      final existingMethods = await _auth.fetchSignInMethodsForEmail(email);
      if (existingMethods.isNotEmpty) {
        throw 'Un compte existe déjà avec cette adresse email.';
      }
      
      // Déconnexion préventive
      if (_auth.currentUser != null) {
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Tentative de création simple
      UserCredential? credential;
      
      try {
        credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (credential.user != null) {
          print('✅ Compte créé avec succès: ${credential.user!.uid}');
          return credential.user!.uid;
        }
        
      } catch (e) {
        print('❌ Erreur création: $e');
        
        // Si c'est le bug PigeonUserDetails, essayer la récupération
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('List<Object?>')) {
          
          print('⚠️ Bug PigeonUserDetails détecté, tentative de récupération...');
          
          // Attendre un peu
          await Future.delayed(const Duration(seconds: 2));
          
          // Essayer de se connecter avec les mêmes identifiants
          try {
            final signInCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            if (signInCredential.user != null) {
              print('✅ Compte récupéré par connexion: ${signInCredential.user!.uid}');
              return signInCredential.user!.uid;
            }
          } catch (signInError) {
            print('❌ Récupération échouée: $signInError');
          }
          
          // Vérifier l'état actuel
          await Future.delayed(const Duration(milliseconds: 500));
          if (_auth.currentUser != null) {
            print('✅ Utilisateur trouvé dans l\'état: ${_auth.currentUser!.uid}');
            return _auth.currentUser!.uid;
          }
        }
        
        // Gérer les erreurs Firebase normales
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'email-already-in-use':
              throw 'Un compte existe déjà avec cette adresse email.';
            case 'weak-password':
              throw 'Le mot de passe doit contenir au moins 6 caractères.';
            case 'invalid-email':
              throw 'L\'adresse email n\'est pas valide.';
          }
        }
        
        rethrow;
      }
      
      throw 'Impossible de créer le compte.';
    } catch (e) {
      print('❌ Erreur createAccountSimple: $e');
      rethrow;
    }
  }

  /// Se connecter avec gestion d'erreur simplifiée
  static Future<String?> signInSimple({
    required String email,
    required String password,
  }) async {
    try {
      print('🚀 === CONNEXION SIMPLIFIÉE ===');
      print('🚀 Email: $email');
      
      // Déconnexion préventive
      if (_auth.currentUser != null) {
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      UserCredential? credential;
      
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        if (credential.user != null) {
          print('✅ Connexion réussie: ${credential.user!.uid}');
          return credential.user!.uid;
        }
        
      } catch (e) {
        print('❌ Erreur connexion: $e');
        
        // Gérer le bug PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('List<Object?>')) {
          
          print('⚠️ Bug PigeonUserDetails lors connexion');
          
          // Attendre et vérifier l'état
          await Future.delayed(const Duration(seconds: 1));
          if (_auth.currentUser != null) {
            print('✅ Utilisateur connecté malgré l\'erreur: ${_auth.currentUser!.uid}');
            return _auth.currentUser!.uid;
          }
        }
        
        // Gérer les erreurs Firebase normales
        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'user-not-found':
              throw 'Aucun compte trouvé avec cette adresse email.';
            case 'wrong-password':
              throw 'Mot de passe incorrect.';
            case 'invalid-email':
              throw 'L\'adresse email n\'est pas valide.';
            case 'user-disabled':
              throw 'Ce compte a été désactivé.';
          }
        }
        
        rethrow;
      }
      
      throw 'Impossible de se connecter.';
    } catch (e) {
      print('❌ Erreur signInSimple: $e');
      rethrow;
    }
  }

  /// Créer les documents Firestore
  static Future<bool> createUserDocuments({
    required String uid,
    required String email,
    required String nom,
    required String telephone,
    required String typeUtilisateur,
    required DateTime dateCreation,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📝 === CRÉATION DOCUMENTS FIRESTORE ===');
      
      // Document principal
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'nom': nom,
        'telephone': telephone,
        'typeUtilisateur': typeUtilisateur,
        'dateCreation': Timestamp.fromDate(dateCreation),
      });

      print('✅ Document users créé');

      // Document spécifique selon le type
      if (typeUtilisateur == 'client' && additionalData != null) {
        await _firestore.collection('clients').doc(uid).set({
          'userId': uid,
          'nomComplet': additionalData['nomComplet'] ?? nom,
          'adresse': additionalData['adresse'] ?? '',
          'ville': additionalData['ville'] ?? '',
          'quartier': additionalData['quartier'],
          'historiqueCommandes': [],
          'favoris': [],
        });
        print('✅ Document client créé');
      } else if (typeUtilisateur == 'pharmacie' && additionalData != null) {
        await _firestore.collection('pharmacies').doc(uid).set({
          'userId': uid,
          'nomPharmacie': additionalData['nomPharmacie'] ?? '',
          'adresse': additionalData['adresse'] ?? '',
          'ville': additionalData['ville'] ?? '',
          'localisation': GeoPoint(
            additionalData['latitude'] ?? 0.0,
            additionalData['longitude'] ?? 0.0,
          ),
          'numeroLicense': additionalData['numeroLicense'] ?? '',
          'heuresOuverture': additionalData['heuresOuverture'] ?? '08:00',
          'heuresFermeture': additionalData['heuresFermeture'] ?? '20:00',
          'telephonePharmacie': additionalData['telephone'] ?? '',
          'horaires24h': additionalData['horaires24h'] ?? false,
          'estOuverte': additionalData['estOuverte'] ?? true,
          'horairesDetailles': additionalData['horairesDetailles'] ?? {},
          'horairesOuverture': additionalData['horairesOuverture'] ?? '',
          'joursGarde': additionalData['joursGarde'] ?? [],
          'ouvert': true,
          'note': additionalData['note'] ?? 0.0,
          'nombreAvis': additionalData['nombreAvis'] ?? 0,
          'photoUrl': additionalData['photoUrl'],
        });
        print('✅ Document pharmacie créé avec tous les champs: ${additionalData['joursGarde']}');
      } else if (typeUtilisateur == 'livreur' && additionalData != null) {
        await _firestore.collection('livreurs').doc(uid).set({
          'userId': uid,
          'nomComplet': additionalData['nomComplet'] ?? nom,
          'numeroPermis': additionalData['numeroPermis'] ?? '',
          'typeVehicule': additionalData['typeVehicule'] ?? '',
          'numeroVehicule': additionalData['numeroVehicule'] ?? '',
          'disponible': true,
          'localisationActuelle': null,
          'nombreLivraisons': 0,
          'note': 0.0,
        });
        print('✅ Document livreur créé');
      }

      return true;
    } catch (e) {
      print('❌ Erreur createUserDocuments: $e');
      return false;
    }
  }

  /// Récupérer utilisateur depuis Firestore
  static Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('❌ Utilisateur non trouvé dans Firestore');
        return null;
      }

      final data = doc.data()!;
      print('✅ Données utilisateur récupérées: ${data['typeUtilisateur']}');
      
      return UserModel.fromMap({...data, 'id': uid});
    } catch (e) {
      print('❌ Erreur getUserFromFirestore: $e');
      return null;
    }
  }

  /// Récupérer profil spécifique
  static Future<dynamic> getSpecificProfile(String uid, String typeUtilisateur) async {
    try {
      if (typeUtilisateur == 'client') {
        final doc = await _firestore.collection('clients').doc(uid).get();
        if (doc.exists) {
          return ClientModel.fromMap({...doc.data()!, 'id': uid});
        }
      } else if (typeUtilisateur == 'pharmacie') {
        final doc = await _firestore.collection('pharmacies').doc(uid).get();
        if (doc.exists) {
          return PharmacieModel.fromMap({...doc.data()!, 'id': uid});
        }
      } else if (typeUtilisateur == 'livreur') {
        final doc = await _firestore.collection('livreurs').doc(uid).get();
        if (doc.exists) {
          return LivreurModel.fromMap({...doc.data()!, 'id': uid});
        }
      }
      return null;
    } catch (e) {
      print('❌ Erreur getSpecificProfile: $e');
      return null;
    }
  }

  /// Obtenir UID utilisateur actuel
  static String? getCurrentUserId() {
    try {
      return _auth.currentUser?.uid;
    } catch (e) {
      print('❌ Erreur getCurrentUserId: $e');
      return null;
    }
  }

  /// Se déconnecter
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur signOut: $e');
    }
  }

  /// Réinitialiser mot de passe
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Email de réinitialisation envoyé');
    } catch (e) {
      print('❌ Erreur resetPassword: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          throw 'Aucun compte trouvé avec cette adresse email.';
        }
        throw e.message ?? 'Erreur lors de l\'envoi de l\'email';
      }
      rethrow;
    }
  }

  /// Vérifier si email existe
  static Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ Erreur emailExists: $e');
      return false;
    }
  }
}