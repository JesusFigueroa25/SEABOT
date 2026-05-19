class SupportEmailOtpResponse {
  final String message;
  final String? correo;

  SupportEmailOtpResponse({
    required this.message,
    this.correo,
  });

  factory SupportEmailOtpResponse.fromJson(Map<String, dynamic> json) {
    return SupportEmailOtpResponse(
      message: json["message"] ?? "",
      correo: json["correo"],
    );
  }
}