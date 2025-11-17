class FaltanteItem {
  final int id;
  final String name;
  final String codSbn;
  final String codBarra;
  final String cod2024;
  final String cod2023;
  final String cod2022;
  final String cod2021;
  final String cod2020;
  final String descripcion;
  final String marca;
  final String modelo;
  final String employeeName;
  final String site;
  final String facility;
  final String floor;

  FaltanteItem({
    required this.id,
    required this.name,
    required this.codSbn,
    required this.codBarra,
    required this.cod2024,
    required this.cod2023,
    required this.cod2022,
    required this.cod2021,
    required this.cod2020,
    required this.descripcion,
    required this.marca,
    required this.modelo,
    required this.employeeName,
    required this.site,
    required this.facility,
    required this.floor,
  });

  // Crear desde JSON (respuesta de Odoo)
  factory FaltanteItem.fromJson(Map<String, dynamic> json) {
    return FaltanteItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      codSbn: json['cod_sbn'] ?? '',
      codBarra: json['cod_barra'] ?? '',
      cod2024: json['cod_2024'] ?? '',
      cod2023: json['cod_2023'] ?? '',
      cod2022: json['cod_2022'] ?? '',
      cod2021: json['cod_2021'] ?? '',
      cod2020: json['cod_2020'] ?? '',
      descripcion: json['descripcion'] ?? '',
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      employeeName: json['employee_name'] ?? '',
      site: json['site'] ?? '',
      facility: json['facility'] ?? '',
      floor: json['floor'] ?? '',
    );
  }

  // Obtener el código principal (prioridad: cod_sbn > cod_barra > name)
  String get displayCode {
    if (codSbn.isNotEmpty) return codSbn;
    if (codBarra.isNotEmpty) return codBarra;
    return name;
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cod_sbn': codSbn,
      'cod_barra': codBarra,
      'cod_2024': cod2024,
      'cod_2023': cod2023,
      'cod_2022': cod2022,
      'cod_2021': cod2021,
      'cod_2020': cod2020,
      'descripcion': descripcion,
      'marca': marca,
      'modelo': modelo,
      'employee_name': employeeName,
      'site': site,
      'facility': facility,
      'floor': floor,
    };
  }
}

// Clase para la información de la captura
class CaptureInfo {
  final int id;
  final String name;
  final String ambito;

  CaptureInfo({
    required this.id,
    required this.name,
    required this.ambito,
  });

  factory CaptureInfo.fromJson(Map<String, dynamic> json) {
    return CaptureInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ambito: json['ambito'] ?? '',
    );
  }
}

// Clase para la respuesta completa de la API
class FaltantesResponse {
  final bool success;
  final String message;
  final int total;
  final int count;
  final List<FaltanteItem> faltantes;
  final CaptureInfo? captureInfo;

  FaltantesResponse({
    required this.success,
    required this.message,
    required this.total,
    required this.count,
    required this.faltantes,
    this.captureInfo,
  });

  factory FaltantesResponse.fromJson(Map<String, dynamic> json) {
    return FaltantesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      total: json['total'] ?? 0,
      count: json['count'] ?? 0,
      faltantes: (json['faltantes'] as List<dynamic>?)
              ?.map((item) => FaltanteItem.fromJson(item))
              .toList() ??
          [],
      captureInfo: json['capture_info'] != null
          ? CaptureInfo.fromJson(json['capture_info'])
          : null,
    );
  }
}
