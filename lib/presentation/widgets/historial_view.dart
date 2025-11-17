import 'package:flutter/material.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';
import 'package:one_ztoc_app/models/scan_item.dart';
import 'package:one_ztoc_app/models/scan_status.dart';
import 'package:one_ztoc_app/presentation/widgets/scan_history_item.dart';
import 'package:one_ztoc_app/presentation/widgets/stat_card.dart';
import 'package:one_ztoc_app/presentation/screens/search_captures_screen.dart';
import 'package:one_ztoc_app/services/database_service.dart';
import 'package:one_ztoc_app/services/api_service.dart';

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
  List<ScanItem> _scanItems = [];
  bool _isLoading = true;
  bool _isSyncing = false;

  // Calcular contadores por estado
  int get _totalCount => _scanItems.length;

  int get _pendingCount => _scanItems
      .where((item) => item.status == ScanStatus.pending)
      .length;

  int get _sentCount => _scanItems
      .where((item) => item.status == ScanStatus.sent)
      .length;

  int get _failedTemporaryCount => _scanItems
      .where((item) => item.status == ScanStatus.failed_temporary)
      .length;

  int get _failedPermanentCount => _scanItems
      .where((item) => item.status == ScanStatus.failed_permanent)
      .length;

  // Total de errores (temporal + permanente)
  int get _totalErrorCount => _failedTemporaryCount + _failedPermanentCount;

  @override
  void initState() {
    super.initState();
    _loadScanItems();
  }

  // Cargar todos los códigos desde la base de datos local
  Future<void> _loadScanItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _dbService.getAllScanItems();
      setState(() {
        _scanItems = items;
        _isLoading = false;
      });

      // Notificar el total al padre
      widget.onTotalCountChanged(_totalCount);
    } catch (e) {
      debugPrint('Error al cargar items: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // LÓGICA PRINCIPAL: Sincronizar SOLO ítems pendientes y con error TEMPORAL
  // IMPORTANTE: NO sincroniza sent ni failed_permanent
  Future<void> _sendPendingItems() async {
    // Verificar si hay ítems para sincronizar
    // SOLO pending y failed_temporary (errores que se pueden reintentar)
    final itemsToSync = _scanItems
        .where((item) =>
            item.status == ScanStatus.pending ||
            item.status == ScanStatus.failed_temporary)
        .toList();

    if (itemsToSync.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay elementos pendientes para enviar'),
          backgroundColor: Color(0xFF64748B),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    int successCount = 0;
    int errorCount = 0;

    // Procesar cada ítem
    for (var item in itemsToSync) {
      try {
        // Llamar a la API de Odoo
        final response = await ApiService.scanBarcode(item.code);

        if (response['success'] == true) {
          // ✅ ÉXITO: Actualizar a SENT (sea conciliado o sobrante)
          item.status = ScanStatus.sent;

          // Guardar datos de la respuesta
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

          item.estado = response['estado']; // conciliado, sobrante
          item.errorMessage = null;

          // Actualizar en la base de datos
          await _dbService.updateScanItem(item);
          successCount++;

          debugPrint('✓ Enviado exitosamente: ${item.code} (${item.estado})');
        } else {
          // ❌ ERROR PERMANENTE: Odoo rechazó el ítem
          item.status = ScanStatus.failed_permanent;

          // Guardar información adicional si es un error_duplicado
          if (response['estado'] == 'error_duplicado' && response['error_data'] != null) {
            final errorData = response['error_data'];
            item.estado = 'error_duplicado';
            item.errorMessage = response['message'] ??
              'Este bien ya fue registrado en ${errorData['captura_original'] ?? 'otra captura'}';

            // Guardar datos del lot si están disponibles
            item.lotId = errorData['lot_id']?.toString();
            item.lotName = errorData['lot_name'];
            item.codSbn = errorData['cod_sbn'];
            item.codBarra = errorData['cod_barra'];
          } else {
            item.errorMessage = response['message'] ?? 'Error desconocido';
          }

          // Guardar el error en la base de datos
          await _dbService.updateScanItem(item);
          errorCount++;

          debugPrint('✗ Error permanente: ${item.code} - ${item.errorMessage}');
        }
      } catch (e) {
        // ⚠ ERROR TEMPORAL: Problemas de red, timeout, error 500
        item.status = ScanStatus.failed_temporary;
        item.errorMessage = 'Error de conexión: ${e.toString()}';

        await _dbService.updateScanItem(item);
        errorCount++;

        debugPrint('⚠ Error temporal: ${item.code} - $e');
      }

      // Actualizar la UI después de cada ítem (para mostrar progreso)
      setState(() {});
    }

    // Recargar la lista completa
    await _loadScanItems();

    setState(() {
      _isSyncing = false;
    });

    // Mostrar resultado
    if (!mounted) return;

    if (errorCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $successCount elementos enviados correctamente'),
          backgroundColor: AppTheme.primaryColor,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠ Enviados: $successCount | Errores: $errorCount\n'
            'Los elementos con error permanecen en la lista.'
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Limpiar errores permanentes (duplicados)
  Future<void> _clearPermanentErrors() async {
    if (_failedPermanentCount == 0) {
      return;
    }

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Errores Permanentes'),
        content: Text(
          '¿Estás seguro de eliminar $_failedPermanentCount elemento(s) con error permanente?\n\n'
          'Estos son códigos duplicados o rechazados que no se pueden sincronizar.'
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final deletedCount = await _dbService.deleteFailedPermanentItems();
      await _loadScanItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $deletedCount errores permanentes eliminados'),
            backgroundColor: AppTheme.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      debugPrint('✓ Eliminados $deletedCount errores permanentes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('Error al eliminar errores permanentes: $e');
    }
  }

  // Método público para recargar desde el padre (cuando se escanea un nuevo código)
  void refresh() {
    _loadScanItems();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con título centrado
          const Column(
            children: [
              Center(
                child: Text(
                  'Historial de Escaneos',
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
                'Gestiona el estado de tus productos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Botones en una fila - mitad y mitad
          Row(
            children: [
              // Botón "Buscar Capturas" - Mitad izquierda
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SearchCapturesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.search, size: 22),
                  label: const Text(
                    'Buscar Capturas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Botón "Enviar Pendientes" - Mitad derecha
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _sendPendingItems,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 18),
                  label: Text(
                    _isSyncing
                        ? 'Enviando...'
                        : 'Enviar Pendientes ($_pendingCount)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_pendingCount > 0 || _failedTemporaryCount > 0) && !_isSyncing
                        ? AppTheme.primaryColor
                        : const Color(0xFF64748B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          // Botón "Limpiar Errores" (solo si hay errores permanentes) - Ancho completo
          if (_failedPermanentCount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _clearPermanentErrors,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'Limpiar Errores Permanentes ($_failedPermanentCount)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Tarjetas de estadísticas
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  iconColor: const Color(0xFF1E293B),
                  backgroundColor: const Color(0xFFF1F5F9),
                  label: 'Total',
                  value: _totalCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: ScanStatus.pending.icon,
                  iconColor: ScanStatus.pending.color,
                  backgroundColor: ScanStatus.pending.backgroundColor,
                  label: ScanStatus.pending.label,
                  value: _pendingCount,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: ScanStatus.sent.icon,
                  iconColor: ScanStatus.sent.color,
                  backgroundColor: ScanStatus.sent.backgroundColor,
                  label: ScanStatus.sent.label,
                  value: _sentCount,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.error_outline,
                  iconColor: const Color(0xFFEF4444),
                  backgroundColor: const Color(0xFFFEE2E2),
                  label: 'Errores',
                  value: _totalErrorCount,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tabla de códigos escaneados
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _scanItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 80,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay códigos escaneados',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Escanea un código para comenzar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            // Header de la tabla
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Código',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Estado',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),                                 
                                ],
                              ),
                            ),

                            // Lista de códigos
                            Expanded(
                              child: ListView.builder(
                                itemCount: _scanItems.length,
                                itemBuilder: (context, index) {
                                  return ScanHistoryItem(
                                    item: _scanItems[index],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}