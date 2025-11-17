import 'package:flutter/material.dart';
import 'package:one_ztoc_app/models/faltante_item.dart';

class FaltanteListItem extends StatelessWidget {
  final FaltanteItem item;

  const FaltanteListItem({
    super.key,
    required this.item,
  });

  // Mostrar detalles del ítem faltante cuando se toca
  void _showItemDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(
          child: Text('Bien Faltante'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 25),
              _buildDetailRow('Código', item.displayCode),
              const SizedBox(height: 8),
              _buildDetailRow('Nombre', item.name),
              if (item.codSbn.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Código SBN', item.codSbn),
              ],
              if (item.codBarra.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Código de Barra', item.codBarra),
              ],
              if (item.cod2024.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Código 2024', item.cod2024),
              ],
              if (item.cod2023.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Código 2023', item.cod2023),
              ],
              if (item.cod2022.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Código 2022', item.cod2022),
              ],
              if (item.descripcion.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Información del Bien',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailRow('Descripción', item.descripcion),
              ],
              if (item.marca.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Marca', item.marca),
              ],
              if (item.modelo.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Modelo', item.modelo),
              ],
              if (item.employeeName.isNotEmpty ||
                  item.site.isNotEmpty ||
                  item.facility.isNotEmpty ||
                  item.floor.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Ubicación y Responsable',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (item.employeeName.isNotEmpty) ...[
                _buildDetailRow('Responsable', item.employeeName),
                const SizedBox(height: 8),
              ],
              if (item.site.isNotEmpty) ...[
                _buildDetailRow('Sede', item.site),
                const SizedBox(height: 8),
              ],
              if (item.facility.isNotEmpty) ...[
                _buildDetailRow('Local', item.facility),
                const SizedBox(height: 8),
              ],
              if (item.floor.isNotEmpty) ...[
                _buildDetailRow('Piso', item.floor),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(fontSize: 16),
            ),
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
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
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
            // Código del bien faltante
            Expanded(
              flex: 2,
              child: Text(
                item.displayCode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),

            // Tag de estado "Faltante" (estático, color morado)
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6), // Morado suave
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Faltante',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E35B1), // Morado oscuro
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Icono de información (clickeable)
            const SizedBox(
              width: 40,
              child: Center(
                child: Icon(
                  Icons.remove_red_eye_outlined,
                  size: 25,
                  color: Color(0xFF5E35B1), // Morado oscuro
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
