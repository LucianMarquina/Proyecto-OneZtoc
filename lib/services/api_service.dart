import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:one_ztoc_app/models/faltante_item.dart';
import 'package:one_ztoc_app/services/storage_service.dart';

class ApiService {
  // URL hardcodeada para pruebas
  static const String baseUrl = 'https://demo19.digilab.pe';
  static const String scanEndpoint = '/api/inventory/scan';
  static const String statsEndpoint = '/api/inventory/stats';
  static const String faltantesEndpoint = '/api/inventory/faltantes';
  static const String validarCapturaEndpoint = '/api/inventory/validar-captura';
  static const String verificarPendientesEndpoint = '/api/inventory/verificar-pendientes';
  static const String marcarFaltantesEndpoint = '/api/inventory/marcar-faltantes';

  static final StorageService _storageService = StorageService();

  // Escanear un código de barras (AHORA RECIBE capture_code en lugar de capture_id)
  static Future<Map<String, dynamic>> scanBarcode(
    String barcode,
    String captureCode,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$scanEndpoint');

      // Obtener el token de acceso
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {
          'success': false,
          'message': 'Token de acceso no disponible',
          'estado': 'error_auth',
        };
      }

      final Map<String, dynamic> params = {
        'access_token': accessToken,
        'barcode': barcode,
        'capture_code': captureCode,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Odoo responde con un formato específico
        if (data.containsKey('result')) {
          final result = data['result'];

          return {
            'success': result['success'] ?? false,
            'message': result['message'] ?? '',
            'estado': result['estado'] ?? '',
            'capture_id': result['capture_id'],
            'item_data': result['item_data'],
            'error_data': result['error_data'],
            'error_code': result['error_code'],
          };
        } else if (data.containsKey('error')) {
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error desconocido',
            'estado': 'error',
          };
        } else {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
            'estado': 'error',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
          'estado': 'error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'estado': 'error',
      };
    }
  }

  // Validar si una captura existe en Odoo (NUEVO)
  static Future<Map<String, dynamic>> validarCaptura(String captureCode) async {
    try {
      final url = Uri.parse('$baseUrl$validarCapturaEndpoint');

      // Obtener el token de acceso
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {
          'success': false,
          'message': 'Token de acceso no disponible',
          'error_code': 'MISSING_TOKEN',
        };
      }

      final Map<String, dynamic> params = {
        'access_token': accessToken,
        'capture_code': captureCode,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('result')) {
          final result = data['result'];
          return {
            'success': result['success'] ?? false,
            'message': result['message'] ?? '',
            'capture': result['capture'],
            'employee': result['employee'],
            'error_code': result['error_code'],
          };
        } else if (data.containsKey('error')) {
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error desconocido',
            'error_code': 'SERVER_ERROR',
          };
        } else {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
            'error_code': 'INVALID_RESPONSE',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
          'error_code': 'HTTP_ERROR',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'error_code': 'CONNECTION_ERROR',
      };
    }
  }

  // Verificar si quedan ítems pendientes (faltantes) en una captura (NUEVO)
  static Future<Map<String, dynamic>> verificarPendientes(
    String captureCode,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$verificarPendientesEndpoint');

      // Obtener el token de acceso
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false, 'message': 'Token de acceso no disponible'};
      }

      final Map<String, dynamic> params = {
        'access_token': accessToken,
        'capture_code': captureCode,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('result')) {
          final result = data['result'];
          return {
            'success': result['success'] ?? false,
            'message': result['message'] ?? '',
            'tiene_pendientes': result['tiene_pendientes'] ?? false,
            'total_pendientes': result['total_pendientes'] ?? 0,
            'capture_code': result['capture_code'],
            'pendientes': result['pendientes'] ?? [],
          };
        } else if (data.containsKey('error')) {
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error desconocido',
          };
        } else {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Marcar todos los ítems pendientes como FALTANTES (NUEVO)
  static Future<Map<String, dynamic>> marcarFaltantes(
    String captureCode,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$marcarFaltantesEndpoint');

      // Obtener el token de acceso
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false, 'message': 'Token de acceso no disponible'};
      }

      final Map<String, dynamic> params = {
        'access_token': accessToken,
        'capture_code': captureCode,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('result')) {
          final result = data['result'];
          return {
            'success': result['success'] ?? false,
            'message': result['message'] ?? '',
            'items_marcados': result['items_marcados'] ?? 0,
            'capture_code': result['capture_code'],
          };
        } else if (data.containsKey('error')) {
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error desconocido',
          };
        } else {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener estadísticas del inventario
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final url = Uri.parse('$baseUrl$statsEndpoint');

      // Obtener el token de acceso
      final accessToken = await _storageService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return {'success': false, 'message': 'Token de acceso no disponible'};
      }

      final Map<String, dynamic> params = {'access_token': accessToken};

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('result')) {
          final result = data['result'];

          if (result['success'] == true) {
            return {'success': true, 'stats': result['stats'] ?? {}};
          } else {
            return {
              'success': false,
              'message': result['message'] ?? 'Error al obtener estadísticas',
            };
          }
        } else if (data.containsKey('error')) {
          return {
            'success': false,
            'message': data['error']['message'] ?? 'Error desconocido',
          };
        } else {
          return {
            'success': false,
            'message': 'Respuesta inválida del servidor',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Error del servidor: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Obtener bienes faltantes por captura
  static Future<FaltantesResponse> getFaltantes(String captureId) async {
    try {
      final url = Uri.parse('$baseUrl$faltantesEndpoint');

      final Map<String, dynamic> params = {
        'limit': 100,
        'offset': 0,
        'capture_id': captureId,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'jsonrpc': '2.0',
              'method': 'call',
              'params': params,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout: No se pudo conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('result')) {
          final result = data['result'];
          return FaltantesResponse.fromJson(result);
        } else if (data.containsKey('error')) {
          return FaltantesResponse(
            success: false,
            message: data['error']['message'] ?? 'Error desconocido',
            total: 0,
            count: 0,
            faltantes: [],
          );
        } else {
          return FaltantesResponse(
            success: false,
            message: 'Respuesta inválida del servidor',
            total: 0,
            count: 0,
            faltantes: [],
          );
        }
      } else {
        return FaltantesResponse(
          success: false,
          message: 'Error del servidor: ${response.statusCode}',
          total: 0,
          count: 0,
          faltantes: [],
        );
      }
    } catch (e) {
      return FaltantesResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
        total: 0,
        count: 0,
        faltantes: [],
      );
    }
  }
}
