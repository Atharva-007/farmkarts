import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Firebase core package

import 'login_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'buy_page.dart';
import 'sell_page.dart';
import 'news_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Market App',
      theme: ThemeData(
        primaryColor: Colors.teal,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
            .copyWith(secondary: Colors.orange),
        scaffoldBackgroundColor: Colors.grey[100],
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/home': (context) => const MainPage(),
        '/profile': (context) => ProfilePage(),
        '/settings': (context) => SettingsPage(),
        '/buy': (context) => const BuyPage(),
        '/sell': (context) => const SellPage(),
        '/news': (context) => NewsPage(),
      },
    );
  }
}
