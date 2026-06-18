import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:seabot/models/support_email_otp_response.dart';
import 'package:seabot/models/support_email_verify_response.dart';
import 'package:seabot/models/support_report.dart';
import 'package:http_parser/http_parser.dart';
import 'package:seabot/core/app_api.dart';

class SupportReportService {
  final String baseUrl = "${AppCore.baseApiUrl}/supports";

  String _getErrorMessage(http.Response response) {
    try {
      final data = json.decode(response.body);

      if (data is Map<String, dynamic>) {
        if (data["detail"] != null) {
          return data["detail"].toString();
        }

        if (data["message"] != null) {
          return data["message"].toString();
        }
      }

      return "Ocurrió un error inesperado";
    } catch (_) {
      return "Ocurrió un error inesperado";
    }
  }

  String _getMultipartErrorMessage(String responseBody) {
    try {
      final data = json.decode(responseBody);

      if (data is Map<String, dynamic>) {
        if (data["detail"] != null) {
          return data["detail"].toString();
        }

        if (data["message"] != null) {
          return data["message"].toString();
        }
      }

      return "Ocurrió un error inesperado";
    } catch (_) {
      return "Ocurrió un error inesperado";
    }
  }

  MediaType _getImageMediaType(String path) {
    final lowerPath = path.toLowerCase();

    if (lowerPath.endsWith(".png")) {
      return MediaType("image", "png");
    }

    if (lowerPath.endsWith(".webp")) {
      return MediaType("image", "webp");
    }

    if (lowerPath.endsWith(".jpg") || lowerPath.endsWith(".jpeg")) {
      return MediaType("image", "jpeg");
    }

    return MediaType("application", "octet-stream");
  }

  Future<SupportEmailOtpResponse> sendEmailVerificationCode(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/email/send-code"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Código enviado correctamente");
      return SupportEmailOtpResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<SupportEmailVerifyResponse> verifyEmailCode(
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/email/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Correo verificado correctamente");
      return SupportEmailVerifyResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<void> createSupportReport({
    required int studentId,
    required String reportType,
    required String description,
    File? foto,
  }) async {
    final request = http.MultipartRequest("POST", Uri.parse("$baseUrl/"));

    request.fields["student_id"] = studentId.toString();
    request.fields["report_type"] = reportType;
    request.fields["description"] = description;

    if (foto != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "foto",
          foto.path,
          contentType: _getImageMediaType(foto.path),
        ),
      );
    }

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 200 ||
        streamedResponse.statusCode == 201 ||
        streamedResponse.statusCode == 204) {
      print("Reporte de soporte creado correctamente");
    } else {
      throw Exception(_getMultipartErrorMessage(responseBody));
    }
  }

  Future<List<SupportReport>> getAllReports() async {
    final response = await http.get(Uri.parse("$baseUrl/"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SupportReport.fromJson(json)).toList();
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<List<SupportReport>> getAdminReports() async {
    final response = await http.get(Uri.parse("$baseUrl/admin/list"));

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => SupportReport.fromJson(json)).toList();
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<SupportReport> getReportById(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/$id"));

    if (response.statusCode == 200) {
      return SupportReport.fromJson(json.decode(response.body));
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<void> updateReportStatus(int id, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Estado del reporte actualizado correctamente");
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<void> deleteReport(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<String?> getReportImageUrl(int reportId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/admin/$reportId/image-url"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["image_url"];
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<bool> isSupportEmailVerified(int studentId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/email/status/$studentId"),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data["correo_verificado"] == true;
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }

  Future<void> sendAdminEmailToUser(
    int reportId,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/admin/$reportId/send-email"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(body),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) {
      print("Correo enviado correctamente al usuario");
    } else {
      throw Exception(_getErrorMessage(response));
    }
  }
}
