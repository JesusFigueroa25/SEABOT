import 'package:seabot/local/local_database.dart';
import 'package:seabot/models/conversation.dart';
import 'package:seabot/services/conversation_service.dart';
import 'package:sqflite/sqflite.dart';

class ConversationRepository {
  final ConversationService apiService = ConversationService();

  Future<List<Conversation>> fetchAndSyncConversations(
      int studentId, bool online) async {
    final db = await LocalDatabase.getDB();

    if (online) {
      print("🌐 Cargando conversaciones desde API...");

      // 1️⃣ Obtener conversaciones desde el backend
      final conversations = await apiService.getConversationsStudent(studentId);

      // 2️⃣ Guardar o reemplazar en SQLite
      for (var conv in conversations) {
        print("💾 Guardando conversación local: ${conv.id} - ${conv.nameConversation}");

        await db.insert(
          'conversations',
          {
            'id': conv.id,
            'student_id': studentId, // ✅ fuerza el ID del usuario activo
            'openai_id': conv.openaiId,
            'name_conversation': conv.nameConversation,
            'qualification': conv.qualification,
            'fecha_inicio': conv.fechaInicio?.toIso8601String(),
            'enable': conv.enable == true ? 1 : 0
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      return conversations;
    } else {
      print("📴 Cargando conversaciones desde SQLite (modo offline)...");

      final localData = await db.query(
        'conversations',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
      print("📦 Conversaciones locales encontradas: ${localData.length}");

      return localData.map((e) => Conversation.fromJson({
            "id": e["id"],
            "student_id": e["student_id"],
            "openai_id": e["openai_id"],
            "name_conversation": e["name_conversation"],
            "qualification": e["qualification"],
            "fecha_inicio": e["fecha_inicio"],
            "enable": e["enable"] == 1
          })).toList();
    }
  }
}
