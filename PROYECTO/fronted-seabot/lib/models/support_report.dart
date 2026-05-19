class SupportReport {
  final int id;
  final int studentId;
  final String reportType;
  final String description;
  final String status;
  final String? rutaFoto;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SupportReport({
    required this.id,
    required this.studentId,
    required this.reportType,
    required this.description,
    required this.status,
    this.rutaFoto,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory SupportReport.fromJson(Map<String, dynamic> json) {
    return SupportReport(
      id: json["id"] ?? 0,
      studentId: json["student_id"] ?? 0,
      reportType: json["report_type"] ?? "",
      description: json["description"] ?? "",
      status: json["status"] ?? "",
      rutaFoto: json["ruta_foto"],
      imageUrl: json["image_url"],
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"].toString())
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "student_id": studentId,
      "report_type": reportType,
      "description": description,
      "status": status,
      "ruta_foto": rutaFoto,
      "image_url": imageUrl,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}