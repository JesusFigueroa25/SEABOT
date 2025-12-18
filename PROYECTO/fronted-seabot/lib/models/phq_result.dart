import 'student.dart';

class PhqResult {
  final int? id;
  final int? totalScore;
  final int? studentid;
  final String? interpretation;
  final DateTime fecha;
  final Student? student;

  PhqResult({
    this.id,
    this.totalScore,
    this.studentid,
    this.interpretation,
    required this.fecha,
    this.student,
  });

  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory PhqResult.fromJson(Map<String, dynamic> json) {
    return PhqResult(
      id: json['id'],
      totalScore: json['total_score'],
      interpretation: json['interpretation'],
      fecha: DateTime.parse(json['fecha']),
      student: Student.fromJson(json['student']),
    );
  }
  factory PhqResult.fromJsonPhqs(Map<String, dynamic> json) {
    return PhqResult(
      id: json['id'],
      totalScore: json['total_score'],
      interpretation: json['interpretation'],
      fecha: DateTime.parse(json['fecha']),
      studentid: json['student_id'],
    );
  }

  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  //Puedo crear varios
  Map<String, dynamic> toJson() {
    return {
      'total_score': totalScore,
      'interpretation': interpretation,
      'fecha': fecha.toIso8601String().split("T")[0], // solo "2025-09-30"
      'student_id': studentid,
    };
  }
}
