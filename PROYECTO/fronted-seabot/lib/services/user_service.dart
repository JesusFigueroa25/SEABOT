import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/student.dart';
import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:seabot/core/app_api.dart';

class UserService {
  final String baseUrl = "${AppCore.baseApiUrl}/users";

  Future<User> createUser(Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    }

    if (response.statusCode == 409) {
      throw Exception("El nombre de usuario ya existe");
    }

    throw Exception("Error al crear usuario");
  }

  Future<List<User>> getAllUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  Future<User> getUserById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));
    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<User> getUserByIdLogin(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/getUserLogin/$id"));
    if (response.statusCode == 200) {
      return User.fromJsonLogin(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
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

  Future<void> deleteUser(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception("Error al eliminar usuario");
    }
  }

  //Funcionalidad
  Future<List<User>> getUsersStudent() async {
    final response = await http.get(Uri.parse("$baseUrl/UsersStudent/"));
    print("response");
    print(response);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception("Error al obtener usuarios");
    }
  }

  Future<Student> usersDetail(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/UsersDetail/$id"));
    if (response.statusCode == 200) {
      return Student.fromJson(json.decode(response.body));
    } else {
      throw Exception("Error al obtener usuario con id $id");
    }
  }

  Future<void> updateEnable(int id, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse("$baseUrl/Enable/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Resultado guardado correctamente");
    } else {
      throw Exception("Error al modificar");
    }
  }

  Future<Metricas> getMetricas() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/metricas/"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Metricas.fromJson(data);
      } else {
        throw Exception("No se pudieron cargar las métricas");
      }
    } on SocketException {
      throw Exception("Sin conexión a internet");
    } on TimeoutException {
      throw Exception("Tiempo de espera agotado");
    } catch (_) {
      throw Exception("No se pudieron cargar las métricas");
    }
  }

  //FORGOT & RESET PASSWORD
  Future<String> forgotPassword(String correo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'correo': correo}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'];
    } else if (response.statusCode == 404) {
      throw Exception("Correo no registrado");
    } else {
      throw Exception("No se pudo enviar el código");
    }
  }

  Future<String> resetPassword(String codigo, String newPassword) async {
    final response = await http.post(
      Uri.parse("$baseUrl/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"codigo": codigo, "new_password": newPassword}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["message"] ?? "Contraseña actualizada correctamente";
    } else {
      throw Exception("Error al restablecer contraseña: ${response.body}");
    }
  }
}

class AuthService {
  final String baseUrl = "${AppCore.baseApiUrl}/users";

  final _storage = const FlutterSecureStorage();

  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "nameuser": username.trim(),
        "password": password.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data["access_token"];

      // Obtiene la expiración real del JWT.
      // Si no puede leerla, usa 15 minutos como respaldo.
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));
      // Guardar token y fecha de expiración
      await _storage.write(key: "auth_token", value: token);
      await _storage.write(
        key: "auth_token_expires_at",
        value: expiresAt.toIso8601String(),
      );

      // Guardar user_id
      await _storage.write(key: "user_id", value: data["id"].toString());

      // Manejar student_id
      final studentId = data["student_id"];
      if (studentId != null) {
        await _storage.write(key: "student_id", value: studentId.toString());
        AppData.studentID = studentId;
      } else {
        await _storage.delete(key: "student_id");
        AppData.studentID = 0;
      }

      // Guardar role
      final role = data["role"];
      if (role != null) {
        await _storage.write(key: "role", value: role);
        AppData.role = role;
      } else {
        await _storage.delete(key: "role");
        AppData.role = "";
      }

      // Guardar en memoria
      AppData.userID = data["id"];
      AppData.token = token;

      return token;
    } else {
      final data = json.decode(response.body);
      final detail = data["detail"] ?? "Error al iniciar sesión";

      throw Exception(detail);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: "auth_token");
    await _storage.delete(key: "auth_token_expires_at");
    await _storage.delete(key: "student_id");
    await _storage.delete(key: "user_id");
    await _storage.delete(key: "role");

    AppData.token = "";
    AppData.studentID = 0;
    AppData.userID = 0;
    AppData.role = "";
  }

  Future<String?> getToken() async {
    return await _storage.read(key: "auth_token");
  }

  /* 
  Future<String?> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/user/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"nameuser": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data["access_token"];

      // ✅ Guarda también los IDs
      await _storage.write(key: "auth_token", value: token);
      await _storage.write(key: "user_id", value: data["id"].toString());
      await _storage.write(
        key: "student_id",
        value: data["student_id"].toString(),
      );

      // Asigna a memoria
      AppData.userID = data["id"];
      AppData.studentID = data["student_id"];

      return token;
    } else {
      return null;
    }
  }

  Future<String?> loginAdmin(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/admin/"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"nameuser": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data["access_token"];
      await _storage.write(key: "auth_token", value: token); // ✅ guardar
      return token;
    } else {
      return null;
    }
  }
*/
}
