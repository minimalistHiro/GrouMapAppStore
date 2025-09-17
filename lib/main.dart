import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/main_navigation_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBFJwEYUZeSaseeJKVu1tDCdM6PawGqGgk",
      authDomain: "groumap-ea452.firebaseapp.com",
      projectId: "groumap-ea452",
      storageBucket: "groumap-ea452.firebasestorage.app",
      messagingSenderId: "1215704250",
      appId: "1:1215704250:web:15a8763991afc67d1f6683",
      measurementId: "G-GG612PT6HQ",
    ),
  );
  
  runApp(
    const ProviderScope(
      child: GrouMapStoreApp(),
    ),
  );
}

class GrouMapStoreApp extends StatelessWidget {
  const GrouMapStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrouMap Store',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B35),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFFF6B35),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const MainNavigationView(),
      debugShowCheckedModeBanner: false,
    );
  }
}

