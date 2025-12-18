import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/message.dart';
import 'package:seabot/services/message_service.dart';
import 'package:sqflite/sqflite.dart';

class MessageRepository {
  final MessageService apiService = MessageService();

  Future<List<Message>> fetchAndSyncMessages(
      int conversationId, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando mensajes desde API...");

      // 1️⃣ Obtener mensajes desde el backend
      final resultadosMessages = await apiService.getMessageByConversation(conversationId);

      // 2️⃣ Guardar o reemplazar en SQLite
      for (var message in resultadosMessages) {
        print("💾 Guardando mensages locales: ${message.id} - ${message.content} - ${message.role}");

        await db.insert(
          'messages',
          {
            'id': message.id,
            'conversation_id': conversationId, 
            'role': message.role,
            'content': message.content,
            'fecha_hora': message.fechaHora.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return resultadosMessages;
    } else {
      print("📴 Cargando mensajes desde SQLite (modo offline)...");

      final localData = await db.query(
        'messages',
        where: 'conversation_id = ?',
        whereArgs: [conversationId],
      );
      print("📦 Mensajes locales encontradas: ${localData.length}");

      return localData.map((e) => Message.fromJson({
            "id": e["id"],
            "role": e["role"],
            "conversation_id": e["conversation_id"],
            "content": e["content"],
            "fecha_hora": e["fecha_hora"]
          })).toList();
    }
  }
}
