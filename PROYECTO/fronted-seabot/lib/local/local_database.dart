// ignore: depend_on_referenced_packages
import 'package:sqflite/sqflite.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;

  /// Inicializa la base de datos local SQLite
  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'seabot_local.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Tabla de conversaciones
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nameuser TEXT,
            password TEXT
          );
        ''');

        // Tabla de conversaciones
        await db.execute('''
          CREATE TABLE conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            openai_id TEXT,
            name_conversation TEXT,
            qualification INTEGER,
            fecha_inicio TEXT,
            enable INTEGER
          );
        ''');

        // Tabla de mensajes
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            conversation_id INTEGER,
            role TEXT,
            content TEXT,
            fecha_hora TEXT
          );
        ''');

        // Tabla de registros emocionales
        await db.execute('''
          CREATE TABLE emotional_registers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            emotion TEXT,
            fecha_hora TEXT
          );
        ''');

        // Tabla de entradas del diario
        await db.execute('''
          CREATE TABLE diary_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            entry TEXT,
            fecha_hora TEXT
          );
        ''');

        // Tabla de resultados del test PHQ-9
        await db.execute('''
          CREATE TABLE phq_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            student_id INTEGER,
            total_score INTEGER,
            interpretation TEXT,
            fecha TEXT
          );
        ''');

        // Tabla de Students
        await db.execute('''
          CREATE TABLE students (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            alias TEXT,
            safe_contact TEXT
          );
        ''');

        // Tabla de help_resources
        await db.execute('''
          CREATE TABLE help_resources (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name_resource TEXT,
            enable INTEGER,
            description TEXT,
            resource_type TEXT,
            url TEXT
          );
        ''');
      },
    );
  }

  /// Devuelve una instancia única de la base de datos
  static Future<Database> getDB() async {
    _database ??= await initDB();
    return _database!;
  }

  /// Cierra la base de datos (opcional)
  static Future<void> closeDB() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
  }

  // Insertar un registro genérico
  static Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await getDB();
    return await db.insert(
      table,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todos los registros de una tabla
  static Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await getDB();
    return await db.query(table);
  }

  // Obtener registros filtrados por una condición
  static Future<List<Map<String, dynamic>>> getBy(
    String table,
    String column,
    dynamic value,
  ) async {
    final db = await getDB();
    return await db.query(table, where: '$column = ?', whereArgs: [value]);
  }

  // Actualizar registro
  static Future<int> update(
    String table,
    Map<String, dynamic> data,
    String column,
    dynamic value,
  ) async {
    final db = await getDB();
    return await db.update(
      table,
      data,
      where: '$column = ?',
      whereArgs: [value],
    );
  }

  // Eliminar registro
  static Future<int> delete(String table, String column, dynamic value) async {
    final db = await getDB();
    return await db.delete(table, where: '$column = ?', whereArgs: [value]);
  }

  // Vaciar todas las tablas (opcional)
  static Future<void> clearAll() async {
    final db = await getDB();
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('emotional_registers');
    await db.delete('diary_entries');
    await db.delete('phq_results');
  }
}
