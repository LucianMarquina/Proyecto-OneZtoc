import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:one_ztoc_app/services/storage_service.dart';
import 'package:one_ztoc_app/services/database_service.dart';

class AuthService {
  static const String baseUrl = 'https://demo19.digilab.pe';
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();

  // Login - Flujo de Iniciar Sesión
  Future<Map<String, dynamic>> login({
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'client_id': clientId,
            'client_secret': clientSecret,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];

        if (result['success'] == true) {
          // Limpiar la base de datos local de capturas anteriores
          await _databaseService.clearDatabase();

          // Guardar token y datos del empleado
          await _storageService.saveUserData(
            accessToken: result['access_token'],
            employeeId: result['employee']['id'],
            employeeName: result['employee']['name'],
            employeeJobTitle: result['employee']['job_title'] ?? 'Empleado',
          );

          return {
            'success': true,
            'message': result['message'],
            'employee': result['employee'],
          };
        } else {
          return {
            'success': false,
            'message': result['message'] ?? 'Credenciales inválidas',
            'error_code': result['error_code'],
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error de conexión con el servidor',
          'error_code': 'CONNECTION_ERROR',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'error_code': 'EXCEPTION',
      };
    }
  }

  // Verify - Flujo de Inicio de App
  Future<Map<String, dynamic>> verifyToken() async {
    try {
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {
          'success': false,
          'valid': false,
          'message': 'No hay token guardado',
        };
      }

      final url = Uri.parse('$baseUrl/api/auth/verify');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'params': {
            'access_token': accessToken,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['result'];

        if (result['valid'] == true) {
          return {
            'success': true,
            'valid': true,
            'employee': result['employee'],
          };
        } else {
          // Token inválido o expirado - limpiar datos locales
          await _storageService.clearUserData();
          return {
            'success': true,
            'valid': false,
            'message': result['message'] ?? 'Token inválido o expirado',
          };
        }
      } else {
        return {
          'success': false,
          'valid': false,
          'message': 'Error de conexión con el servidor',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Logout - Flujo de Cerrar Sesión
  Future<Map<String, dynamic>> logout() async {
    try {
      final accessToken = await _storageService.getAccessToken();

      if (accessToken != null && accessToken.isNotEmpty) {
        final url = Uri.parse('$baseUrl/api/auth/logout');

        try {
          await http.post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'jsonrpc': '2.0',
              'params': {
                'access_token': accessToken,
              },
            }),
          );
          // No importa la respuesta del servidor, limpiamos localmente
        } catch (e) {
          // Si hay error en la llamada, igual limpiamos localmente
        }
      }

      // Siempre limpiar datos locales y base de datos
      await _storageService.clearUserData();
      await _databaseService.clearDatabase();

      return {
        'success': true,
        'message': 'Sesión cerrada exitosamente',
      };
    } catch (e) {
      // Aunque haya error, limpiamos localmente
      await _storageService.clearUserData();
      await _databaseService.clearDatabase();
      return {
        'success': true,
        'message': 'Sesión cerrada exitosamente',
      };
    }
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    return await _storageService.hasToken();
  }

  // Obtener información del usuario guardada
  Future<Map<String, dynamic>?> getUserData() async {
    final employeeName = await _storageService.getEmployeeName();
    final employeeJobTitle = await _storageService.getEmployeeJobTitle();
    final employeeId = await _storageService.getEmployeeId();

    if (employeeName != null) {
      return {
        'name': employeeName,
        'job_title': employeeJobTitle ?? 'Empleado',
        'id': employeeId,
      };
    }

    return null;
  }
}
