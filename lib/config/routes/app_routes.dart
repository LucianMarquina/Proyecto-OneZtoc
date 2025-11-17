import 'package:flutter/material.dart';
import 'package:one_ztoc_app/presentation/screens/splash_screen.dart';
import 'package:one_ztoc_app/presentation/screens/login_screen.dart';
import 'package:one_ztoc_app/presentation/screens/home_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String scan = '/scan';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    scan: (context) => const HomeScreen(),
  };
}
