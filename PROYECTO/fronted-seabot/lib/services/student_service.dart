import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class StudentService {
  final String baseUrl =
      "http://192.168.0.7:8080/students";

  Future<Student> createStudent(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return Student.fromJson(data);
    }

    if (response.statusCode == 409) {
      final data = json.decode(response.body);
      final detail = data["detail"] ?? "El correo ya está registrado";
      throw Exception(detail);
    }

    throw Exception("Error al crear estudiante");
  }

  Future<List<Student>> getAllStudents() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener estudiantes");
    }
  }

  Future<Student> getStudentById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Student.fromJsonStudent(json.decode(response.body));
    } else {
      throw Exception("Error al obtener estudiante con id $id");
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteStudent(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar estudiante");
    }
  }

  Future<bool> existsCorreo(String correo) async {
    final cleanCorreo = correo.trim().toLowerCase();
    final encodedCorreo = Uri.encodeComponent(cleanCorreo);

    final response = await http.get(
      Uri.parse("$baseUrl/exists/correo/$encodedCorreo"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["exists"] == true;
    }

    throw Exception("No se pudo validar el correo");
  }
}
