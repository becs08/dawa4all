import 'package:geolocator/geolocator.dart';

/// Service de géolocalisation optimisé pour éviter les erreurs
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._internal();
  
  LocationService._internal();

  /// Obtenir la position actuelle avec gestion d'erreur complète
  static Future<Position?> getCurrentPosition() async {
    try {
      print('📍 === DEMANDE DE GÉOLOCALISATION ===');
      
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Service de localisation désactivé');
        throw CustomLocationServiceDisabledException();
      }

      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Permission refusée, demande de permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Permission refusée définitivement');
          throw CustomLocationPermissionException('Permission de localisation refusée');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Permission refusée pour toujours');
        throw CustomLocationPermissionException('Permission de localisation refusée définitivement. Veuillez l\'activer dans les paramètres.');
      }

      print('✅ Permissions OK, récupération de la position...');
      
      // Obtenir la position avec timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;

    } catch (e) {
      print('❌ Erreur géolocalisation: $e');
      
      // Si c'est une TimeoutException, essayer avec une précision moindre
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        try {
          print('⏳ Nouveau tentative avec précision réduite...');
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
          print('✅ Position obtenue (précision réduite): ${position.latitude}, ${position.longitude}');
          return position;
        } catch (e2) {
          print('❌ Échec définitif: $e2');
        }
      }
      
      rethrow; // Relancer l'exception au lieu de retourner null
    }
  }

  /// Calculer la distance entre deux points
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    ) / 1000; // Conversion en kilomètres
  }

  /// Vérifier si l'utilisateur est proche d'un point
  static bool isNearby(
    Position userPosition,
    double targetLatitude,
    double targetLongitude,
    double radiusInKm,
  ) {
    final distance = calculateDistance(
      userPosition.latitude,
      userPosition.longitude,
      targetLatitude,
      targetLongitude,
    );
    return distance <= radiusInKm;
  }
}

/// Exception personnalisée pour le service de localisation
class CustomLocationServiceDisabledException implements Exception {
  @override
  String toString() => 'Service de localisation désactivé';
}

/// Exception personnalisée pour les permissions
class CustomLocationPermissionException implements Exception {
  final String message;
  CustomLocationPermissionException(this.message);

  @override
  String toString() => message;
}