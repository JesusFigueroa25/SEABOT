import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/help_resource.dart';

class HelpResourceService {
  final String baseUrl = "https://seabot-backend-260367329176.southamerica-west1.run.app/helpresources";
  //final String baseUrl = "http://10.0.2.2:8080/helpresources";

  Future<void> createResource(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    print("📤 POST -> ${response.statusCode} ${response.reasonPhrase}");
    print("📦 Body: ${response.body}");

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("✅ Recurso creado correctamente");
    } else {
      throw Exception("❌ Error al crear recurso: ${response.body}");
    }
  }

  Future<List<HelpResource>> getAllResources() async {
    final response = await http.get(Uri.parse("$baseUrl/"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => HelpResource.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener recursos de ayuda");
    }
  }

  Future<HelpResource> getResourceById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return HelpResource.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener recurso con id $id");
    }
  }

  Future<void> updateResource(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteResource(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar recurso");
    }
  }

  //Funcionalidad
  Future<void> modifyEnable(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/ModifyEnable/$id"),
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
}
