import 'package:flutter/material.dart';
import 'package:one_ztoc_app/core/theme/app_theme.dart';
import 'package:one_ztoc_app/modules/auth/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Limpiar mensaje de error previo
    setState(() {
      _errorMessage = null;
    });

    final clientId = _clientIdController.text.trim();
    final clientSecret = _clientSecretController.text.trim();

    // Validación básica
    if (clientId.isEmpty || clientSecret.isEmpty) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos';
      });
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // Llamar al servicio de autenticación
      final result = await _authService.login(
        clientId: clientId,
        clientSecret: clientSecret,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Login exitoso - navegar al home
        Navigator.pushReplacementNamed(context, '/scan');
      } else {
        // Login fallido - mostrar error
        setState(() {
          _errorMessage = result['message'] ?? 'Error al iniciar sesión';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error de conexión. Intenta nuevamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),

                // Logo y nombre
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 150,                      
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),                     
                    ],
                  ),
                ),

                const SizedBox(height: 40),                

                Container(                  
                  padding: const EdgeInsets.all(30),                  
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      /* Título del formulario
                      const Text(
                        'Ingresa tus credenciales',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ), */

                      const SizedBox(height: 30),

                      // Label Client ID
                      const Text(
                        'Client ID',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Campo Client ID
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _clientIdController,                          
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu Client ID',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),                            
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,                            
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Label Client Secret

                      const Text(
                        'Client Secret',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Campo Client Secret

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _clientSecretController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Ingresa tu Client Secret',
                            hintStyle: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),      
                              borderSide: BorderSide(
                                color: AppTheme.secondaryColor
                              )                      
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppTheme.primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Mensaje de error

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.red.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Botón de login
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,                          
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),                          
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),      
                                                  
                          ),
                          elevation: 0,
                          disabledBackgroundColor: AppTheme.secondaryColor,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : const Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Sección de ayuda
                Column(
                  children: [
                    Text(
                      '¿Necesitas Ayuda?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar contacto con administrador
                      },
                      child: const Text(
                        'Contacta con el Administrador',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,                                                    
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
