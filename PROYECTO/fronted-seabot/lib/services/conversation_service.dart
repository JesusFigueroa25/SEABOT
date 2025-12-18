import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';

class ConversationService {
 final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/conversations";
 //final String baseUrl = "http://10.0.2.2:8080/conversations";

  Future<List<Conversation>> getAllConversations() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Conversation.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener conversaciones");
    }
  }

  Future<Conversation> getConversationById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Conversation.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener conversación con id $id");
    }
  }

  Future<Conversation> createConversation(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/openai"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return Conversation.fromJson(data); // ✅ Devuelve un objeto Conversation
    } else if (response.statusCode == 400) {
      final data = json.decode(response.body);
      throw Exception(data["detail"] ?? "Límite de conversaciones alcanzado");
    } else {
      throw Exception(
        "Error del servidor: ${response.statusCode} ${response.body}",
      );
    }
  }

  Future<void> updateConversation(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteConversation(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar conversación");
    }
  }

  // Funcionalidades
  Future<List<Conversation>> getConversationsStudent(int studentId) async {
    final response = await http.get(Uri.parse("$baseUrl/func/$studentId"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data
          .map((json) => Conversation.fromJsonConversations(json))
          .toList();
    } else {
      throw Exception(
        "Error al obtener los resultados para el estudiante $studentId",
      );
    }
  }

  Future<void> updateName(int id, Map<String, dynamic> body) async {
    print("updateName");
    final response = await http.put(
      Uri.parse("$baseUrl/updatename/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado modificado correctamente");
    } else {
      throw Exception("Error");
    }
  }

  Future<void> updateCalification(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/updatecalification/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado modificado correctamente");
    } else {
      throw Exception("Error");
    }
  }
}
