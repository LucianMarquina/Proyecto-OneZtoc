import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:one_ztoc_app/models/faltante_item.dart';

class ApiService {
  // URL hardcodeada para pruebas
  static const String baseUrl = 'https://demo19.digilab.pe';
  static const String scanEndpoint = '/api/inventory/scan';
  static const String statsEndpoint = '/api/inventory/stats';
  static const String faltantesEndpoint = '/api/inventory/faltantes';

  // ID de empleado y captura para pruebas (se pueden cambiar después)
  static const int? employeeId = null; // // Un ID específico (Future Developer)
  static int? _currentCaptureId;

  static int? get currentCaptureId => _currentCaptureId;

  // Escanear un código de barras
  static Future<Map<String, dynamic>> scanBarcode(String barcode) async {
    try {
      final url = Uri.parse('$baseUrl$scanEndpoint');

      // Preparar el capture_id: si es null, enviarlo como null explícitamente
      // El servidor ahora maneja null correctamente
      final Map<String, dynamic> params = {
        'barcode': barcode,
        'employee_id': employeeId,
        'capture_id': _currentCaptureId,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': params,
        }),
      ).timeout(
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

          // Guardar el capture_id si viene en la respuesta
          if (result['capture_id'] != null) {
            _currentCaptureId = result['capture_id'];
          }

          return {
            'success': result['success'] ?? false,
            'message': result['message'] ?? '',
            'estado': result['estado'] ?? '',
            'capture_id': result['capture_id'],
            'item_data': result['item_data'],
            'error_data': result['error_data'],
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

  // Obtener estadísticas del inventario
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final url = Uri.parse('$baseUrl$statsEndpoint');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': {},
        }),
      ).timeout(
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
            return {
              'success': true,
              'stats': result['stats'] ?? {},
            };
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

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'jsonrpc': '2.0',
          'method': 'call',
          'params': params,
        }),
      ).timeout(
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

  // Reiniciar el capture_id (útil para pruebas)
  static void resetCaptureId() {
    _currentCaptureId = null;
  }
}
