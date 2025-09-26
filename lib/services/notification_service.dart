import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  
  static const String _channelId = 'dawa4all_orders';
  static const String _channelName = 'Nouvelles Commandes';
  static const String _channelDescription = 'Notifications pour les nouvelles commandes reçues';

  /// Initialise le service de notifications
  Future<void> initialize() async {
    try {
      // Configuration des notifications locales
      await _initializeLocalNotifications();
      
      // Configuration de Firebase Messaging
      await _initializeFirebaseMessaging();
      
      print('✅ Service de notifications initialisé avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation des notifications: $e');
    }
  }

  /// Initialise les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Créer le canal de notification pour Android
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Initialise Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permissions de notifications accordées');
      
      // Obtenir le token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 Token FCM: $token');
        // Sauvegarder le token pour l'utilisateur connecté
        await _saveTokenForUser(token);
      }

      // Écouter les messages en foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Écouter les messages quand l'app est en background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    } else {
      print('❌ Permissions de notifications refusées');
    }
  }

  /// Sauvegarde le token FCM pour l'utilisateur
  Future<void> _saveTokenForUser(String token) async {
    // Cette méthode sera implémentée quand on aura l'ID utilisateur
    // Pour l'instant, on stocke juste le token localement
    print('💾 Token FCM sauvegardé: $token');
  }

  /// Gère les messages reçus en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Message reçu en foreground: ${message.notification?.title}');
    
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Nouvelle notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Gère les messages reçus en background
  void _handleBackgroundMessage(RemoteMessage message) {
    print('📨 Message reçu en background: ${message.notification?.title}');
    // Navigation vers l'écran approprié selon le type de notification
    _navigateFromNotification(message.data);
  }

  /// Navigation depuis une notification
  void _navigateFromNotification(Map<String, dynamic> data) {
    String? type = data['type'];
    
    switch (type) {
      case 'nouvelle_commande':
        // Naviguer vers l'écran des commandes
        print('📱 Navigation vers les commandes');
        break;
      case 'commande_validee':
      case 'commande_refusee':
        // Naviguer vers les détails de la commande
        print('📱 Navigation vers les détails de commande');
        break;
      default:
        print('📱 Type de notification inconnu: $type');
    }
  }

  /// Affiche une notification locale
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.green,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Notification pour nouvelle commande (spécifique aux pharmacies)
  Future<void> showNewOrderNotification({
    required String commandeId,
    required String clientNom,
    required double montant,
  }) async {
    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '🛒 Nouvelle commande reçue !',
      body: 'Commande de $clientNom - ${montant.toStringAsFixed(0)} FCFA',
      payload: 'nouvelle_commande:$commandeId',
    );
  }

  /// Notification de changement de statut de commande
  Future<void> showOrderStatusNotification({
    required String commandeId,
    required String status,
    required String clientNom,
  }) async {
    String title;
    String emoji;
    
    switch (status) {
      case 'validee':
        title = 'Commande validée';
        emoji = '✅';
        break;
      case 'en_preparation':
        title = 'Commande en préparation';
        emoji = '⚙️';
        break;
      case 'prete':
        title = 'Commande prête';
        emoji = '📦';
        break;
      case 'en_livraison':
        title = 'Commande en livraison';
        emoji = '🚚';
        break;
      case 'livree':
        title = 'Commande livrée';
        emoji = '🎉';
        break;
      case 'refusee':
        title = 'Commande refusée';
        emoji = '❌';
        break;
      default:
        title = 'Statut mis à jour';
        emoji = '📋';
    }

    await showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: '$emoji $title',
      body: 'Commande de $clientNom',
      payload: 'statut_commande:$commandeId:$status',
    );
  }

  /// Écoute les nouvelles commandes pour une pharmacie spécifique
  void listenToNewOrders(String pharmacieId) {
    FirebaseFirestore.instance
        .collection('commandes')
        .where('pharmacieId', isEqualTo: pharmacieId)
        .where('statutCommande', isEqualTo: 'en_attente')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          
          // Afficher la notification pour la nouvelle commande
          showNewOrderNotification(
            commandeId: change.doc.id,
            clientNom: data['clientNom'] ?? 'Client inconnu',
            montant: (data['montantTotal'] ?? 0.0).toDouble(),
          );
        }
      }
    });
  }

  /// Callback quand une notification est tapée
  void _onNotificationTapped(NotificationResponse response) {
    String? payload = response.payload;
    if (payload != null) {
      print('📱 Notification tapée avec payload: $payload');
      
      List<String> parts = payload.split(':');
      if (parts.length >= 2) {
        String type = parts[0];
        String commandeId = parts[1];
        
        switch (type) {
          case 'nouvelle_commande':
            // Naviguer vers l'écran des commandes
            print('📱 Navigation vers commande: $commandeId');
            break;
          case 'statut_commande':
            // Naviguer vers les détails de la commande
            print('📱 Navigation vers détails commande: $commandeId');
            break;
        }
      }
    }
  }

  /// Annule toutes les notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Annule une notification spécifique
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Obtient le nombre de notifications en attente
  Future<int> getPendingNotificationCount() async {
    final pendingNotifications = await _localNotifications.pendingNotificationRequests();
    return pendingNotifications.length;
  }

  /// Nettoie les ressources
  void dispose() {
    // Nettoyer les listeners si nécessaire
  }
}

/// Gestionnaire pour les messages FCM en background (fonction top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Message FCM reçu en background: ${message.notification?.title}');
  
  // Afficher une notification locale
  if (message.notification != null) {
    NotificationService().showLocalNotification(
      title: message.notification!.title ?? 'Nouvelle notification',
      body: message.notification!.body ?? '',
      payload: message.data.toString(),
    );
  }
}