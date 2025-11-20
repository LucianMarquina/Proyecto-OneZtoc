import 'package:one_ztoc_app/models/scan_status.dart';

class ScanItem {
  final int? id; // ID de la base de datos local
  final String code; // El código de barras escaneado
  ScanStatus status; // Estado: pending, sent, error
  final DateTime scannedAt; // Fecha/hora del escaneo

  // Datos de respuesta de la API (cuando se sincroniza)
  String? lotId; // ID del lot en Odoo
  String? lotName; // Nombre del lot
  String? codSbn;
  String? codBarra;
  String? descripcion;
  String? marca;
  String? modelo;
  String? estadoFisico;
  String? captureId; // ID de la captura en Odoo
  String? captureName;
  String? estado; // conciliado, sobrante, error_duplicado
  String? errorMessage; // Mensaje de error si falla
  int? employeeId; // ID del empleado que escaneó

  ScanItem({
    this.id,
    required this.code,
    required this.status,
    DateTime? scannedAt,
    this.lotId,
    this.lotName,
    this.codSbn,
    this.codBarra,
    this.descripcion,
    this.marca,
    this.modelo,
    this.estadoFisico,
    this.captureId,
    this.captureName,
    this.estado,
    this.errorMessage,
    this.employeeId,
  }) : scannedAt = scannedAt ?? DateTime.now();

  // Convertir de Map (de la base de datos) a ScanItem
  factory ScanItem.fromMap(Map<String, dynamic> map) {
    return ScanItem(
      id: map['id'],
      code: map['code'],
      status: ScanStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ScanStatus.pending,
      ),
      scannedAt: DateTime.parse(map['scannedAt']),
      lotId: map['lotId'],
      lotName: map['lotName'],
      codSbn: map['codSbn'],
      codBarra: map['codBarra'],
      descripcion: map['descripcion'],
      marca: map['marca'],
      modelo: map['modelo'],
      estadoFisico: map['estadoFisico'],
      captureId: map['captureId'],
      captureName: map['captureName'],
      estado: map['estado'],
      errorMessage: map['errorMessage'],
      employeeId: map['employeeId'],
    );
  }

  // Convertir de ScanItem a Map (para guardar en la base de datos)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'status': status.name,
      'scannedAt': scannedAt.toIso8601String(),
      'lotId': lotId,
      'lotName': lotName,
      'codSbn': codSbn,
      'codBarra': codBarra,
      'descripcion': descripcion,
      'marca': marca,
      'modelo': modelo,
      'estadoFisico': estadoFisico,
      'captureId': captureId,
      'captureName': captureName,
      'estado': estado,
      'errorMessage': errorMessage,
      'employeeId': employeeId,
    };
  }
}
