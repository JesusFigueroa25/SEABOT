import 'conversation.dart';

class Summary {
  final int id;
  final int startMessageId;
  final int endMessageId;
  final String resumen;
  final DateTime fechaHora;
  final Conversation conversation;

  Summary({
    required this.id,
    required this.startMessageId,
    required this.endMessageId,
    required this.resumen,
    required this.fechaHora,
    required this.conversation,
  });
  //toma un JSON y conviértelo en un objeto Dart.
  //Puedo crear varios factorys para manejar diferentes tipos de JSON
  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'],
      startMessageId: json['start_message_id'],
      endMessageId: json['end_message_id'],
      resumen: json['resumen'],
      fechaHora: DateTime.parse(json['fecha_hora']),
      conversation: Conversation.fromJson(json['conversation']),
    );
  }
//Esto sirve cuando quieras guardar o enviar datos al servidor.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_message_id': startMessageId,
      'end_message_id': endMessageId,
      'resumen': resumen,
      'fecha_hora': fechaHora.toIso8601String(),
      'conversation': conversation.toJson(),
    };
  }
}
