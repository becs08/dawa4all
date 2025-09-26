import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/firebase/notification_firebase_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationFirebaseService _notificationService = NotificationFirebaseService();
  
  List<NotificationModel> _notifications = [];
  int _nombreNonLues = 0;
  bool _isLoading = false;
  String? _utilisateurId;

  // Getters
  List<NotificationModel> get notifications => _notifications;
  int get nombreNonLues => _nombreNonLues;
  bool get isLoading => _isLoading;
  bool get hasUnreadNotifications => _nombreNonLues > 0;

  /// Initialise le provider pour un utilisateur
  Future<void> initialize(String utilisateurId, String userType) async {
    _utilisateurId = utilisateurId;
    _isLoading = true;
    notifyListeners();

    try {
      // Initialiser les listeners Firebase
      _notificationService.initialiserListeners(utilisateurId, userType);

      // Écouter les notifications de cet utilisateur
      _notificationService.getNotificationsUtilisateur(utilisateurId).listen((notifications) {
        _notifications = notifications;
        _nombreNonLues = notifications.where((n) => !n.lue).length;
        notifyListeners();
      });

      // Écouter le nombre de notifications non lues
      _notificationService.streamNombreNotificationsNonLues(utilisateurId).listen((nombre) {
        _nombreNonLues = nombre;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
      
      print('✅ NotificationProvider initialisé pour utilisateur: $utilisateurId');
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Erreur lors de l\'initialisation du NotificationProvider: $e');
    }
  }

  /// Marque une notification comme lue
  Future<void> marquerCommeLue(String notificationId) async {
    try {
      await _notificationService.marquerCommeLue(notificationId);
      
      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(lue: true);
        if (_nombreNonLues > 0) _nombreNonLues--;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur lors du marquage comme lue: $e');
    }
  }

  /// Marque toutes les notifications comme lues
  Future<void> marquerToutesCommeLues() async {
    if (_utilisateurId == null) return;
    
    try {
      await _notificationService.marquerToutesCommeLues(_utilisateurId!);
      
      // Mettre à jour localement
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(lue: true);
      }
      _nombreNonLues = 0;
      notifyListeners();
    } catch (e) {
      print('❌ Erreur lors du marquage global: $e');
    }
  }

  /// Supprime une notification
  Future<void> supprimerNotification(String notificationId) async {
    try {
      await _notificationService.supprimerNotification(notificationId);
      
      // Mettre à jour localement
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = _notifications[index];
        _notifications.removeAt(index);
        if (!notification.lue && _nombreNonLues > 0) _nombreNonLues--;
        notifyListeners();
      }
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }

  /// Obtient les notifications récentes (24h)
  List<NotificationModel> get notificationsRecentes {
    final hier = DateTime.now().subtract(const Duration(hours: 24));
    return _notifications
        .where((n) => n.dateCreation.isAfter(hier))
        .take(5)
        .toList();
  }

  /// Obtient les notifications par type
  List<NotificationModel> getNotificationsParType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  /// Obtient les notifications de commandes
  List<NotificationModel> get notificationsCommandes {
    return _notifications.where((n) => 
      n.type == NotificationType.nouvelleCommande ||
      n.type == NotificationType.commandeValidee ||
      n.type == NotificationType.commandeRefusee ||
      n.type == NotificationType.commandePreparation ||
      n.type == NotificationType.commandePrete ||
      n.type == NotificationType.commandeLivraison ||
      n.type == NotificationType.commandeLivree
    ).toList();
  }

  /// Nettoie le provider
  void dispose() {
    _notifications.clear();
    _nombreNonLues = 0;
    _utilisateurId = null;
    super.dispose();
  }

  /// Force le rafraîchissement des notifications
  Future<void> rafraichir() async {
    if (_utilisateurId == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Les notifications se mettront à jour automatiquement via le stream
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}