import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/auth_service_v2.dart';
import '../services/auth/firebase_simple_auth.dart';
import '../models/user_model.dart';
import '../models/pharmacie_model.dart';
import '../models/livreur_model.dart';
import '../models/client_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuthServiceV2 _authServiceV2 = AuthServiceV2();
  
  UserModel? _currentUser;
  String? _userType;
  bool _isLoading = false;
  String? _errorMessage;

  // Profils spécifiques
  PharmacieModel? _pharmacieProfil;
  LivreurModel? _livreurProfil;
  ClientModel? _clientProfil;

  // Getters
  UserModel? get currentUser => _currentUser;
  String? get userType => _userType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  
  PharmacieModel? get pharmacieProfil => _pharmacieProfil;
  LivreurModel? get livreurProfil => _livreurProfil;
  ClientModel? get clientProfil => _clientProfil;

  AuthProvider() {
    _checkAuthState();
  }

  // Vérifier l'état de l'authentification au démarrage
  void _checkAuthState() {
    // Utiliser Firebase Auth directement pour écouter les changements d'état
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await _loadUserData();
      } else {
        _clearUserData();
      }
    });
  }

  // Charger les données de l'utilisateur
  Future<void> _loadUserData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Récupérer l'utilisateur actuel depuis Firestore
      final uid = FirebaseSimpleAuth.getCurrentUserId();
      if (uid != null) {
        _currentUser = await FirebaseSimpleAuth.getUserFromFirestore(uid);
        
        if (_currentUser != null) {
          _userType = _currentUser!.typeUtilisateur;
          
          // Charger le profil spécifique selon le type
          switch (_userType) {
            case 'pharmacie':
              final profil = await FirebaseSimpleAuth.getSpecificProfile(_currentUser!.id, 'pharmacie');
              if (profil != null) {
                _pharmacieProfil = profil as PharmacieModel;
              }
              break;
            case 'livreur':
              final profil = await FirebaseSimpleAuth.getSpecificProfile(_currentUser!.id, 'livreur');
              if (profil != null) {
                _livreurProfil = profil as LivreurModel;
              }
              break;
            case 'client':
              final profil = await FirebaseSimpleAuth.getSpecificProfile(_currentUser!.id, 'client');
              if (profil != null) {
                _clientProfil = profil as ClientModel;
              }
              break;
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Effacer les données utilisateur
  void _clearUserData() {
    _currentUser = null;
    _userType = null;
    _pharmacieProfil = null;
    _livreurProfil = null;
    _clientProfil = null;
    notifyListeners();
  }

  // Inscription client
  Future<bool> inscriptionClient({
    required String email,
    required String password,
    required String nomComplet,
    required String telephone,
    required String adresse,
    required String ville,
    String? quartier,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser l'authentification simplifiée pour éviter PigeonUserDetails
      final uid = await FirebaseSimpleAuth.createAccountSimple(
        email: email,
        password: password,
      );
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }
      
      // Créer les documents Firestore
      final success = await FirebaseSimpleAuth.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'client',
        dateCreation: DateTime.now(),
        additionalData: {
          'nomComplet': nomComplet,
          'adresse': adresse,
          'ville': ville,
          'quartier': quartier,
        },
      );
      
      if (!success) {
        throw 'Erreur lors de la création du profil.';
      }
      
      // Récupérer l'utilisateur depuis Firestore
      final user = await FirebaseSimpleAuth.getUserFromFirestore(uid);
      
      if (user != null) {
        _currentUser = user;
        _userType = 'client';
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur dans AuthProvider inscriptionClient: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Inscription pharmacie
  Future<bool> inscriptionPharmacie({
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
    required String telephonePharmacie,
    required bool est24h,
    required Map<String, String> horairesDetailles,
    required Set<String> joursGarde,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser l'authentification simplifiée pour éviter PigeonUserDetails
      final uid = await FirebaseSimpleAuth.createAccountSimple(
        email: email,
        password: password,
      );
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }
      
      // Créer les documents Firestore
      final success = await FirebaseSimpleAuth.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomGerant,
        telephone: telephone,
        typeUtilisateur: 'pharmacie',
        dateCreation: DateTime.now(),
        additionalData: {
          'nomPharmacie': nomPharmacie,
          'adresse': adresse,
          'ville': ville,
          'latitude': latitude,
          'longitude': longitude,
          'numeroLicense': numeroLicense,
          'heuresOuverture': heuresOuverture,
          'heuresFermeture': heuresFermeture,
          'telephone': telephonePharmacie,
          'horaires24h': est24h,
          'estOuverte': true, // Par défaut ouvert
          'horairesDetailles': horairesDetailles,
          'horairesOuverture': est24h ? '24h/24' : '${heuresOuverture}-${heuresFermeture}',
          'joursGarde': joursGarde.toList(),
          'note': 0.0,
          'nombreAvis': 0,
          'photoUrl': null,
        },
      );
      
      if (!success) {
        throw 'Erreur lors de la création du profil.';
      }
      
      // Récupérer l'utilisateur depuis Firestore
      final user = await FirebaseSimpleAuth.getUserFromFirestore(uid);
      
      if (user != null) {
        _currentUser = user;
        _userType = 'pharmacie';
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur dans AuthProvider inscriptionPharmacie: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Inscription livreur
  Future<bool> inscriptionLivreur({
    required String email,
    required String password,
    required String nomComplet,
    required String telephone,
    required String numeroPermis,
    required String typeVehicule,
    required String numeroVehicule,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser l'authentification simplifiée pour éviter PigeonUserDetails
      final uid = await FirebaseSimpleAuth.createAccountSimple(
        email: email,
        password: password,
      );
      
      if (uid == null) {
        throw 'Impossible de créer le compte.';
      }
      
      // Créer les documents Firestore
      final success = await FirebaseSimpleAuth.createUserDocuments(
        uid: uid,
        email: email,
        nom: nomComplet,
        telephone: telephone,
        typeUtilisateur: 'livreur',
        dateCreation: DateTime.now(),
        additionalData: {
          'nomComplet': nomComplet,
          'numeroPermis': numeroPermis,
          'typeVehicule': typeVehicule,
          'numeroVehicule': numeroVehicule,
        },
      );
      
      if (!success) {
        throw 'Erreur lors de la création du profil.';
      }
      
      // Récupérer l'utilisateur depuis Firestore
      final user = await FirebaseSimpleAuth.getUserFromFirestore(uid);
      
      if (user != null) {
        _currentUser = user;
        _userType = 'livreur';
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur dans AuthProvider inscriptionLivreur: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Connexion
  Future<bool> connexion(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Utiliser l'authentification manuelle pour éviter PigeonUserDetails
      final uid = await FirebaseSimpleAuth.signInSimple(
        email: email,
        password: password,
      );
      
      if (uid == null) {
        throw 'Email ou mot de passe incorrect.';
      }
      
      // Récupérer l'utilisateur depuis Firestore
      final user = await FirebaseSimpleAuth.getUserFromFirestore(uid);
      
      if (user != null) {
        _currentUser = user;
        _userType = user.typeUtilisateur;
        
        // Charger le profil spécifique selon le type
        switch (_userType) {
          case 'pharmacie':
            final profil = await FirebaseSimpleAuth.getSpecificProfile(uid, 'pharmacie');
            if (profil != null) {
              _pharmacieProfil = profil as PharmacieModel;
            }
            break;
          case 'livreur':
            final profil = await FirebaseSimpleAuth.getSpecificProfile(uid, 'livreur');
            if (profil != null) {
              _livreurProfil = profil as LivreurModel;
            }
            break;
          case 'client':
            final profil = await FirebaseSimpleAuth.getSpecificProfile(uid, 'client');
            if (profil != null) {
              _clientProfil = profil as ClientModel;
            }
            break;
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('Erreur dans AuthProvider connexion: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Déconnexion
  Future<void> deconnexion() async {
    _isLoading = true;
    notifyListeners();

    await FirebaseSimpleAuth.signOut();
    _clearUserData();

    _isLoading = false;
    notifyListeners();
  }

  // Réinitialiser le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}