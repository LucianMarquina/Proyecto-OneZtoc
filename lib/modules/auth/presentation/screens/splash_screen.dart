import 'package:flutter/material.dart';
import 'package:one_ztoc_app/modules/auth/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Esperar 3 segundos para mostrar el splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Verificar si hay un token guardado
    final result = await _authService.verifyToken();

    if (!mounted) return;

    if (result['valid'] == true) {
      // Token válido - ir directamente al home
      Navigator.pushReplacementNamed(context, '/scan');
    } else {
      // Token inválido o no existe - ir al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 250,
              height: 250,              
              child: Image.asset('assets/images/logo.png')
            ),                       
          ],
        ),
      ),
    );
  }
}
