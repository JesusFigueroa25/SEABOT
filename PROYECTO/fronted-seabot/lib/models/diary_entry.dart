import 'student.dart';

class DiaryEntry {
  final int? id;
  final String? entry;
  final int? studentid;
  final DateTime fechaHora;
  final Student? student;

  DiaryEntry({
    this.id,
    this.entry,
    this.studentid,
    required this.fechaHora,
    this.student,
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //GET - Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      entry: json['entry'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      student: Student.fromJson(json['student']),
    );
  }

  factory DiaryEntry.fromJsonEntries(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      studentid: json['student_id'],
      entry: json['entry'],
      fechaHora: DateTime.parse(json['fecha_hora']),
    );
  }

  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  //Puedo crear varios
  Map<String, dynamic> toJson() {
    return {
      'entry': entry,
      'fecha_hora': fechaHora.toIso8601String(),
      'student_id': studentid,
    };
  }
}
