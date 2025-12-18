import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/summary.dart';

class SummaryService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/summaries";
  //final String baseUrl = "http://10.0.2.2:8080/summaries";

  Future<void> createSummary(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado guardado correctamente");
    } else {
      throw Exception("Error al crear registro emocional");
    }
  }

  Future<List<Summary>> getAllSummaries() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Summary.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener resúmenes");
    }
  }

  Future<Summary> getSummaryById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Summary.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener resumen con id $id");
    }
  }

  Future<void> updateSummary(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado guardado correctamente");
    } else {
      throw Exception("Error al crear registro emocional");
    }
  }

  Future<void> deleteSummary(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar resumen");
    }
  }
}
