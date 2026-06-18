import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/habit.dart';
import 'package:seabot/core/app_api.dart';

class HabitService {
  final String baseUrl = "${AppCore.baseApiUrl}/habits";
  

  Future<List<Habit>> getDailyHabits(int studentId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/daily/$studentId"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppData.token}",
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Habit.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener hábitos");
    }
  }

  Future<void> toggleHabit(int studentId, Habit habit) async {
    final response = await http.post(
      Uri.parse("$baseUrl/toggle"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AppData.token}",
      },
      body: jsonEncode(habit.toToggleJson(studentId)),
    );

    if (response.statusCode != 200) {
      throw Exception("Error al actualizar hábito");
    }
  }
}