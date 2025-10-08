import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'views/auth/auth_wrapper.dart';
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
  
  // Firebase Emulator設定（開発環境のみ）
  if (const bool.fromEnvironment('dart.vm.product') == false) {
    try {
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
      print('Firebase Emulator設定完了: localhost:5001');
    } catch (e) {
      print('Firebase Emulator設定エラー: $e');
    }
  }
  
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
      home: const AuthWrapper(),
      routes: {
        '/main': (context) => const MainNavigationView(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

