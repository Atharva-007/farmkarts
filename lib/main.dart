import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'pages/auth_wrapper.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'theme/app_theme.dart';
import 'pages/main_app_layout.dart';
import 'services/user_state_service.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';
import 'services/fcm_service.dart';
import 'services/analytics_service.dart';
import 'services/performance_service.dart';
import 'services/sync_service.dart';
import 'services/ai_chat_service.dart';
import 'services/marketplace_service.dart';
import 'utils/app_logger.dart';
import 'l10n/app_localizations.dart';
import 'pages/add_product_page.dart';
import 'pages/selling_history_page.dart';
import 'pages/buying_list_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/cart_page.dart';
import 'pages/chat_conversation_page.dart';
import 'pages/settings_page.dart';
import 'pages/market_history_page.dart';
import 'pages/help_support_page.dart';
import 'pages/add_inventory_item_page.dart';
import 'models/conversation_model.dart';
import 'models/product_model.dart';
import 'models/inventory_model.dart';

void main() async {
  // Catch all Dart errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error('Global Flutter Error',
        error: details.exception, stackTrace: details.stack, tag: 'Main');
  };

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully', 'Main');

    // Background initialization for non-critical services
    _initializeBackgroundServices();
  } catch (e) {
    AppLogger.error('Firebase initialization failed', error: e, tag: 'Main');
  }

  runApp(const MyApp());
}

Future<void> _initializeBackgroundServices() async {
  try {
    await Future.wait([
      _initConnectivity(),
      _initAnalytics(),
      _initPerformance(),
      _initNotifications(),
      _initFCM(),
      _initSync(),
    ], eagerError: false)
        .timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        AppLogger.warning(
            'Background services initialization timed out after 15s', 'Main');
        return [];
      },
    );

    AppLogger.info('All background services initialized', 'Main');
  } catch (e) {
    AppLogger.error('Some background services failed to initialize',
        error: e, tag: 'Main');
  }
}

Future<void> _initConnectivity() async {
  try {
    final dynamic connectivityResult = await Connectivity().checkConnectivity();
    bool isOffline = false;
    if (connectivityResult is List) {
      isOffline = connectivityResult.contains(ConnectivityResult.none);
    } else {
      isOffline = connectivityResult == ConnectivityResult.none;
    }

    if (isOffline) {
      await FirebaseFirestore.instance.disableNetwork();
    }

    Connectivity().onConnectivityChanged.listen((dynamic result) async {
      bool nowOnline = false;
      if (result is List) {
        nowOnline = !result.contains(ConnectivityResult.none);
      } else {
        nowOnline = result != ConnectivityResult.none;
      }

      if (nowOnline) {
        FirebaseFirestore.instance.enableNetwork();
      } else {
        FirebaseFirestore.instance.disableNetwork();
      }
    });
  } catch (e) {
    AppLogger.error('Connectivity initialization failed',
        error: e, tag: 'Main');
  }
}

Future<void> _initAnalytics() async {
  try {
    await AnalyticsService().initialize();
    await AnalyticsService().logAppOpen();
  } catch (e) {
    AppLogger.error('Analytics initialization failed', error: e, tag: 'Main');
  }
}

Future<void> _initPerformance() async {
  try {
    await PerformanceService().initialize();
    await PerformanceService().trackAppStart();
  } catch (e) {
    AppLogger.error('Performance initialization failed', error: e, tag: 'Main');
  }
}

Future<void> _initNotifications() async {
  try {
    await NotificationService().initialize();
  } catch (e) {
    AppLogger.error('Notification initialization failed',
        error: e, tag: 'Main');
  }
}

Future<void> _initFCM() async {
  try {
    await FCMService().initialize();
  } catch (e) {
    AppLogger.error('FCM initialization failed', error: e, tag: 'Main');
  }
}

Future<void> _initSync() async {
  try {
    await SyncService().initialize();
  } catch (e) {
    AppLogger.error('Sync initialization failed', error: e, tag: 'Main');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserStateService()),
        ChangeNotifierProvider(create: (_) => LocaleService()..loadLocale()),
        ChangeNotifierProvider(create: (_) => ThemeService()..loadTheme()),
        Provider.value(value: AnalyticsService()),
        Provider.value(value: PerformanceService()),
        Provider.value(value: NotificationService()),
        Provider.value(value: FCMService()),
        Provider.value(value: SyncService()),
        Provider.value(value: AIChatService()),
        Provider.value(value: MarketplaceService()),
      ],
      child: Consumer2<LocaleService, ThemeService>(
        builder: (context, localeService, themeService, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'FarmKarts - Smart Agriculture Platform',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.materialThemeMode,
            locale: localeService.locale,
            supportedLocales: LocaleService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/home': (context) => const MainAppLayout(),
              '/add-product': (context) => const AddProductPage(),
              '/selling-history': (context) => const SellingHistoryPage(),
              '/buying-list': (context) => const BuyingListPage(),
              '/wishlist': (context) => const WishlistPage(),
              '/cart': (context) => const CartPage(),
              '/settings': (context) => const SettingsPage(),
              '/history': (context) => const MarketHistoryPage(),
              '/help': (context) => const HelpAndSupportPage(),
            },
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == '/home') {
                final args = settings.arguments as Map<String, dynamic>?;
                final initialIndex = args?['initialIndex'] as int?;
                return MaterialPageRoute(
                  builder: (context) =>
                      MainAppLayout(initialIndex: initialIndex),
                  settings: settings,
                );
              }

              if (settings.name == '/chat') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  final conversationId =
                      args['conversationId'] as String? ?? '';
                  final product = args['product'] as Product?;
                  final otherUserId = args['otherUserId'] as String? ?? '';
                  final otherUserName = args['otherUserName'] as String? ?? '';
                  final productName = args['productName'] as String? ?? '';

                  final conversation = Conversation(
                    id: conversationId,
                    productId: product?.id ?? '',
                    productName: product?.name ?? productName,
                    buyerId: '',
                    buyerName: '',
                    sellerId: otherUserId,
                    sellerName: otherUserName,
                    lastMessage: 'Starting conversation...',
                    lastMessageTime: DateTime.now(),
                    lastMessageSenderId: '',
                    createdAt: DateTime.now(),
                  );

                  return MaterialPageRoute(
                    builder: (context) => ChatConversationPage(
                      conversation: conversation,
                      product: product,
                    ),
                    settings: settings,
                  );
                }
              }

              if (settings.name == '/add-inventory-item') {
                final item = settings.arguments as InventoryItem?;
                return MaterialPageRoute(
                  builder: (context) => AddInventoryItemPage(item: item),
                  settings: settings,
                );
              }
              return null;
            },
            onUnknownRoute: (RouteSettings settings) {
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Route "${settings.name}" not found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushReplacementNamed('/'),
                          child: const Text('Go Home'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
