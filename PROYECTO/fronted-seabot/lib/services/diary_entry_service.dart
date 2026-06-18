import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import 'package:seabot/core/app_api.dart';

class DiaryEntryService {
  final String baseUrl = "${AppCore.baseApiUrl}/diaryentries";

  // POST create
  Future<void> createEntry(Map<String, dynamic> body) async {
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
      throw Exception("Error al crear");
    }
  }

  // GET all PHQ Results
  Future<List<DiaryEntry>> getAllEntries() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => DiaryEntry.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener entradas de diario");
    }
  }

  // GET by ID
  Future<DiaryEntry> getEntryById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return DiaryEntry.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener entrada con id $id");
    }
  }

  // PUT update
  Future<void> updateEntry(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado modificado correctamente");
    } else {
      throw Exception("Error al crear entrada");
    }
  }

  // DELETE
  Future<void> deleteEntry(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar entrada");
    }
  }

  // GET last 8 PHQ Results by student
  Future<List<DiaryEntry>> getLast8ByStudent(int studentId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/func/$studentId"),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => DiaryEntry.fromJsonEntries(json)).toList();
    } else {
      throw Exception(
        "Error al obtener los últimos 8 resultados para el estudiante $studentId",
      );
    }
  }
}
