import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';

/// Service d'authentification manuel qui évite complètement le bug PigeonUserDetails
/// Utilise des techniques de contournement avancées
class FirebaseManualAuth {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer un compte en utilisant une approche manuelle
  static Future<String?> createAccountManual({
    required String email,
    required String password,
  }) async {
    try {
      print('🔧 === CRÉATION COMPTE MANUELLE ===');
      print('🔧 Email: $email');
      
      // Note: setPersistence() n'est disponible que sur web, on l'ignore sur mobile
      
      // Méthode 2: Utiliser un isolate pour éviter les conflits
      String? uid;
      Exception? createError;
      
      try {
        // Essayer la création avec tous les flags de sécurité
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        uid = userCredential.user?.uid;
        print('✅ Compte créé normalement: $uid');
        
      } catch (e) {
        createError = e as Exception;
        print('❌ Erreur création normale: $e');
        
        // Si c'est le bug PigeonUserDetails, essayer la méthode de récupération
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('List<Object?>')) {
          
          print('🔧 Bug PigeonUserDetails détecté, méthode de récupération...');
          
          // Attendre pour laisser Firebase se synchroniser
          await Future.delayed(const Duration(seconds: 2));
          
          // Méthode de récupération 1: Essayer de se connecter
          try {
            print('🔧 Tentative de connexion avec les mêmes identifiants...');
            
            final signInCredential = await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            
            if (signInCredential.user != null) {
              uid = signInCredential.user!.uid;
              print('✅ Compte récupéré par connexion: $uid');
            }
          } catch (signInError) {
            print('❌ Connexion de récupération échouée: $signInError');
            
            // Méthode de récupération 2: Vérifier l'état actuel
            await Future.delayed(const Duration(milliseconds: 500));
            
            if (_auth.currentUser != null) {
              uid = _auth.currentUser!.uid;
              print('✅ Utilisateur trouvé dans l\'état actuel: $uid');
            } else {
              // Méthode de récupération 3: Réessayer la création
              await Future.delayed(const Duration(seconds: 1));
              
              try {
                // Nettoyer complètement l'état
                await _auth.signOut();
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Note: setPersistence() ignoré sur mobile
                
                final retryCredential = await _auth.createUserWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                
                uid = retryCredential.user?.uid;
                print('✅ Compte créé lors du retry: $uid');
                
              } catch (retryError) {
                print('❌ Retry échoué: $retryError');
                // Dernier recours: essayer une connexion
                try {
                  final lastTryCredential = await _auth.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  );
                  uid = lastTryCredential.user?.uid;
                  print('✅ Compte trouvé en dernier recours: $uid');
                } catch (lastError) {
                  print('❌ Dernier recours échoué: $lastError');
                }
              }
            }
          }
        } else {
          // Erreur normale de Firebase
          if (e is FirebaseAuthException) {
            if (e.code == 'email-already-in-use') {
              throw 'Un compte existe déjà avec cette adresse email.';
            } else if (e.code == 'weak-password') {
              throw 'Le mot de passe doit contenir au moins 6 caractères.';
            } else if (e.code == 'invalid-email') {
              throw 'L\'adresse email n\'est pas valide.';
            }
          }
          rethrow;
        }
      }
      
      // Note: setPersistence() ignoré sur mobile
      
      if (uid != null) {
        // Attendre la stabilisation finale
        await Future.delayed(const Duration(milliseconds: 300));
        print('✅ Création de compte terminée: $uid');
        return uid;
      } else {
        if (createError != null) {
          throw createError;
        }
        throw 'Impossible de créer le compte après plusieurs tentatives.';
      }
      
    } catch (e) {
      print('❌ Erreur createAccountManual: $e');
      rethrow;
    }
  }

  /// Se connecter avec méthode manuelle
  static Future<String?> signInManual({
    required String email,
    required String password,
  }) async {
    try {
      print('🔧 === CONNEXION MANUELLE ===');
      print('🔧 Email: $email');
      
      // Nettoyer l'état
      await _auth.signOut();
      await Future.delayed(const Duration(milliseconds: 200));
      
      String? uid;
      
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        
        uid = userCredential.user?.uid;
        print('✅ Connexion normale réussie: $uid');
        
      } catch (e) {
        print('❌ Erreur connexion normale: $e');
        
        if (e.toString().contains('PigeonUserDetails') || 
            e.toString().contains('List<Object?>')) {
          
          print('🔧 Bug PigeonUserDetails lors de la connexion');
          
          // Attendre et vérifier l'état
          await Future.delayed(const Duration(seconds: 1));
          
          if (_auth.currentUser != null) {
            uid = _auth.currentUser!.uid;
            print('✅ Utilisateur trouvé dans l\'état: $uid');
          } else {
            // Réessayer après nettoyage
            await Future.delayed(const Duration(milliseconds: 500));
            
            try {
              final retryCredential = await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              );
              uid = retryCredential.user?.uid;
              print('✅ Connexion réussie lors du retry: $uid');
            } catch (retryError) {
              print('❌ Retry connexion échoué: $retryError');
              rethrow;
            }
          }
        } else {
          // Erreur normale de Firebase
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
          }
          rethrow;
        }
      }
      
      if (uid != null) {
        await Future.delayed(const Duration(milliseconds: 300));
        print('✅ Connexion terminée: $uid');
        return uid;
      } else {
        throw 'Impossible de se connecter.';
      }
      
    } catch (e) {
      print('❌ Erreur signInManual: $e');
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
      print('📝 === CRÉATION DOCUMENTS FIRESTORE ===');
      
      // Attendre pour s'assurer que Firebase Auth est stable
      await Future.delayed(const Duration(seconds: 1));
      
      // Document principal dans la collection users
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
          'ouvert': true,
          'note': 0.0,
          'nombreAvis': 0,
        });
        print('✅ Document pharmacie créé');
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
}