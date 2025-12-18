import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seabot/models/reports_models.dart';

class ReportsService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/admin/reports";

  // CA1
  Future<List<WeeklyActivity>> getWeeklyActivity() async {
    final response = await http.get(Uri.parse("$baseUrl/actividad"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => WeeklyActivity.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener actividad semanal");
    }
  }

  // CA2
  Future<List<EmotionCount>> getEmotions() async {
    final response = await http.get(Uri.parse("$baseUrl/emociones"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => EmotionCount.fromJson(e)).toList();
    } else {
      throw Exception("Error al obtener emociones");
    }
  }

  // CA3
  Future<PhqPromedio> getPhqPromedio() async {
    final response = await http.get(Uri.parse("$baseUrl/phq"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PhqPromedio.fromJson(data);
    } else {
      throw Exception("Error al obtener PHQ-9 promedio");
    }
  }

  // CA4
  Future<UsabilidadResultados> getUsabilidad() async {
    final response = await http.get(Uri.parse("$baseUrl/usabilidad"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return UsabilidadResultados.fromJson(data);
    } else {
      throw Exception("Error al obtener datos de usabilidad");
    }
  }
}
