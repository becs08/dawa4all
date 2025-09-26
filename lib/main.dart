import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Services
import 'services/notification_service.dart';
import 'services/firebase/notification_firebase_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/panier_provider.dart';
import 'providers/notification_provider.dart';

// Models
import 'models/pharmacie_model.dart';
import 'models/medicament_model.dart';

// Écrans communs
import 'screens/common/loading_screen.dart';
import 'screens/common/payment_screen.dart';

// Écrans d'authentification
import 'screens/auth/start_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_selection_screen.dart';
import 'screens/auth/register_client_screen.dart';
import 'screens/auth/register_pharmacie_screen.dart';
import 'screens/auth/register_livreur_screen.dart';

// Écrans Client
import 'screens/client/client_main_screen.dart';
import 'screens/client/client_home_screen.dart';
import 'screens/client/pharmacies_list_screen.dart';
import 'screens/client/pharmacy_details_screen.dart';
import 'screens/client/medicament_details_screen.dart';
import 'screens/client/cart_screen.dart';
import 'screens/client/checkout_screen.dart';
import 'screens/client/orders_history_screen.dart';

// Écrans Pharmacie
import 'screens/pharmacie/pharmacie_dashboard_screen.dart';
import 'screens/pharmacie/medicaments_management_screen.dart';
import 'screens/pharmacie/orders_management_screen.dart';
import 'screens/pharmacie/profile_screen.dart';

// Écrans Livreur
import 'screens/livreur/livreur_dashboard_screen.dart';
import 'screens/livreur/available_deliveries_screen.dart';
import 'screens/livreur/active_delivery_screen.dart';
import 'screens/livreur/delivery_history_screen.dart';

// Écrans de test
import 'screens/test/firebase_test_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialiser les services de notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Configurer le gestionnaire des messages FCM en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PanierProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Gestionnaire pour les messages FCM en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📨 Message FCM reçu en background: ${message.notification?.title}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dawa4All',
      theme: ThemeData(
        primarySwatch: Colors.green,
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          secondary: const Color(0xFF66BB6A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // Redirection basée sur l'état d'authentification
          if (authProvider.isLoading) {
            return const LoadingScreen();
          }
          
          if (authProvider.isAuthenticated) {
            // Redirection selon le type d'utilisateur
            switch (authProvider.userType) {
              case 'client':
                return const ClientMainScreen();
              case 'pharmacie':
                return const PharmacieDashboardScreen();
              case 'livreur':
                return const LivreurDashboardScreen();
              default:
                return const StartScreen();
            }
          }
          
          return const StartScreen();
        },
      ),
      routes: {
        // Routes d'authentification
        '/start': (context) => const StartScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterSelectionScreen(),
        '/register-client': (context) => const RegisterClientScreen(),
        '/register-pharmacie': (context) => const RegisterPharmacieScreen(),
        '/register-livreur': (context) => const RegisterLivreurScreen(),
        
        // Routes communes
        '/payment': (context) => const PaymentScreen(),
        
        // Routes Client
        '/client/home': (context) => const ClientMainScreen(),
        '/client/pharmacies': (context) => const PharmaciesListScreen(),
        '/client/pharmacy-details': (context) {
          final pharmacie = ModalRoute.of(context)!.settings.arguments as PharmacieModel;
          return PharmacyDetailsScreen(pharmacie: pharmacie);
        },
        '/client/medicament-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return MedicamentDetailsScreen(
            medicament: args['medicament'],
            pharmacie: args['pharmacie'],
          );
        },
        '/client/cart': (context) => const CartScreen(),
        '/client/checkout': (context) => const CheckoutScreen(),
        '/client/orders': (context) => const OrdersHistoryScreen(),
        
        // Routes Pharmacie
        '/pharmacie/dashboard': (context) => const PharmacieDashboardScreen(),
        '/pharmacie/medicaments': (context) => const MedicamentsManagementScreen(),
        '/pharmacie/orders': (context) => const OrdersManagementScreen(),
        '/pharmacie/profile': (context) => const ProfileScreen(),
        
        // Routes Livreur
        '/livreur/dashboard': (context) => const LivreurDashboardScreen(),
        '/livreur/deliveries': (context) => const AvailableDeliveriesScreen(),
        '/livreur/active-delivery': (context) => const ActiveDeliveryScreen(),
        '/livreur/history': (context) => const DeliveryHistoryScreen(),
        
        // Routes Test
        '/test/firebase': (context) => const FirebaseTestScreen(),
      },
    );
  }
}