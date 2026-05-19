import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/habit.dart';
import 'package:seabot/services/habit_service.dart';
import 'package:sqflite/sqflite.dart';

class HabitsRepository {
  final HabitService apiService = HabitService();

  Future<List<Habit>> fetchAndSyncDailyHabits(int studentId, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando hábitos desde API...");

      // 1️⃣ Obtener hábitos diarios desde backend
      final habits = await apiService.getDailyHabits(studentId);

      // 2️⃣ Guardar catálogo de hábitos
      for (var habit in habits) {
        print("💾 Guardando hábito local: ${habit.habitId} - ${habit.nameHabit}");

        await db.insert(
          'habits',
          {
            'id': habit.habitId,
            'name_habit': habit.nameHabit,
            'description': habit.description,
            'icon_habit': habit.iconHabit,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // 3️⃣ Guardar estado diario en habit_logs
        await db.insert(
          'habit_logs',
          {
            'habit_id': habit.habitId,
            'student_id': studentId,
            'fecha': habit.fecha,
            'completed': habit.completed ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return habits;
    } else {
      print("📴 Cargando hábitos desde SQLite (modo offline)...");

      final localData = await db.rawQuery('''
        SELECT 
          h.id as habit_id,
          h.name_habit,
          h.description,
          h.icon_habit,
          hl.fecha,
          hl.completed
        FROM habits h
        LEFT JOIN habit_logs hl
          ON h.id = hl.habit_id
        WHERE hl.student_id = ?
        ORDER BY h.id ASC
      ''', [studentId]);

      print("📦 Hábitos locales encontrados: ${localData.length}");

      return localData.map((e) => Habit.fromJson({
            "habit_id": e["habit_id"],
            "name_habit": e["name_habit"],
            "description": e["description"],
            "icon_habit": e["icon_habit"],
            "fecha": e["fecha"],
            "completed": (e["completed"] == 1),
          })).toList();
    }
  }

  Future<void> toggleHabitLocal({
    required int studentId,
    required Habit habit,
  }) async {
    final db = await LocalDatabase.getDB();

    await db.insert(
      'habit_logs',
      {
        'habit_id': habit.habitId,
        'student_id': studentId,
        'fecha': habit.fecha,
        'completed': habit.completed ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print("✅ Hábito actualizado localmente: ${habit.habitId} -> ${habit.completed}");
  }
}