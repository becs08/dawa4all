import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilitaires pour créer des données de test
class TestDataUtils {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Créer des pharmacies de test
  static Future<void> createTestPharmacies() async {
    try {
      print('🧪 === CRÉATION DES DONNÉES DE TEST ===');

      // Quelques pharmacies de test avec différentes localisations
      final testPharmacies = [
        {
          'nomPharmacie': 'Pharmacie du Centre',
          'adresse': '15 Avenue Bourguiba',
          'ville': 'Dakar',
          'localisation': const GeoPoint(14.6937, -17.4441), // Dakar centre
          'numeroLicense': 'PH001',
          'heuresOuverture': '08:00',
          'heuresFermeture': '20:00',
          'estOuverte': true,
          'note': 4.5,
          'nombreAvis': 23,
        },
        {
          'nomPharmacie': 'Pharmacie de la Paix',
          'adresse': '42 Rue de la République',
          'ville': 'Dakar',
          'localisation': const GeoPoint(14.6928, -17.4467), // Proche du centre
          'numeroLicense': 'PH002',
          'heuresOuverture': '07:30',
          'heuresFermeture': '19:30',
          'estOuverte': true,
          'note': 4.2,
          'nombreAvis': 18,
        },
        {
          'nomPharmacie': 'Pharmacie Moderne',
          'adresse': '88 Boulevard du Centenaire',
          'ville': 'Dakar',
          'localisation': const GeoPoint(14.6851, -17.4536), // Un peu plus loin
          'numeroLicense': 'PH003',
          'heuresOuverture': '09:00',
          'heuresFermeture': '18:00',
          'estOuverte': false, // Fermée pour tester les filtres
          'note': 3.8,
          'nombreAvis': 12,
        },
        {
          'nomPharmacie': 'Pharmacie Plateau',
          'adresse': '12 Place de l\'Indépendance',
          'ville': 'Dakar',
          'localisation': const GeoPoint(14.6919, -17.4484),
          'numeroLicense': 'PH004',
          'heuresOuverture': '08:30',
          'heuresFermeture': '19:00',
          'estOuverte': true,
          'note': 4.7,
          'nombreAvis': 31,
        },
        {
          'nomPharmacie': 'Pharmacie de la Médina',
          'adresse': '67 Rue 10',
          'ville': 'Dakar',
          'localisation': const GeoPoint(14.6775, -17.4580), // Médina
          'numeroLicense': 'PH005',
          'heuresOuverture': '07:00',
          'heuresFermeture': '21:00',
          'estOuverte': true,
          'note': 4.1,
          'nombreAvis': 19,
        },
      ];

      // Supprimer les anciennes données de test (optionnel)
      final existingDocs = await _firestore.collection('pharmacies').get();
      for (var doc in existingDocs.docs) {
        await doc.reference.delete();
      }

      // Créer les nouvelles pharmacies de test
      for (var pharmacie in testPharmacies) {
        await _firestore.collection('pharmacies').add(pharmacie);
        print('✅ Pharmacie créée: ${pharmacie['nomPharmacie']}');
      }

      print('🎉 Toutes les pharmacies de test ont été créées !');
    } catch (e) {
      print('❌ Erreur lors de la création des données de test: $e');
    }
  }

  /// Créer des médicaments de test
  static Future<void> createTestMedicaments() async {
    try {
      print('🧪 === CRÉATION DES MÉDICAMENTS DE TEST ===');

      // Récupérer les pharmacies
      final pharmaciesSnapshot = await _firestore.collection('pharmacies').get();
      if (pharmaciesSnapshot.docs.isEmpty) {
        print('⚠️ Aucune pharmacie trouvée. Créez d\'abord les pharmacies de test.');
        return;
      }

      final medicamentsTest = [
        {
          'nom': 'Paracétamol 500mg',
          'description': 'Antalgique et antipyrétique',
          'prix': 2500,
          'stock': 150,
          'estDisponible': true,
          'necessite0rdonnance': false,
        },
        {
          'nom': 'Ibuprofen 400mg',
          'description': 'Anti-inflammatoire non stéroïdien',
          'prix': 3200,
          'stock': 75,
          'estDisponible': true,
          'necessite0rdonnance': false,
        },
        {
          'nom': 'Amoxicilline 500mg',
          'description': 'Antibiotique pénicilline',
          'prix': 5800,
          'stock': 40,
          'estDisponible': true,
          'necessite0rdonnance': true,
        },
        {
          'nom': 'Doliprane 1000mg',
          'description': 'Paracétamol haute dose',
          'prix': 4200,
          'stock': 0,
          'estDisponible': false,
          'necessite0rdonnance': false,
        },
      ];

      // Ajouter des médicaments à chaque pharmacie
      for (var pharmacieDoc in pharmaciesSnapshot.docs) {
        for (var medicament in medicamentsTest) {
          // Ajouter l'ID de la pharmacie
          final medicamentData = {
            ...medicament,
            'pharmacieId': pharmacieDoc.id,
            'pharmacieNom': pharmacieDoc.data()['nomPharmacie'],
          };

          await _firestore.collection('medicaments').add(medicamentData);
        }
        print('✅ Médicaments ajoutés à: ${pharmacieDoc.data()['nomPharmacie']}');
      }

      print('🎉 Tous les médicaments de test ont été créés !');
    } catch (e) {
      print('❌ Erreur lors de la création des médicaments de test: $e');
    }
  }

  /// Créer toutes les données de test
  static Future<void> createAllTestData() async {
    await createTestPharmacies();
    await createTestMedicaments();
    print('🚀 Toutes les données de test ont été créées !');
  }
}