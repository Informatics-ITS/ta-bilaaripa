import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:monkeypox_cls_app/screens/home/home_screen.dart';
import 'package:monkeypox_cls_app/screens/auth/login_screen.dart';
import 'package:monkeypox_cls_app/screens/auth/register_screen.dart';
import 'package:monkeypox_cls_app/screens/splash/splash_screen.dart';
import 'package:monkeypox_cls_app/screens/success/success_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monkeypox Classifier App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        'home': (context) => const HomeScreen(),
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'success': (context) => const SuccessScreen(), //
      },
    );
  }
}
