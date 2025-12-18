import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/diary_entry.dart';
import 'package:seabot/services/diary_entry_service.dart';
import 'package:sqflite/sqflite.dart';

class DiariosRepository {
  final DiaryEntryService apiService = DiaryEntryService();

  Future<List<DiaryEntry>> fetchAndSyncDiaries(
    int studentId,
    bool online,
  ) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando diarios desde API...");

      // 1️⃣ Obtener diarios desde el backend
      final diariosEntradas = await apiService.getLast8ByStudent(studentId);

      // 2️⃣ Guardar o reemplazar en SQLite
      for (var diario in diariosEntradas) {
        print("💾 Guardando Diarios locales: ${diario.id} - ${diario.entry}");

        await db.insert('diary_entries', {
          'id': diario.id,
          'student_id': studentId,
          'entry': diario.entry,
          'fecha_hora': diario.fechaHora.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      return diariosEntradas;
    } else {
      print("📴 Cargando diarios desde SQLite (modo offline)...");

      final localData = await db.query(
        'diary_entries',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      print("📦 Diarios locales encontradas: ${localData.length}");

      return localData
          .map(
            (e) => DiaryEntry.fromJsonEntries({
              "id": e["id"],
              "student_id": e["student_id"],
              "entry": e["entry"],
              "fecha_hora": e["fecha_hora"],
            }),
          )
          .toList();
    }
  }
}
