import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/phq_result.dart';

class PhqResultService {
  final String baseUrl = "http://192.168.0.6:8080/phqresults";


  Future<void> createResult(Map<String, dynamic> body) async {
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
      throw Exception(
        "Error al crear resultado: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<List<PhqResult>> getAllResults() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PhqResult.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener resultados PHQ");
    }
  }

  Future<PhqResult> getResultById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return PhqResult.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener resultado con id $id");
    }
  }

  Future<PhqResult> updateResult(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200) {
      return PhqResult.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al actualizar resultado");
    }
  }

  Future<void> deleteResult(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar resultado");
    }
  }

  // Funcionalidades
  Future<List<PhqResult>> getLast8ByStudent(int studentId) async {
    final response = await http.get(Uri.parse("$baseUrl/func/$studentId"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => PhqResult.fromJsonPhqs(json)).toList();
    } else {
      throw Exception(
        "Error al obtener los últimos 8 resultados para el estudiante $studentId",
      );
    }
  }

  Future<bool> hasTakenRecently(int studentId) async {
  final response = await http.get(
    Uri.parse('$baseUrl/check/$studentId'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return data['taken_recently'] == true;
  } else {
    throw Exception('Error al verificar restricción del test');
  }
}
}
