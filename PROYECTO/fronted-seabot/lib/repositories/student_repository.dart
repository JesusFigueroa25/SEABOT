import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/student.dart';
import 'package:seabot/services/student_service.dart';
import 'package:sqflite/sqflite.dart';

class StudentRepository {
  final StudentService apiService = StudentService();

  Future<Student?> fetchAndSyncStudent(int identificador, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Perfil desde API...");

      // 1️⃣ Obtener perfil student desde el backend
      final perfil = await apiService.getStudentById(identificador);

      // 2️⃣ Guardar o reemplazar en SQLite
      print("💾 Guardando tests locales: ${perfil.id} - ${perfil.alias}");

      await db.insert('students', {
        'id': perfil.id,
        'user_id': perfil.userId,
        'alias': perfil.alias,
        'safe_contact': perfil.safeContact
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return perfil;
    } else {
      print("📴 Cargando perfil desde SQLite (modo offline)...");

      final localData = await db.query(
        'students',
        where: 'id = ?',
        whereArgs: [identificador],
      );
      print("📦 Student locales encontradas: ${localData.length}");

      if (localData.isNotEmpty) {
        final e = localData.first;
        return Student.fromJsonCreateUserStudent({
          "id": e["id"],
          "user_id": e["user_id"],
          "alias": e["alias"],
          "safe_contact": e["safe_contact"],
        });
      } else {
        return null; // 👈 no hay datos en local
      }
    }
  }
}
