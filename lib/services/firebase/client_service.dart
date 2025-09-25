import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../../models/client_model.dart';
import '../../models/commande_model.dart';
import '../../models/medicament_model.dart';
import '../../models/pharmacie_model.dart';
import '../../models/notification_model.dart';

class ClientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Instance unique (Singleton)
  static final ClientService _instance = ClientService._internal();
  factory ClientService() => _instance;
  ClientService._internal();

  // Obtenir un client par ID
  Future<ClientModel?> getClientById(String id) async {
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (doc.exists) {
        return ClientModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du client: $e');
      return null;
    }
  }

  // Rechercher un médicament dans toutes les pharmacies
  Future<List<Map<String, dynamic>>> rechercherMedicament(String query) async {
    try {
      // Rechercher les médicaments par nom
      final snapshot = await _firestore
          .collection('medicaments')
          .where('estDisponible', isEqualTo: true)
          .get();

      final resultats = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final medicament = Medicament.fromMap(doc.data(), doc.id);
        
        // Filtrer par le terme de recherche
        if (medicament.nom.toLowerCase().contains(query.toLowerCase()) ||
            medicament.description.toLowerCase().contains(query.toLowerCase())) {
          
          // Récupérer les informations de la pharmacie
          final pharmacieDoc = await _firestore
              .collection('pharmacies')
              .doc(medicament.pharmacieId)
              .get();
          
          if (pharmacieDoc.exists) {
            final pharmacie = PharmacieModel.fromMap(pharmacieDoc.data()!);
            
            resultats.add({
              'medicament': medicament,
              'pharmacie': pharmacie,
            });
          }
        }
      }
      
      return resultats;
    } catch (e) {
      print('Erreur lors de la recherche de médicaments: $e');
      return [];
    }
  }

  // Créer une commande
  Future<String?> creerCommande({
    required String clientId,
    required ClientModel client,
    required String pharmacieId,
    required PharmacieModel pharmacie,
    required List<ItemCommande> items,
    required double montantTotal,
    required double fraisLivraison,
    required String modePaiement,
    required bool paiementEffectue,
    String? ordonnanceUrl,
  }) async {
    try {
      print('🆔 Génération ID commande...');
      final commandeId = _firestore.collection('commandes').doc().id;
      print('✅ ID commande généré: $commandeId');
      
      // Récupérer le téléphone depuis UserModel
      String clientTelephone = 'Non renseigné';
      try {
        final userDoc = await _firestore.collection('users').doc(clientId).get();
        if (userDoc.exists) {
          clientTelephone = userDoc.data()?['telephone'] ?? 'Non renseigné';
        }
      } catch (e) {
        print('⚠️ Erreur récupération téléphone: $e');
      }
      
      final commande = CommandeModel(
        id: commandeId,
        clientId: clientId,
        clientNom: client.nomComplet,
        clientTelephone: clientTelephone,
        clientAdresse: '${client.adresse}, ${client.ville}',
        clientLocalisation: client.localisation ?? GeoPoint(0, 0),
        pharmacieId: pharmacieId,
        pharmacieNom: pharmacie.nomPharmacie,
        pharmacieLocalisation: pharmacie.localisation,
        items: items,
        montantTotal: montantTotal,
        fraisLivraison: fraisLivraison,
        statutCommande: 'en_attente',
        dateCommande: DateTime.now(),
        modePaiement: modePaiement,
        paiementEffectue: paiementEffectue,
        ordonnanceUrl: ordonnanceUrl,
      );

      print('💾 Sauvegarde commande en cours...');
      await _firestore.collection('commandes').doc(commandeId).set(commande.toMap());
      print('✅ Commande sauvegardée');

      // Créer une notification pour la pharmacie
      print('📢 Création notification pharmacie...');
      final notification = NotificationModel(
        id: _firestore.collection('notifications').doc().id,
        destinataireId: pharmacieId,
        typeDestinataire: 'pharmacie',
        titre: 'Nouvelle commande',
        message: 'Vous avez reçu une nouvelle commande de ${client.nomComplet}',
        type: 'commande',
        commandeId: commandeId,
        dateCreation: DateTime.now(),
      );

      await _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
      print('✅ Notification créée');

      // Mettre à jour le stock des médicaments
      print('📦 Mise à jour stock médicaments...');
      for (var item in items) {
        print('🔄 MAJ stock pour ${item.medicamentNom}...');
        final medicamentDoc = await _firestore
            .collection('medicaments')
            .doc(item.medicamentId)
            .get();
        
        if (medicamentDoc.exists) {
          final currentStock = medicamentDoc.data()?['stock'] ?? 0;
          final newStock = currentStock - item.quantite;
          
          await _firestore.collection('medicaments').doc(item.medicamentId).update({
            'stock': newStock >= 0 ? newStock : 0,
            'estDisponible': newStock > 0,
          });
          print('✅ Stock mis à jour: $currentStock → ${newStock >= 0 ? newStock : 0}');
        }
      }

      print('🎉 Commande créée avec succès: $commandeId');
      return commandeId;
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      return null;
    }
  }

  // Uploader une ordonnance
  Future<String?> uploaderOrdonnance(String commandeId, File imageFile) async {
    try {
      print('📤 Début upload ordonnance pour commande: $commandeId');
      print('📁 Fichier: ${imageFile.path}');
      
      // Vérifier que le fichier existe
      if (!await imageFile.exists()) {
        print('❌ Le fichier n\'existe pas: ${imageFile.path}');
        return null;
      }
      
      final fileSize = await imageFile.length();
      print('📊 Taille fichier: $fileSize bytes');
      
      if (fileSize == 0) {
        print('❌ Fichier vide');
        return null;
      }
      
      // Essayer plusieurs approches pour l'upload
      return await _tryMultipleUploadStrategies(commandeId, imageFile);
      
    } catch (e) {
      print('❌ Erreur lors de l\'upload de l\'ordonnance: $e');
      print('🔍 Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }
  
  // Essayer plusieurs stratégies d'upload
  Future<String?> _tryMultipleUploadStrategies(String commandeId, File imageFile) async {
    final strategies = [
      _uploadWithData,
      _uploadWithFile,
      _uploadWithBytes,
    ];
    
    for (int i = 0; i < strategies.length; i++) {
      try {
        print('🔄 Essai stratégie ${i + 1}/${strategies.length}...');
        final result = await strategies[i](commandeId, imageFile);
        if (result != null) {
          print('✅ Succès avec stratégie ${i + 1}');
          return result;
        }
      } catch (e) {
        print('⚠️ Stratégie ${i + 1} échoué: $e');
        continue;
      }
    }
    
    print('❌ Toutes les stratégies ont échoué');
    return null;
  }
  
  // Stratégie 1: Upload avec putData
  Future<String?> _uploadWithData(String commandeId, File imageFile) async {
    final fileName = 'ordonnances/$commandeId/${DateTime.now().millisecondsSinceEpoch}_data.jpg';
    final ref = _storage.ref().child(fileName);
    
    final bytes = await imageFile.readAsBytes();
    final uploadTask = await ref.putData(bytes);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    await _firestore.collection('commandes').doc(commandeId).update({
      'ordonnanceUrl': downloadUrl,
    });
    
    return downloadUrl;
  }
  
  // Stratégie 2: Upload avec putFile simple
  Future<String?> _uploadWithFile(String commandeId, File imageFile) async {
    final fileName = 'ordonnances/$commandeId/${DateTime.now().millisecondsSinceEpoch}_file.jpg';
    final ref = _storage.ref().child(fileName);
    
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    await _firestore.collection('commandes').doc(commandeId).update({
      'ordonnanceUrl': downloadUrl,
    });
    
    return downloadUrl;
  }
  
  // Stratégie 3: Upload avec Uint8List
  Future<String?> _uploadWithBytes(String commandeId, File imageFile) async {
    final fileName = 'ordonnances/$commandeId/${DateTime.now().millisecondsSinceEpoch}_bytes.jpg';
    final ref = _storage.ref().child(fileName);
    
    final bytes = await imageFile.readAsBytes();
    final uploadTask = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    
    await _firestore.collection('commandes').doc(commandeId).update({
      'ordonnanceUrl': downloadUrl,
    });
    
    return downloadUrl;
  }

  // Noter une pharmacie
  Future<bool> noterPharmacie(String pharmacieId, String commandeId, double note) async {
    try {
      // Mettre à jour la note dans la commande
      await _firestore.collection('commandes').doc(commandeId).update({
        'notePharmacie': note,
      });

      // Mettre à jour la note moyenne de la pharmacie
      final pharmacieDoc = await _firestore.collection('pharmacies').doc(pharmacieId).get();
      
      if (pharmacieDoc.exists) {
        final pharmacie = PharmacieModel.fromMap(pharmacieDoc.data()!);
        final nouvelleNoteTotal = (pharmacie.note * pharmacie.nombreAvis) + note;
        final nouveauNombreAvis = pharmacie.nombreAvis + 1;
        final nouvelleNoteMoyenne = nouvelleNoteTotal / nouveauNombreAvis;
        
        await _firestore.collection('pharmacies').doc(pharmacieId).update({
          'note': nouvelleNoteMoyenne,
          'nombreAvis': nouveauNombreAvis,
        });
      }

      return true;
    } catch (e) {
      print('Erreur lors de la notation de la pharmacie: $e');
      return false;
    }
  }

  // Noter un livreur
  Future<bool> noterLivreur(String livreurId, String commandeId, double note) async {
    try {
      // Mettre à jour la note dans la commande
      await _firestore.collection('commandes').doc(commandeId).update({
        'noteLivreur': note,
      });

      // Mettre à jour la note moyenne du livreur
      final livreurDoc = await _firestore.collection('livreurs').doc(livreurId).get();
      
      if (livreurDoc.exists) {
        final livreurData = livreurDoc.data()!;
        final noteActuelle = livreurData['note'] ?? 0.0;
        final nombreAvisActuel = livreurData['nombreAvis'] ?? 0;
        
        final nouvelleNoteTotal = (noteActuelle * nombreAvisActuel) + note;
        final nouveauNombreAvis = nombreAvisActuel + 1;
        final nouvelleNoteMoyenne = nouvelleNoteTotal / nouveauNombreAvis;
        
        await _firestore.collection('livreurs').doc(livreurId).update({
          'note': nouvelleNoteMoyenne,
          'nombreAvis': nouveauNombreAvis,
        });
      }

      return true;
    } catch (e) {
      print('Erreur lors de la notation du livreur: $e');
      return false;
    }
  }

  // Obtenir l'historique des commandes
  Stream<List<CommandeModel>> getHistoriqueCommandes(String clientId) {
    return _firestore
        .collection('commandes')
        .where('clientId', isEqualTo: clientId)
        .orderBy('dateCommande', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommandeModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Mettre à jour la localisation du client
  Future<bool> updateLocalisation(String clientId, Position position) async {
    try {
      await _firestore.collection('clients').doc(clientId).update({
        'localisation': GeoPoint(position.latitude, position.longitude),
      });
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de la localisation: $e');
      return false;
    }
  }

  // Obtenir les médicaments d'une pharmacie avec filtres
  Stream<List<Medicament>> getMedicamentsPharmacie(
    String pharmacieId, {
    bool? avecOrdonnanceOnly,
    String? categorie,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('medicaments')
        .where('pharmacieId', isEqualTo: pharmacieId)
        .where('estDisponible', isEqualTo: true);

    if (avecOrdonnanceOnly != null) {
      query = query.where('necessite0rdonnance', isEqualTo: avecOrdonnanceOnly);
    }

    if (categorie != null && categorie.isNotEmpty) {
      query = query.where('categorie', isEqualTo: categorie);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Medicament.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Calculer les frais de livraison basés sur la distance
  double calculerFraisLivraison(double distanceKm) {
    const double tarifBase = 1000; // 1000 CFA de base
    const double tarifParKm = 200; // 200 CFA par km
    
    return tarifBase + (distanceKm * tarifParKm);
  }

  // Obtenir les notifications du client
  Stream<List<NotificationModel>> getNotifications(String clientId) {
    return _firestore
        .collection('notifications')
        .where('destinataireId', isEqualTo: clientId)
        .where('typeDestinataire', isEqualTo: 'client')
        .orderBy('dateCreation', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Marquer une notification comme lue
  Future<bool> marquerNotificationLue(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'lue': true,
      });
      return true;
    } catch (e) {
      print('Erreur lors du marquage de la notification: $e');
      return false;
    }
  }
}