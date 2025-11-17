import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color(0xFF35A1A2);
  static const Color secondaryColor = Color(0xFFB8E6E6);
  static const Color tertiaryColor = Color.fromARGB(255, 50, 199, 182);
  static const Color bgColor = Color.fromARGB(255, 207, 238, 238);

  static const String fontFamily = 'Roboto';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: primaryColor,
      ),
      fontFamily: fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }
}
