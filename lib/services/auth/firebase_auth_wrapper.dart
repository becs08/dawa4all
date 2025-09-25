import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';

/// Wrapper pour contourner le bug de cast PigeonUserDetails
/// Basé sur l'implémentation fonctionnelle de KayFoot
class FirebaseAuthWrapper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un compte utilisateur sans déclencher le bug de cast
  static Future<String?> createAccount(String email, String password) async {
    try {
      print('📝 === CRÉATION DE COMPTE (Méthode KayFoot) ===');
      print('📝 Email: $email');
      
      // Vérifier si l'email existe déjà
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        print('❌ Email déjà utilisé');
        throw 'Un compte existe déjà avec cette adresse email.';
      }

      // Déconnexion préventive
      if (_auth.currentUser != null) {
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Créer le compte avec délai pour éviter les conflits
      await Future.delayed(const Duration(milliseconds: 100));

      UserCredential? userCredential;
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e is FirebaseAuthException) {
          if (e.code == 'weak-password') {
            throw 'Le mot de passe doit contenir au moins 6 caractères.';
          } else if (e.code == 'email-already-in-use') {
            throw 'Un compte existe déjà avec cette adresse email.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          }
          throw e.message ?? 'Erreur lors de la création du compte';
        }
        print('❌ Erreur création compte: $e');
        
        // Si c'est l'erreur PigeonUserDetails, on essaie de récupérer
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Erreur PigeonUserDetails détectée, tentative de récupération...');
          
          // Attendre un peu plus longtemps
          await Future.delayed(const Duration(seconds: 1));
          
          // Essayer de se connecter avec les mêmes identifiants
          try {
            final loginResult = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            if (loginResult.user != null) {
              print('✅ Utilisateur récupéré avec succès après connexion');
              return loginResult.user!.uid;
            }
          } catch (loginError) {
            print('❌ Impossible de récupérer l\'utilisateur: $loginError');
          }
        }
        
        rethrow;
      }

      final user = userCredential.user;
      if (user == null) {
        throw 'Impossible de créer le compte.';
      }

      // Attendre que l'utilisateur soit complètement créé
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Compte créé avec succès: ${user.uid}');
      return user.uid;
    } catch (e) {
      print('❌ Erreur dans createAccount: $e');
      rethrow;
    }
  }

  /// Se connecter sans déclencher le bug
  static Future<String?> signIn(String email, String password) async {
    try {
      print('🔐 === CONNEXION (Méthode KayFoot) ===');
      print('🔐 Email: $email');
      
      // Déconnexion préventive
      if (_auth.currentUser != null) {
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      UserCredential? userCredential;

      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        if (e is FirebaseAuthException) {
          if (e.code == 'user-not-found') {
            throw 'Aucun compte trouvé avec cette adresse email.';
          } else if (e.code == 'wrong-password') {
            throw 'Mot de passe incorrect.';
          } else if (e.code == 'invalid-email') {
            throw 'L\'adresse email n\'est pas valide.';
          } else if (e.code == 'user-disabled') {
            throw 'Ce compte a été désactivé.';
          }
          throw e.message ?? 'Erreur lors de la connexion';
        }
        
        // Gérer l'erreur PigeonUserDetails
        if (e.toString().contains('PigeonUserDetails')) {
          print('⚠️ Erreur PigeonUserDetails détectée lors de la connexion');
          
          // Attendre et vérifier si déjà connecté
          await Future.delayed(const Duration(seconds: 1));
          
          if (_auth.currentUser != null) {
            print('✅ Utilisateur déjà connecté');
            return _auth.currentUser!.uid;
          }
          
          // Réessayer
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            final retryResult = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            if (retryResult.user != null) {
              print('✅ Connexion réussie après nouvelle tentative');
              return retryResult.user!.uid;
            }
          } catch (retryError) {
            print('❌ Échec de la nouvelle tentative: $retryError');
          }
        }
        
        rethrow;
      }

      final user = userCredential.user;
      if (user == null) {
        throw 'Impossible de se connecter.';
      }

      // Attendre la stabilisation
      await Future.delayed(const Duration(milliseconds: 300));

      print('✅ Connexion réussie: ${user.uid}');
      return user.uid;
    } catch (e) {
      print('❌ Erreur dans signIn: $e');
      rethrow;
    }
  }

  /// Créer les documents utilisateur dans Firestore
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
      // Document principal dans la collection users
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'nom': nom,
        'telephone': telephone,
        'typeUtilisateur': typeUtilisateur,
        'dateCreation': Timestamp.fromDate(dateCreation),
      });

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
          'ouvert': true,
          'note': 0.0,
          'nombreAvis': 0,
        });
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
      }

      print('✅ Documents utilisateur créés avec succès');
      return true;
    } catch (e) {
      print('❌ Erreur createUserDocuments: $e');
      return false;
    }
  }

  /// Récupérer les données utilisateur depuis Firestore
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

  /// Récupérer le profil spécifique selon le type d'utilisateur
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

  /// Obtenir l'UID de l'utilisateur actuel
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

  /// Stream pour écouter les changements d'authentification
  static Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  /// Vérifier si un email existe déjà
  static Future<bool> emailExists(String email) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ Erreur emailExists: $e');
      return false;
    }
  }

  /// Réinitialiser le mot de passe
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
}