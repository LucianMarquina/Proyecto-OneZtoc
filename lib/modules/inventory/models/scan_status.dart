import 'package:flutter/material.dart';
import 'package:one_ztoc_app/core/theme/app_theme.dart';

enum ScanStatus {
  pending,           // Nunca enviado
  sent,              // Enviado exitosamente (conciliado o sobrante)
  failed_temporary,  // Error temporal (red, timeout, error 500) - REINTENTAR
  failed_permanent;  // Error permanente (duplicado, rechazado por Odoo) - NO REINTENTAR

  String get label {
    switch (this) {
      case ScanStatus.pending:
        return 'Pendiente';
      case ScanStatus.sent:
        return 'Enviado';
      case ScanStatus.failed_temporary:
        return 'Error Temporal';
      case ScanStatus.failed_permanent:
        return 'Error Permanente';
    }
  }

  Color get color {
    switch (this) {
      case ScanStatus.pending:
        return const Color(0xFFF59E0B); // Amarillo
      case ScanStatus.sent:
        return AppTheme.primaryColor; // Verde
      case ScanStatus.failed_temporary:
        return const Color(0xFFFF9800); // Naranja (temporal, se puede reintentar)
      case ScanStatus.failed_permanent:
        return const Color(0xFFEF4444); // Rojo (permanente, no reintentar)
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ScanStatus.pending:
        return const Color(0xFFFEF3C7); // Amarillo claro
      case ScanStatus.sent:
        return AppTheme.bgColor; // Verde claro
      case ScanStatus.failed_temporary:
        return const Color(0xFFFFF3E0); // Naranja claro
      case ScanStatus.failed_permanent:
        return const Color(0xFFFEE2E2); // Rojo claro
    }
  }

  IconData get icon {
    switch (this) {
      case ScanStatus.pending:
        return Icons.access_time;
      case ScanStatus.sent:
        return Icons.check_circle_outline;
      case ScanStatus.failed_temporary:
        return Icons.sync_problem;
      case ScanStatus.failed_permanent:
        return Icons.error_outline;
    }
  }
}
