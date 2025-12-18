import 'student.dart';

class Conversation {
  final int id;
  final String? openaiId;
  final String? nameConversation;
  int? qualification;
  final DateTime? fechaInicio;
  final bool? enable;
  final Student? student;
   final int? studentId;
  

  Conversation({
    required this.id,
    this.openaiId,
    this.nameConversation,
    this.qualification,
    this.fechaInicio,
    this.enable,
    this.student,
    this.studentId
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json["id"],
      openaiId: json["openai_id"],
      nameConversation: json["name_conversation"],
      qualification: json["qualification"],
      fechaInicio: DateTime.parse(json["fecha_inicio"]),
      enable: json["enable"]
    );
  }
  factory Conversation.fromJsonConversations(Map<String, dynamic> json) {
    return Conversation(
      nameConversation: json['name_conversation'],
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'])
          : null,
      qualification: json['qualification'],
      id: json['id'],
      openaiId: json["openai_id"]
    );
  }
  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'openai_id': openaiId,
      'name_conversation': nameConversation,
      'qualification': qualification,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'enable': enable,
      'student': student?.toJson(),
    };
  }
}
