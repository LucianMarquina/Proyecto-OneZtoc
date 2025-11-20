import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/models/scan_item.dart';
import 'package:one_ztoc_app/models/scan_status.dart';
import 'package:one_ztoc_app/presentation/widgets/scan_history_item.dart';
import 'package:one_ztoc_app/services/database_service.dart';
import 'package:one_ztoc_app/services/api_service.dart';
import 'package:one_ztoc_app/services/auth_service.dart';

class HistorialView extends StatefulWidget {
  final Function(int) onTotalCountChanged;

  const HistorialView({
    super.key,
    required this.onTotalCountChanged,
  });

  @override
  State<HistorialView> createState() => _HistorialViewState();
}

class _HistorialViewState extends State<HistorialView> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _captures = [];
  Map<String, List<ScanItem>> _captureItems = {};
  bool _isLoading = true;
  String? _syncingCapture; // Captura que se está sincronizando actualmente
  int? _employeeId; // ID del empleado logueado

  int get _totalCount => _captureItems.values.fold(0, (sum, items) => sum + items.length);

  @override
  void initState() {
    super.initState();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final userData = await _authService.getUserData();
    if (userData != null && mounted) {
      setState(() {
        _employeeId = userData['id'];
      });
      _loadCaptures();
    }
  }

  // Cargar todas las capturas únicas desde la base de datos local
  Future<void> _loadCaptures() async {
    if (!mounted || _employeeId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final captures = await _dbService.getUniqueCaptures(employeeId: _employeeId!);

      if (!mounted) return;

      // Solo mostrar capturas si hay al menos una con ítems
      setState(() {
        _captures = captures;
        _isLoading = false;
      });

      // Notificar el total al padre
      widget.onTotalCountChanged(_totalCount);
    } catch (e) {
      debugPrint('Error al cargar capturas: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cargar los ítems de una captura específica
  Future<List<ScanItem>> _loadCaptureItems(String captureName) async {
    if (_captureItems.containsKey(captureName)) {
      return _captureItems[captureName]!;
    }

    if (_employeeId == null) return [];

    try {
      final items = await _dbService.getItemsByCapture(captureName, employeeId: _employeeId!);

      if (!mounted) return items;

      setState(() {
        _captureItems[captureName] = items;
      });
      return items;
    } catch (e) {
      debugPrint('Error al cargar ítems de captura $captureName: $e');
      return [];
    }
  }

  // Sincronizar pendientes de una captura específica
  // IMPORTANTE: Solo sincroniza ítems con estado "pending" o "failed_temporary"
  // Los ítems con estado "sent" (enviados) se ignoran completamente
  Future<bool> _syncCaptureItems(String captureName) async {
    if (_employeeId == null) return false;

    try {
      // Obtener SOLO los ítems que necesitan sincronización (pending y failed_temporary)
      // Los ítems "sent" NO se incluyen aquí
      final itemsToSync = await _dbService.getPendingAndErrorItemsByCapture(captureName, employeeId: _employeeId!);

      if (itemsToSync.isEmpty) {
        // No hay nada pendiente por sincronizar
        debugPrint('✓ No hay ítems pendientes para sincronizar en $captureName');
        return true;
      }

      debugPrint('📤 Sincronizando ${itemsToSync.length} ítems pendientes de $captureName');

      int successCount = 0;
      int errorCount = 0;

      for (var item in itemsToSync) {
        // Verificar nuevamente que el ítem NO esté ya enviado
        if (item.status == ScanStatus.sent) {
          debugPrint('⏭️ Saltando ${item.code} - ya está enviado');
          continue; // Saltar este ítem
        }

        try {
          final response = await ApiService.scanBarcode(item.code, captureName);

          if (response['success'] == true) {
            // ✅ ÉXITO: Marcar como ENVIADO
            item.status = ScanStatus.sent;

            if (response['item_data'] != null) {
              final itemData = response['item_data'];
              item.lotId = itemData['lot_id']?.toString();
              item.lotName = itemData['lot_name'];
              item.codSbn = itemData['cod_sbn'];
              item.codBarra = itemData['cod_barra'];
              item.descripcion = itemData['descripcion'];
              item.marca = itemData['marca'];
              item.modelo = itemData['modelo'];
              item.estadoFisico = itemData['estado_fisico'];
              item.captureId = itemData['capture_id']?.toString();
              item.captureName = itemData['capture_name'];
            }

            item.estado = response['estado'];
            item.errorMessage = null;

            await _dbService.updateScanItem(item);
            successCount++;

            debugPrint('✓ Enviado: ${item.code} (${item.estado})');
          } else {
            // ❌ ERROR PERMANENTE
            item.status = ScanStatus.failed_permanent;
            item.errorMessage = response['message'] ?? 'Error desconocido';

            await _dbService.updateScanItem(item);
            errorCount++;

            debugPrint('✗ Error permanente: ${item.code} - ${item.errorMessage}');
          }
        } catch (e) {
          // ⚠️ ERROR TEMPORAL (red, timeout, etc.)
          item.status = ScanStatus.failed_temporary;
          item.errorMessage = 'Error de conexión: ${e.toString()}';

          await _dbService.updateScanItem(item);
          errorCount++;

          debugPrint('⚠ Error temporal: ${item.code} - $e');
        }
      }

      if (!mounted) return false;

      if (errorCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠ Enviados: $successCount | Errores: $errorCount'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return false;
      }

      // Mostrar mensaje de éxito si se sincronizó algo
      if (successCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $successCount ítems sincronizados correctamente'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error sincronizando captura: $e');
      return false;
    }
  }

  // FLUJO COMPLETO: Finalizar Captura
  Future<void> _finalizarCaptura(String captureName) async {
    if (_syncingCapture != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya hay una captura en proceso de finalización'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _syncingCapture = captureName;
    });

    try {
      // Paso 1: Sincronizar pendientes
      final syncSuccess = await _syncCaptureItems(captureName);

      if (!syncSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠ No se pudieron sincronizar todos los ítems. Revisa los errores.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );

          setState(() {
            _syncingCapture = null;
          });
        }
        await _loadCaptures();
        return;
      }

      // Paso 2: Verificar pendientes en Odoo
      final verificarResponse = await ApiService.verificarPendientes(captureName);

      if (!mounted) return;

      if (verificarResponse['success'] != true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al verificar pendientes: ${verificarResponse['message']}'),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _syncingCapture = null;
          });
        }
        return;
      }

      // Paso 3: Si hay pendientes, preguntar al usuario
      if (verificarResponse['tiene_pendientes'] == true) {
        final totalPendientes = verificarResponse['total_pendientes'] ?? 0;

        final confirmar = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bienes Faltantes Detectados'),
            content: Text(
              'Se detectaron $totalPendientes bienes pendientes en Odoo.\n\n'
              '¿Desea marcarlos como FALTANTES y finalizar la captura?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Marcar Faltantes'),
              ),
            ],
          ),
        );

        if (confirmar != true) {
          if (mounted) {
            setState(() {
              _syncingCapture = null;
            });
          }
          return;
        }

        // Marcar faltantes
        final marcarResponse = await ApiService.marcarFaltantes(captureName);

        if (!mounted) return;

        if (marcarResponse['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al marcar faltantes: ${marcarResponse['message']}'),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _syncingCapture = null;
          });
          return;
        }
      }

      // Paso 4: Mostrar éxito y preguntar si desea limpiar
      if (!mounted) return;

      final limpiar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Captura Finalizada'),
          content: Text(
            '✓ La captura "$captureName" se finalizó correctamente.\n\n'
            '¿Desea eliminar los datos locales de esta captura?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Mantener'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );

      if (limpiar == true && _employeeId != null) {
        await _dbService.deleteItemsByCapture(captureName, employeeId: _employeeId!);
      }

      if (!mounted) return;

      setState(() {
        _syncingCapture = null;
        _captureItems.remove(captureName);
      });

      await _loadCaptures();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Captura "$captureName" finalizada correctamente'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar captura: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() {
        _syncingCapture = null;
      });
    }
  }

  // Limpiar (eliminar) todos los códigos de una captura (mantiene la captura)
  Future<void> _limpiarCaptura(String captureName) async {
    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Códigos'),
        content: Text(
          '¿Estás seguro de eliminar todos los códigos de la captura "$captureName"?\n\n'
          'Esto borrará todos los ítems escaneados, pero la captura seguirá disponible para escanear nuevos códigos.\n\n'
          'Esta acción no se puede deshacer.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Eliminar Códigos'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_employeeId == null) return;

    try {
      // Eliminar solo los ítems/códigos, mantener la captura
      await _dbService.deleteOnlyItemsByCapture(captureName, employeeId: _employeeId!);

      // Limpiar del cache
      _captureItems.remove(captureName);

      // Recargar capturas
      await _loadCaptures();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Códigos de "$captureName" eliminados'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar códigos: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Método público para recargar desde el padre (cuando se escanea un nuevo código)
  void refresh() {
    _loadCaptures();
    _captureItems.clear(); // Limpiar cache
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _captures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: AppTheme.secondaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay capturas registradas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Por favor, selecciona y valida una captura\nprimero en la pestaña "Escanear"',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 123, 135, 154),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con título centrado (solo aparece cuando hay capturas)
                    const Column(
                      children: [
                        Center(
                          child: Text(
                            'Historial por Captura',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Gestiona tus capturas de inventario',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Lista de capturas
                    Expanded(
                      child: ListView.builder(
                        itemCount: _captures.length,
                        itemBuilder: (context, index) {
                          final capture = _captures[index];
                          final captureName = capture['captureName'] as String;
                          final totalItems = capture['totalItems'] as int;

                          return _buildCaptureGroup(captureName, totalItems);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildCaptureGroup(String captureName, int totalItems) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.all(0),  
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        backgroundColor: Colors.white,      
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    captureName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalItems ítems escaneados',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Ícono de tacho de basura para limpiar códigos
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () => _limpiarCaptura(captureName),
              tooltip: 'Limpiar códigos',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        trailing: _syncingCapture == captureName
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
        children: [
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          FutureBuilder<List<ScanItem>>(
            future: _loadCaptureItems(captureName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No hay bienes escaneados'),
                );
              }

              // Contar por estado
              final pending = items.where((i) => i.status == ScanStatus.pending).length;
              final sent = items.where((i) => i.status == ScanStatus.sent).length;
              final failedTemp = items.where((i) => i.status == ScanStatus.failed_temporary).length;
              // No mostramos errores permanentes al usuario (son errores del servidor)

              // Determinar si hay ítems pendientes por sincronizar
              final hasPendingItems = pending > 0 || failedTemp > 0;

              return Column(
                children: [
                  // Estadísticas de la captura
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatCard('Pendientes', pending, ScanStatus.pending.color,),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatCard('Enviados', sent, ScanStatus.sent.color),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Solo mostrar "Reintentar" si hay errores temporales

                        if (failedTemp > 0)
                          _buildMiniStatCard('Reintentar', failedTemp, Colors.orange),
                      ],
                    ),
                  ),

                  // Lista de ítems (máximo 8 visibles con scroll)
                  Container(
                    constraints: const BoxConstraints(
                      maxHeight: 400, // Altura máxima para ~8 ítems
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: items.length,                  
                      itemBuilder: (context, index) {
                        return ScanHistoryItem(item: items[index]);
                      },
                    ),
                  ),

                  // Botón "Finalizar Captura"
                  // Solo se puede presionar si hay ítems pendientes por sincronizar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Mensaje informativo si no hay pendientes
                        if (!hasPendingItems) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Todos los ítems ya fueron enviados',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: (_syncingCapture == captureName || !hasPendingItems)
                                ? null
                                : () => _finalizarCaptura(captureName),
                            icon: _syncingCapture == captureName
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline, size: 20),
                            label: Text(
                              _syncingCapture == captureName
                                  ? 'Finalizando...'
                                  : hasPendingItems
                                      ? 'Finalizar Captura ($pending pendientes)'
                                      : 'Captura Finalizada',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasPendingItems
                                  ? AppTheme.secondaryColor
                                  : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}