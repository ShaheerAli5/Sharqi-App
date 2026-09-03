import 'package:flutter/material.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/sign_in_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/self_service/presentation/screens/self_service_portal_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String verification = '/verification';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String selfServiceWeb = '/self-service-web';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        signIn: (context) => const SignInScreen(),
        verification: (context) => const VerificationScreen(),
        home: (context) => const HomeScreen(),
        dashboard: (context) => const DashboardScreen(),
        selfServiceWeb: (context) => const SelfServicePortalScreen(),
      };
}
