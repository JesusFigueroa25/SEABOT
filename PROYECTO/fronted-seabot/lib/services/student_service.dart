import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class StudentService {
  final String baseUrl = "http://192.168.0.6:8080/students";

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
    final url = Uri.parse("$baseUrl/$id");

    print("[StudentService] GET $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("[StudentService] status: ${response.statusCode}");
      print("[StudentService] body: ${response.body}");

      if (response.statusCode == 200) {
        return Student.fromJsonStudent(json.decode(response.body));
      }

      throw Exception(
        "Error al obtener estudiante con id $id. "
        "Status: ${response.statusCode}. Body: ${response.body}",
      );
    } catch (e) {
      print("[StudentService] ERROR GET student: $e");
      rethrow;
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/$id");

    print("[StudentService] PUT $url");
    print("[StudentService] body: ${json.encode(body)}");

    final response = await http
        .put(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode(body),
        )
        .timeout(const Duration(seconds: 10));

    print("[StudentService] status: ${response.statusCode}");
    print("[StudentService] response: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado modificado correctamente");
      return;
    }

    throw Exception(
      "Error al actualizar estudiante con id $id. "
      "Status: ${response.statusCode}. Body: ${response.body}",
    );
  }

  Future<Student> getStudentByUserId(int userId) async {
    final url = Uri.parse("$baseUrl/by-user/$userId");

    print("[StudentService] GET $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      print("[StudentService] status: ${response.statusCode}");
      print("[StudentService] body: ${response.body}");

      if (response.statusCode == 200) {
        return Student.fromJsonStudent(json.decode(response.body));
      }

      throw Exception(
        "Error al obtener estudiante por user_id $userId. "
        "Status: ${response.statusCode}. Body: ${response.body}",
      );
    } catch (e) {
      print("[StudentService] ERROR GET student by user_id: $e");
      rethrow;
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
