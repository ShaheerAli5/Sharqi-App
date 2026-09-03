import 'package:flutter/material.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String verification = '/verification';
  static const String home = '/home';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        signIn: (context) => const SignInScreen(),
        verification: (context) => const VerificationScreen(),
        home: (context) => const HomeScreen(),
      };
}
