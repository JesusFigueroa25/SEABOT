import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class StudentService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/students";
  //final String baseUrl = "http://10.0.2.2:8080/students";

  Future<Student> createStudent(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      final data = json.decode(response.body);
      return Student.fromJsonCreateUserStudent(data);
    } else {
      throw Exception("Error al crear");
    }
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
}
