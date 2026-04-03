import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'auth_wrapper.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'theme/app_theme.dart';
import 'main_app_layout.dart';
import 'services/user_state_service.dart';
import 'services/locale_service.dart';
import 'services/theme_service.dart';
import 'l10n/app_localizations.dart';
import 'features/marketplace/add_product_page.dart';
import 'pages/selling_history_page.dart';
import 'pages/buying_list_page.dart';
import 'pages/wishlist_page.dart';
import 'pages/cart_page.dart';
import 'pages/chat_conversation_page.dart';
import 'pages/settings_page.dart';
import 'models/conversation_model.dart';
import 'models/product_model.dart';
import 'add_sell_item_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase asynchronously to prevent blocking
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Run app
  runApp(const MyApp());
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
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: child!,
              );
            },
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginPage(),
              '/signup': (context) => const SignUpPage(),
              '/home': (context) => const MainAppLayout(),
              '/add-product': (context) => const AddProductPage(),
              '/add_product': (context) => const AddSellItemPage(),
              '/selling_history': (context) => const SellingHistoryPage(),
              '/buying_list': (context) => const BuyingListPage(),
              '/wishlist': (context) => const WishlistPage(),
              '/cart': (context) => const CartPage(),
              '/settings': (context) => const SettingsPage(),
            },
            onGenerateRoute: (RouteSettings settings) {
              // Handle the /home route with arguments
              if (settings.name == '/home') {
                final args = settings.arguments as Map<String, dynamic>?;
                final initialIndex = args?['initialIndex'] as int?;
                
                return MaterialPageRoute(
                  builder: (context) => MainAppLayout(initialIndex: initialIndex),
                  settings: settings,
                );
              }
              
              // Handle the /chat route with arguments
              if (settings.name == '/chat') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null) {
                  // Create a dummy conversation from the arguments
                  final conversationId = args['conversationId'] as String? ?? '';
                  final product = args['product'] as Product?;
                  final otherUserId = args['otherUserId'] as String? ?? '';
                  final otherUserName = args['otherUserName'] as String? ?? '';
                  final productName = args['productName'] as String? ?? '';
                  
                  // Create a conversation object
                  final conversation = Conversation(
                    id: conversationId,
                    productId: product?.id ?? '',
                    productName: product?.name ?? productName,
                    buyerId: '', // Will be set by the service
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
              
              // Return null if no route found - this will trigger onUnknownRoute
              return null;
            },
            onUnknownRoute: (RouteSettings settings) {
              // Handle unknown routes gracefully
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Page Not Found')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Route "${settings.name}" not found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
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
