import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/phq_result.dart';
import 'package:seabot/services/phq_result_service.dart';
import 'package:sqflite/sqflite.dart';

class PHQResultsRepository {
  final PhqResultService apiService = PhqResultService();

  Future<List<PhqResult>> fetchAndSyncPHQResults(
      int studentId, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Test PHQ desde API...");

      // 1️⃣ Obtener tests desde el backend
      final resultadosTestPHQ = await apiService.getLast8ByStudent(studentId);

      // 2️⃣ Guardar o reemplazar en SQLite
      for (var test in resultadosTestPHQ) {
        print("💾 Guardando tests locales: ${test.id} - ${test.interpretation}");

        await db.insert(
          'phq_results',
          {
            'id': test.id,
            'student_id': studentId, 
            'total_score': test.totalScore,
            'interpretation': test.interpretation,
            'fecha': test.fecha.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return resultadosTestPHQ;
    } else {
      print("📴 Cargando test PHQ-9 desde SQLite (modo offline)...");

      final localData = await db.query(
        'phq_results',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      print("📦 Tests PHQ-9 locales encontradas: ${localData.length}");

      return localData.map((e) => PhqResult.fromJsonPhqs({
            "id": e["id"],
            "student_id": e["student_id"],
            "total_score": e["total_score"],
            "interpretation": e["interpretation"],
            "fecha": e["fecha"],
          })).toList();
    }
  }
}
