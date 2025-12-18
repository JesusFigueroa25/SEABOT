import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class MessageService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/messages";
  //final String baseUrl = "http://10.0.2.2:8080/messages";

  Future<Message> createMessage(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/createMessages"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Message.fromJson(json.decode(response.body));
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      final errorMessage = errorData["detail"] ?? "Error desconocido";
      throw Exception(errorMessage);
    } else {
      throw Exception("Error al crear mensaje");
    }
  }

  Future<List<Message>> getAllMessages() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener mensajes");
    }
  }

  Future<Message> getMessageById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return Message.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener mensaje con id $id");
    }
  }

  Future<void> updateMessage(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteMessage(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar mensaje");
    }
  }

  //Funcionalidades
  Future<List<Message>> getMessageByConversation(int conversationID) async {
    final response = await http.get(
      Uri.parse("$baseUrl/GetMessages/$conversationID"),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Message.fromJson(json)).toList();
    } else {
      throw Exception(
        "Error al obtener los mensajes para la conversacion $conversationID",
      );
    }
  }
}
