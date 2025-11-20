import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:one_ztoc_app/models/scan_item.dart';
import 'package:one_ztoc_app/models/scan_status.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'scan_items.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE scan_items(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL,
            status TEXT NOT NULL,
            scannedAt TEXT NOT NULL,
            lotId TEXT,
            lotName TEXT,
            codSbn TEXT,
            codBarra TEXT,
            descripcion TEXT,
            marca TEXT,
            modelo TEXT,
            estadoFisico TEXT,
            captureId TEXT,
            captureName TEXT,
            estado TEXT,
            errorMessage TEXT,
            employeeId INTEGER NOT NULL
          )
        ''');

        // Tabla para registrar capturas validadas (aunque no tengan ítems)
        await db.execute('''
          CREATE TABLE validated_captures(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            captureName TEXT NOT NULL,
            validatedAt TEXT NOT NULL,
            captureData TEXT,
            employeeId INTEGER NOT NULL,
            UNIQUE(captureName, employeeId)
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Crear la nueva tabla de capturas validadas
          await db.execute('''
            CREATE TABLE IF NOT EXISTS validated_captures(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              captureName TEXT NOT NULL UNIQUE,
              validatedAt TEXT NOT NULL,
              captureData TEXT
            )
          ''');
        }

        if (oldVersion < 3) {
          // Agregar employeeId a ambas tablas
          await db.execute('ALTER TABLE scan_items ADD COLUMN employeeId INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE validated_captures ADD COLUMN employeeId INTEGER DEFAULT 0');

          // Eliminar constraint UNIQUE anterior y crear uno nuevo que incluya employeeId
          // SQLite no soporta DROP CONSTRAINT, así que recreamos la tabla
          await db.execute('''
            CREATE TABLE validated_captures_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              captureName TEXT NOT NULL,
              validatedAt TEXT NOT NULL,
              captureData TEXT,
              employeeId INTEGER NOT NULL,
              UNIQUE(captureName, employeeId)
            )
          ''');

          await db.execute('''
            INSERT INTO validated_captures_new (id, captureName, validatedAt, captureData, employeeId)
            SELECT id, captureName, validatedAt, captureData, COALESCE(employeeId, 0)
            FROM validated_captures
          ''');

          await db.execute('DROP TABLE validated_captures');
          await db.execute('ALTER TABLE validated_captures_new RENAME TO validated_captures');
        }
      },
    );
  }

  // Insertar un nuevo código escaneado (siempre como PENDING)
  // Ahora recibe captureCode, captureName y employeeId para asociar el escaneo
  Future<int> insertScanItem(String code, {String? captureCode, String? captureName, required int employeeId}) async {
    final db = await database;

    final scanItem = ScanItem(
      code: code,
      status: ScanStatus.pending,
      scannedAt: DateTime.now(),
      captureName: captureName ?? captureCode, // Usar el código como nombre si no se proporciona
      employeeId: employeeId,
    );

    return await db.insert('scan_items', scanItem.toMap());
  }

  // Obtener todos los códigos escaneados
  Future<List<ScanItem>> getAllScanItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_items',
      orderBy: 'scannedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanItem.fromMap(maps[i]);
    });
  }

  // Obtener códigos por estado
  Future<List<ScanItem>> getScanItemsByStatus(ScanStatus status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_items',
      where: 'status = ?',
      whereArgs: [status.name],
      orderBy: 'scannedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanItem.fromMap(maps[i]);
    });
  }

  // Obtener códigos pendientes y con error TEMPORAL (para sincronización)
  // No incluye failed_permanent ni sent
  Future<List<ScanItem>> getPendingAndErrorItems() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_items',
      where: 'status = ? OR status = ?',
      whereArgs: [ScanStatus.pending.name, ScanStatus.failed_temporary.name],
      orderBy: 'scannedAt ASC',
    );

    return List.generate(maps.length, (i) {
      return ScanItem.fromMap(maps[i]);
    });
  }

  // Eliminar todos los ítems con error permanente
  Future<int> deleteFailedPermanentItems() async {
    final db = await database;
    return await db.delete(
      'scan_items',
      where: 'status = ?',
      whereArgs: [ScanStatus.failed_permanent.name],
    );
  }

  // Actualizar el estado de un código después de sincronización
  Future<int> updateScanItem(ScanItem item) async {
    final db = await database;
    return await db.update(
      'scan_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // Actualizar solo el estado
  Future<int> updateScanItemStatus(int id, ScanStatus status, {String? errorMessage}) async {
    final db = await database;

    Map<String, dynamic> updateData = {
      'status': status.name,
    };

    if (errorMessage != null) {
      updateData['errorMessage'] = errorMessage;
    }

    return await db.update(
      'scan_items',
      updateData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Contar ítems por estado
  Future<Map<String, int>> getStatusCounts() async {
    final db = await database;

    final total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_items')
    ) ?? 0;

    final pending = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_items WHERE status = ?', [ScanStatus.pending.name])
    ) ?? 0;

    final sent = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_items WHERE status = ?', [ScanStatus.sent.name])
    ) ?? 0;

    final failedTemporary = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_items WHERE status = ?', [ScanStatus.failed_temporary.name])
    ) ?? 0;

    final failedPermanent = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM scan_items WHERE status = ?', [ScanStatus.failed_permanent.name])
    ) ?? 0;

    return {
      'total': total,
      'pending': pending,
      'sent': sent,
      'failed_temporary': failedTemporary,
      'failed_permanent': failedPermanent,
    };
  }

  // Eliminar un ítem
  Future<int> deleteScanItem(int id) async {
    final db = await database;
    return await db.delete(
      'scan_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Limpiar toda la base de datos
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('scan_items');
    await db.delete('validated_captures');
  }

  // Registrar una captura validada (aunque no tenga ítems aún)
  Future<void> registerValidatedCapture(String captureName, {String? captureData, required int employeeId}) async {
    final db = await database;

    try {
      await db.insert(
        'validated_captures',
        {
          'captureName': captureName,
          'validatedAt': DateTime.now().toIso8601String(),
          'captureData': captureData,
          'employeeId': employeeId,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Si hay error (ej: captura duplicada), ignorar
      debugPrint('Captura ya registrada: $captureName para empleado $employeeId');
    }
  }

  // Obtener capturas únicas registradas (incluye validadas sin ítems)
  // Filtradas por employeeId y ordenadas por nombre ascendente
  Future<List<Map<String, dynamic>>> getUniqueCaptures({required int employeeId}) async {
    final db = await database;

    // Combinar capturas validadas con capturas que tienen ítems, filtradas por employeeId
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        COALESCE(v.captureName, s.captureName) as captureName,
        COALESCE(COUNT(s.id), 0) as totalItems,
        MIN(s.scannedAt) as firstScan,
        MAX(s.scannedAt) as lastScan,
        v.validatedAt
      FROM validated_captures v
      LEFT JOIN scan_items s ON v.captureName = s.captureName AND s.employeeId = ?
      WHERE v.employeeId = ?
      GROUP BY v.captureName

      UNION

      SELECT
        s.captureName as captureName,
        COUNT(s.id) as totalItems,
        MIN(s.scannedAt) as firstScan,
        MAX(s.scannedAt) as lastScan,
        NULL as validatedAt
      FROM scan_items s
      WHERE s.employeeId = ?
        AND s.captureName NOT IN (
          SELECT captureName FROM validated_captures WHERE employeeId = ?
        )
      GROUP BY s.captureName

      ORDER BY captureName ASC
    ''', [employeeId, employeeId, employeeId, employeeId]);

    return result;
  }

  // Obtener ítems filtrados por captura y employeeId
  Future<List<ScanItem>> getItemsByCapture(String captureName, {required int employeeId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_items',
      where: 'captureName = ? AND employeeId = ?',
      whereArgs: [captureName, employeeId],
      orderBy: 'scannedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return ScanItem.fromMap(maps[i]);
    });
  }

  // Obtener códigos pendientes y con error TEMPORAL filtrados por captura y employeeId
  Future<List<ScanItem>> getPendingAndErrorItemsByCapture(String captureName, {required int employeeId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scan_items',
      where: 'captureName = ? AND employeeId = ? AND (status = ? OR status = ?)',
      whereArgs: [captureName, employeeId, ScanStatus.pending.name, ScanStatus.failed_temporary.name],
      orderBy: 'scannedAt ASC',
    );

    return List.generate(maps.length, (i) {
      return ScanItem.fromMap(maps[i]);
    });
  }

  // Eliminar todos los ítems de una captura específica del employeeId actual
  Future<int> deleteItemsByCapture(String captureName, {required int employeeId}) async {
    final db = await database;

    // Eliminar los ítems del empleado actual
    final itemsDeleted = await db.delete(
      'scan_items',
      where: 'captureName = ? AND employeeId = ?',
      whereArgs: [captureName, employeeId],
    );

    // Eliminar también de capturas validadas del empleado actual
    await db.delete(
      'validated_captures',
      where: 'captureName = ? AND employeeId = ?',
      whereArgs: [captureName, employeeId],
    );

    return itemsDeleted;
  }

  // Eliminar solo los ítems/códigos de una captura (mantiene la captura validada)
  Future<int> deleteOnlyItemsByCapture(String captureName, {required int employeeId}) async {
    final db = await database;

    // Solo eliminar los ítems de scan_items del empleado actual, NO tocar validated_captures
    final itemsDeleted = await db.delete(
      'scan_items',
      where: 'captureName = ? AND employeeId = ?',
      whereArgs: [captureName, employeeId],
    );

    return itemsDeleted;
  }

  // Cerrar la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
