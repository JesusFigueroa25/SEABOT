import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/user.dart';
import 'package:seabot/services/user_service.dart';
import 'package:sqflite/sqflite.dart';

class UserRepository {
  final UserService apiService = UserService();

  Future<User?> fetchAndSyncUser(int identificador, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 usuario desde API...");

      // 1️⃣ Obtener usuario desde el backend
      final usuario = await apiService.getUserByIdLogin(identificador);

      // 2️⃣ Guardar o reemplazar en SQLite
      print("💾 Guardando user local: ${usuario.id} - ${usuario.nameuser} - ${usuario.password}");

      await db.insert('users', {
        'id': usuario.id,
        'nameuser': usuario.nameuser,
        'password': usuario.password,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return usuario;
    } else {
      print("📴 Cargando usuario desde SQLite (modo offline)...");

      final localData = await db.query(
        'students',
        where: 'id = ?',
        whereArgs: [identificador],
      );
      print("📦 usuario local encontrada: ${localData.length}");

      if (localData.isNotEmpty) {
        final e = localData.first;
        return User.fromJsonLogin({
          "id": e["id"],
          "nameuser": e["nameuser"],
          "password": e["password"]
        });
      } else {
        return null; // 👈 no hay datos en local
      }
    }
  }
}
