class SupportEmailVerifyResponse {
  final String message;
  final bool correoVerificado;

  SupportEmailVerifyResponse({
    required this.message,
    required this.correoVerificado,
  });

  factory SupportEmailVerifyResponse.fromJson(Map<String, dynamic> json) {
    return SupportEmailVerifyResponse(
      message: json["message"] ?? "",
      correoVerificado: json["correo_verificado"] ?? false,
    );
  }
}