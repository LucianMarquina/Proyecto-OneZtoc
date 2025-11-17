import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 1,
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
            errorMessage TEXT
          )
        ''');
      },
    );
  }

  // Insertar un nuevo código escaneado (siempre como PENDING)
  Future<int> insertScanItem(String code) async {
    final db = await database;

    final scanItem = ScanItem(
      code: code,
      status: ScanStatus.pending,
      scannedAt: DateTime.now(),
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
  // IMPORTANTE: NO incluye failed_permanent ni sent
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
  }

  // Cerrar la base de datos
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
