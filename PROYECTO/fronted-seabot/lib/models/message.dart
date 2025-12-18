import 'conversation.dart';

class Message {
  final int id;
  final String role;
  final String content;
  final String? responseID;
  final DateTime fechaHora;
  final bool? riskFlag;
  final int? riskLevel;
  final String? sentiment;
  final String? emotion;
  final String? intention;
  final String? derivationAction;
  final Conversation? conversation;
  final int? conversationID;

  Message({
    required this.id,
    required this.role,
    required this.content,
    this.responseID,
    required this.fechaHora,
    this.riskFlag,
    this.riskLevel,
    this.sentiment,
    this.emotion,
    this.intention,
    this.derivationAction,
    this.conversation,
    this.conversationID,
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      role: json['role'],
      content: json['content'],
      responseID: json['response_id'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      conversationID: json['conversation_id']
    );
  }
  //Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'content': content,
      'response_id': responseID,
      'fecha_hora': fechaHora.toIso8601String(),
      'conversation_id': conversationID, // ✅ agregado
      'risk_flag': riskFlag,
      'risk_level': riskLevel,
      'sentiment': sentiment,
      'emotion': emotion,
      'intention': intention,
      'derivation_action': derivationAction,
    };
  }
}
