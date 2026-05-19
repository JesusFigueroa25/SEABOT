import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/conversation.dart';
import 'package:seabot/repositories/messages_repository.dart';
import 'package:seabot/services/conversation_service.dart';
import 'package:sqflite/sqflite.dart';

class ConversationRepository {
  final ConversationService apiService = ConversationService();
  final MessageRepository messageRepository = MessageRepository();

  Future<void> saveConversationLocal(Conversation conv, int studentId) async {
    final db = await LocalDatabase.getDB();

    await db.insert('conversations', {
      'id': conv.id,
      'student_id': studentId,
      'openai_id': conv.openaiId,
      'name_conversation': conv.nameConversation,
      'qualification': conv.qualification ?? 0,
      'fecha_inicio': conv.fechaInicio?.toIso8601String(),
      'enable': conv.enable == false ? 0 : 1,
      'is_pending': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    print(
      "💾 Conversación guardada localmente: ${conv.id} - ${conv.nameConversation}",
    );
  }

  Future<List<Conversation>> getLocalConversations(int studentId) async {
    final db = await LocalDatabase.getDB();

    final localData = await db.query(
      'conversations',
      where: 'student_id = ? AND enable = ?',
      whereArgs: [studentId, 1],
      orderBy: 'fecha_inicio DESC',
    );

    print("📦 Conversaciones locales encontradas: ${localData.length}");

    return localData.map((e) {
      return Conversation.fromJson({
        "id": e["id"],
        "student_id": e["student_id"],
        "openai_id": e["openai_id"],
        "name_conversation": e["name_conversation"],
        "qualification": e["qualification"] ?? 0,
        "fecha_inicio": e["fecha_inicio"],
        "enable": e["enable"] == 1,
      });
    }).toList();
  }

  Future<List<Conversation>> fetchAndSyncConversations(
    int studentId,
    bool online,
  ) async {
    if (online) {
      print("🌐 Cargando conversaciones desde API...");

      final conversations = await apiService.getConversationsStudent(studentId);

      print("🌐 Conversaciones recibidas API: ${conversations.length}");

      for (final conv in conversations) {
        await saveConversationLocal(conv, studentId);

        await messageRepository.syncMessagesForConversation(conv.id);
      }

      return conversations;
    } else {
      print("📴 Cargando conversaciones desde SQLite...");
      return await getLocalConversations(studentId);
    }
  }

  Future<Conversation> createAndSaveConversation(int studentId) async {
    final body = {"student_id": studentId};

    final conversation = await apiService.createConversation(body);

    await saveConversationLocal(conversation, studentId);

    return conversation;
  }

  Future<void> updateLocalConversationName(
    int conversationId,
    String newName,
  ) async {
    final db = await LocalDatabase.getDB();

    await db.update(
      'conversations',
      {'name_conversation': newName},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    print("✏️ Nombre actualizado localmente: $conversationId");
  }

  Future<void> updateLocalConversationQualification(
    int conversationId,
    int qualification,
  ) async {
    final db = await LocalDatabase.getDB();

    await db.update(
      'conversations',
      {'qualification': qualification},
      where: 'id = ?',
      whereArgs: [conversationId],
    );

    print("⭐ Valoración actualizada localmente: $conversationId");
  }
}
