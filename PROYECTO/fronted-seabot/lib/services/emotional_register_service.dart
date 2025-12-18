import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emotional_register.dart';

class EmotionalRegisterService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/emotionalregisters";
  //final String baseUrl = "http://10.0.2.2:8080/emotionalregisters";

  Future<void> createRegister(Map<String, dynamic> body) async {
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

  Future<List<EmotionalRegister>> getAllRegisters() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => EmotionalRegister.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener registros emocionales");
    }
  }

  Future<EmotionalRegister> getRegisterById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return EmotionalRegister.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener registro emocional con id $id");
    }
  }

  Future<void> updateRegister(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteRegister(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar registro emocional");
    }
  }

  // Funcionalidades
  Future<List<EmotionalRegister>> getLast8ByStudent(int studentId) async {
    final response = await http.get(Uri.parse("$baseUrl/func/$studentId"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((json) => EmotionalRegister.fromJsonEmotionals(json))
          .toList();
    } else {
      throw Exception(
        "Error al obtener los últimos 8 resultados para el estudiante $studentId",
      );
    }
  }

  Future<bool> hasTakenToday(int studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/check/$studentId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['taken_today'] == true;
    } else {
      throw Exception('Error al verificar el test de hoy');
    }
  }
}
