import 'package:flutter/material.dart';
import 'package:one_ztoc_app/models/scan_item.dart';
import 'package:one_ztoc_app/config/theme/app_theme.dart';

class ScanHistoryItem extends StatelessWidget {
  final ScanItem item;

  const ScanHistoryItem({
    super.key,
    required this.item,
  });

  // Mostrar detalles del ítem cuando se toca
  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            item.estado == 'conciliado'
                ? '✓ Bien Conciliado'
                : item.estado == 'sobrante'
                    ? 'Bien Sobrante'
                    : item.status.label,
          ),
        ),          
        content: SingleChildScrollView(                    
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 25),
              _buildDetailRow('Código', item.code),
              const SizedBox(height: 8),
              _buildDetailRow('Estado', item.status.label),
              if (item.estado != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Tipo', item.estado!),
              ],
              if (item.lotName != null) ...[
                const Divider(height: 24),
                const Text(
                  'Información del Bien',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Nombre', item.lotName ?? '-'),
                if (item.codSbn != null)
                  _buildDetailRow('Código SBN', item.codSbn ?? '-'),
                if (item.descripcion != null)
                  _buildDetailRow('Descripción', item.descripcion ?? '-'),
                if (item.marca != null)
                  _buildDetailRow('Marca', item.marca ?? '-'),
                if (item.modelo != null)
                  _buildDetailRow('Modelo', item.modelo ?? '-'),
                if (item.estadoFisico != null)
                  _buildDetailRow('Estado Físico', item.estadoFisico ?? '-'),
              ],
              if (item.errorMessage != null) ...[
                const Divider(height: 24),
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
              const Divider(height: 24),
              _buildDetailRow(
                'Fecha de escaneo',
                _formatDateTime(item.scannedAt),
              ),
              
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(fontSize: 16),),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10, right: 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
                fontSize: 16
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showItemDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            // Código
            Expanded(
              flex: 2,
              child: Text(
                item.code,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),

            // Estado (solo lectura)
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: item.status.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.status.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Icono de información (clickeable)
            SizedBox(
              width: 40,
              child: Center(
                child: Icon(
                  Icons.remove_red_eye_outlined,
                  size: 25,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
