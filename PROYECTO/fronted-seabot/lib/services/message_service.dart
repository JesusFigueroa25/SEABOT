import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/message.dart';

class MessageService {
  final String baseUrl = "http://192.168.0.6:8080/messages";

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
      return;
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

  Stream<String> createMessageStream(Map<String, dynamic> body) async* {
    final uri = Uri.parse("$baseUrl/createMessages/stream");
    final stopwatch = Stopwatch()..start();

    final request = http.Request("POST", uri);

    request.headers.addAll({
      "Content-Type": "application/json",
      "Accept": "text/event-stream",
    });

    request.body = json.encode(body);

    final response = await request.send();
    developer.log(
      "[PERF] Chat stream response headers time: ${stopwatch.elapsedMilliseconds}ms (status: ${response.statusCode})",
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      var firstChunkLogged = false;
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        if (chunk.isNotEmpty) {
          if (!firstChunkLogged) {
            firstChunkLogged = true;
            developer.log(
              "[PERF] Chat stream first chunk time: ${stopwatch.elapsedMilliseconds}ms",
            );
          }
          yield chunk;
        }
      }
      developer.log(
        "[PERF] Chat stream total client time: ${stopwatch.elapsedMilliseconds}ms",
      );
    } else {
      await response.stream.drain();
      developer.log(
        "[PERF] Chat stream failed after: ${stopwatch.elapsedMilliseconds}ms",
      );
      throw Exception("Error streaming ${response.statusCode}");
    }
  }
}
