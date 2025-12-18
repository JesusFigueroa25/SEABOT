import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/emotional_register.dart';
import 'package:seabot/services/emotional_register_service.dart';
import 'package:sqflite/sqflite.dart';

class EmotionsRepository {
  final EmotionalRegisterService apiService = EmotionalRegisterService();

  Future<List<EmotionalRegister>> fetchAndSyncEmotion(
      int studentId, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando emociones desde API...");

      // 1️⃣ Obtener emociones desde el backend
      final emotionalRegisters = await apiService.getLast8ByStudent(studentId);

      // 2️⃣ Guardar o reemplazar en SQLite
      for (var emocion in emotionalRegisters) {
        print("💾 Guardando emociones locales: ${emocion.id} - ${emocion.emotion}");

        await db.insert(
          'emotional_registers',
          {
           //  'id': emocion.id,
            'student_id': studentId,
            'emotion': emocion.emotion,
            'fecha_hora': emocion.fechaHora.toIso8601String()
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return emotionalRegisters;
    } else {
      print("📴 Cargando emociones desde SQLite (modo offline)...");

      final localData = await db.query(
        'emotional_registers',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      print("📦 Emociones locales encontradas: ${localData.length}");

      return localData.map((e) => EmotionalRegister.fromJsonEmotionals({
            "id": e["id"],
            "student_id": e["student_id"],
            "emotion": e["emotion"],
            "fecha_hora": e["fecha_hora"]
          })).toList();
    }
  }
}
