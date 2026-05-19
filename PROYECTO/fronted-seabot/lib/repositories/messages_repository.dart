import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/message.dart';
import 'package:seabot/services/message_service.dart';
import 'package:sqflite/sqflite.dart';

class MessageRepository {
  final MessageService apiService = MessageService();

  Future<void> saveLocalMessage(Message message) async {
    final db = await LocalDatabase.getDB();

    await db.insert('messages', {
      'id': message.id,
      'conversation_id': message.conversationID,
      'role': message.role,
      'content': message.content,
      'fecha_hora': message.fechaHora.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Message>> getLocalMessages(int conversationId) async {
    final db = await LocalDatabase.getDB();

    final localData = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'fecha_hora ASC',
    );

    print("📦 Mensajes locales encontrados: ${localData.length}");

    return localData.map((e) {
      return Message.fromJson({
        "id": e["id"],
        "role": e["role"],
        "conversation_id": e["conversation_id"],
        "content": e["content"],
        "response_id": e["response_id"],
        "fecha_hora": e["fecha_hora"],
      });
    }).toList();
  }

  Future<List<Message>> fetchAndSyncMessages(
    int conversationId,
    bool online,
  ) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando mensajes desde API... conversationId=$conversationId");

      final remoteMessages = await apiService.getMessageByConversation(
        conversationId,
      );

      await db.delete(
        'messages',
        where: 'conversation_id = ? AND id < 0',
        whereArgs: [conversationId],
      );

      for (final message in remoteMessages) {
        await db.insert('messages', {
          'id': message.id,
          'conversation_id': conversationId,
          'role': message.role,
          'content': message.content,
          'fecha_hora': message.fechaHora.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      print(
        "💾 Mensajes sincronizados localmente: ${remoteMessages.length} para conversación $conversationId",
      );

      return remoteMessages;
    } else {
      print("📴 Cargando mensajes desde SQLite...");
      return await getLocalMessages(conversationId);
    }
  }

  Future<void> syncMessagesForConversation(int conversationId) async {
    try {
      await fetchAndSyncMessages(conversationId, true);
    } catch (e) {
      print(
        "⚠️ No se pudieron sincronizar mensajes de conversación $conversationId: $e",
      );
    }
  }

  Future<void> markConversationPending(int conversationId, bool pending) async {
    final db = await LocalDatabase.getDB();

    await db.update(
      'conversations',
      {'is_pending': pending ? 1 : 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<bool> isConversationPending(int conversationId) async {
    final db = await LocalDatabase.getDB();

    final result = await db.query(
      'conversations',
      columns: ['is_pending'],
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    if (result.isEmpty) return false;

    return (result.first['is_pending'] as int) == 1;
  }
}
