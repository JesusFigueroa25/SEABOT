import 'student.dart';

class EmotionalRegister {
  final int? id;
  final String? emotion;
  final int? studentid;
  final DateTime fechaHora;
  final Student? student;

  EmotionalRegister({
    this.id,
    this.emotion,
    this.studentid,
    required this.fechaHora,
    this.student,
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory EmotionalRegister.fromJson(Map<String, dynamic> json) {
    return EmotionalRegister(
      id: json['id'],
      emotion: json['emotion'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      student: Student.fromJson(json['student']),
    );
  }
  factory EmotionalRegister.fromJsonEmotionals(Map<String, dynamic> json) {
    return EmotionalRegister(
      id: json['id'],
      studentid: json['student_id'],
      emotion: json['emotion'],
      fechaHora: DateTime.parse(json['fecha_hora']),
    );
  }

  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJsonEmotoin() {
    return {
      'emotion': emotion,
      'fecha_hora': fechaHora.toIso8601String(),
      'student_id': studentid,
    };
  }
}
