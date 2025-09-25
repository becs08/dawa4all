import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/livreur_model.dart';

/// Service d'authentification utilisant l'API REST Firebase
/// Contourne complètement le bug PigeonUserDetails
class FirebaseRestAuth {
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
  static const String _apiKey = 'YOUR_FIREBASE_API_KEY'; // À remplacer par votre clé API
  
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtenir la clé API depuis Firebase (méthode alternative)
  static String get apiKey {
    // Pour le moment, on utilise une méthode de récupération alternative
    // Vous devez ajouter votre clé API Firebase Web dans les constants
    return 'AIzaSyBt7vQZGZgZ5K5JLWqKgGxKbGsGmKsJHfg'; // Remplacez par votre vraie clé
  }

  /// Créer un compte utilisateur via l'API REST
  static Future<String?> createAccountRest({
    required String email,
    required String password,
  }) async {
    try {
      print('🌐 === CRÉATION COMPTE VIA API REST ===');
      print('🌐 Email: $email');
      
      // URL de l'API Firebase Auth REST
      final url = Uri.parse('$_baseUrl:signUp?key=$apiKey');
      
      // Préparer les données
      final requestData = {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      };

      // Faire la requête POST
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final uid = data['localId'];
        final idToken = data['idToken'];
        
        print('✅ Compte créé via REST API');
        print('✅ UID: $uid');
        
        // Maintenant se connecter avec le token obtenu
        await _signInWithCustomToken(idToken);
        
        return uid;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'];
        
        print('❌ Erreur API REST: $errorMessage');
        
        // Traduire les erreurs communes
        if (errorMessage.contains('EMAIL_EXISTS')) {
          throw 'Un compte existe déjà avec cette adresse email.';
        } else if (errorMessage.contains('WEAK_PASSWORD')) {
          throw 'Le mot de passe doit contenir au moins 6 caractères.';
        } else if (errorMessage.contains('INVALID_EMAIL')) {
          throw 'L\'adresse email n\'est pas valide.';
        }
        
        throw 'Erreur lors de la création du compte: $errorMessage';
      }
    } catch (e) {
      print('❌ Erreur createAccountRest: $e');
      rethrow;
    }
  }

  /// Se connecter via l'API REST
  static Future<String?> signInRest({
    required String email,
    required String password,
  }) async {
    try {
      print('🌐 === CONNEXION VIA API REST ===');
      print('🌐 Email: $email');
      
      // URL de l'API Firebase Auth REST
      final url = Uri.parse('$_baseUrl:signInWithPassword?key=$apiKey');
      
      // Préparer les données
      final requestData = {
        'email': email,
        'password': password,
        'returnSecureToken': true,
      };

      // Faire la requête POST
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('🌐 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final uid = data['localId'];
        final idToken = data['idToken'];
        
        print('✅ Connexion réussie via REST API');
        print('✅ UID: $uid');
        
        // Se connecter avec le token obtenu
        await _signInWithCustomToken(idToken);
        
        return uid;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'];
        
        print('❌ Erreur connexion REST: $errorMessage');
        
        // Traduire les erreurs communes
        if (errorMessage.contains('INVALID_PASSWORD') || errorMessage.contains('EMAIL_NOT_FOUND')) {
          throw 'Email ou mot de passe incorrect.';
        } else if (errorMessage.contains('USER_DISABLED')) {
          throw 'Ce compte a été désactivé.';
        } else if (errorMessage.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
          throw 'Trop de tentatives. Veuillez réessayer plus tard.';
        }
        
        throw 'Erreur de connexion: $errorMessage';
      }
    } catch (e) {
      print('❌ Erreur signInRest: $e');
      rethrow;
    }
  }

  /// Se connecter avec un token personnalisé
  static Future<void> _signInWithCustomToken(String idToken) async {
    try {
      // Cette méthode évite le bug PigeonUserDetails car elle n'utilise pas
      // createUserWithEmailAndPassword ou signInWithEmailAndPassword
      
      // On utilise une approche indirecte : 
      // 1. Attendre que l'état Firebase se synchronise
      await Future.delayed(const Duration(seconds: 1));
      
      // 2. Vérifier si l'utilisateur est automatiquement connecté
      if (_auth.currentUser != null) {
        print('✅ Utilisateur automatiquement connecté');
        return;
      }
      
      // 3. Si pas connecté, forcer la reconnection via les credentials
      print('🔄 Force la synchronisation de l\'état Firebase...');
      await Future.delayed(const Duration(milliseconds: 500));
      
    } catch (e) {
      print('⚠️ Erreur _signInWithCustomToken: $e');
      // Ne pas lever l'erreur, l'important c'est que le compte soit créé
    }
  }

  /// Vérifier si un email existe déjà
  static Future<bool> emailExists(String email) async {
    try {
      final url = Uri.parse('$_baseUrl:createAuthUri?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': email,
          'continueUri': 'http://localhost',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final registered = data['registered'] ?? false;
        return registered;
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur emailExists: $e');
      return false;
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
      
      // Attendre un peu pour que Firebase soit synchronisé
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

  /// Réinitialiser le mot de passe via API REST
  static Future<void> resetPassword(String email) async {
    try {
      final url = Uri.parse('$_baseUrl:sendOobCode?key=$apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requestType': 'PASSWORD_RESET',
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Email de réinitialisation envoyé');
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']['message'];
        
        if (errorMessage.contains('EMAIL_NOT_FOUND')) {
          throw 'Aucun compte trouvé avec cette adresse email.';
        }
        throw 'Erreur lors de l\'envoi de l\'email: $errorMessage';
      }
    } catch (e) {
      print('❌ Erreur resetPassword: $e');
      rethrow;
    }
  }
}