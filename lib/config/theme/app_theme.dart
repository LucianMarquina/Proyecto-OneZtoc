import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color primaryColor = Color.fromARGB(255, 6, 113, 155);
  static const Color secondaryColor = Color.fromARGB(255, 17, 156, 210);
  static const Color tertiaryColor = Color.fromARGB(255, 27, 77, 97);
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
