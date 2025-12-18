import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seabot/core/app_api.dart';

class OpenAIService {
  final String apiKey = AppCore.openAIKey; 
  final String apiUrl = "https://api.openai.com/v1/responses";

  Future<String> sendMessage(String userMessage) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini", // puedes usar gpt-4.1 o gpt-4o
        "input": [
          {"role": "system", "content": "Eres un chatbot de apoyo emocional, cálido y empático."},
          {"role": "user", "content": userMessage},
        ],
        "max_output_tokens": 150
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Extraer el texto de la respuesta
      final reply = data["output"][0]["content"][0]["text"];
      return reply;
    } else {
      throw Exception("Error en la API: ${response.body}");
    }
  }
}
