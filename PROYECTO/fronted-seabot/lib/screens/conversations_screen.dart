import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/conversation.dart';
import 'package:seabot/repositories/conversation_repository.dart';
import 'package:seabot/screens/chat_screen.dart';
import 'package:seabot/services/conversation_service.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int studentID = AppData.studentID;
  TextEditingController _renameController = TextEditingController();
  final ConversationService serviceController = ConversationService();
  final ConversationRepository repository = ConversationRepository();
  late Future<List<Conversation>> resultados;
  bool _isCreating = false; // 🟢 Controla si se está creando una conversación

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    bool online = await hasInternet();
    setState(() {
      resultados = repository.fetchAndSyncConversations(studentID, online);
    });
  }

  Future<bool> hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _nuevoChat() async {
    if (_isCreating) return; // evita pulsaciones múltiples
    setState(() => _isCreating = true);

    final hasNet = await hasInternet();
    if (!hasNet) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "📵 No tienes conexión a internet",
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isCreating = false);
      return;
    }

    try {
      Map<String, dynamic> createResponse = {"student_id": studentID};
      Conversation conversation = await serviceController.createConversation(
        createResponse,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Conversación creada con éxito (${conversation.nameConversation})",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: AppColors.secundary,
        ),
      );

      // 🔹 Espera ligera antes de permitir otra creación
      await Future.delayed(const Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(conversation.openaiId!, conversation.id),
        ),
      ).then((_) {
        setState(() {
          resultados = serviceController.getConversationsStudent(studentID);
        });
      });
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Theme(
          data: Theme.of(
            context,
          ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("⚠️ Error"),
            content: Text(e.toString().replaceFirst("Exception: ", "")),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _renombrarChat(Conversation conv) {
    _renameController = TextEditingController(text: conv.nameConversation);

    showDialog(
      context: context,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Theme(
          data: Theme.of(
            context,
          ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Text(
              "Renombrar conversación",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: TextField(
              controller: _renameController,
              style: GoogleFonts.manrope(
                color: isDark
                    ? Colors.white
                    : Colors.black87, // ✅ Texto visible
                fontSize: 15,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                labelText: "Nuevo nombre",
                labelStyle: GoogleFonts.manrope(
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white24
                        : Colors.grey.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancelar",
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secundary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final nuevoNombre = _renameController.text.trim();
                  if (nuevoNombre.isEmpty) return;

                  await serviceController.updateName(conv.id, {
                    "name_conversation": nuevoNombre,
                  });

                  setState(() {
                    resultados = serviceController.getConversationsStudent(
                      studentID,
                    );
                  });
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "✅ Conversación renombrada",
                        style: GoogleFonts.manrope(color: Colors.white),
                      ),
                      backgroundColor: AppColors.secundary,
                    ),
                  );
                },
                child: Text(
                  "Guardar",
                  style: GoogleFonts.manrope(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _valorarChat(Conversation conv) {
    int _rating = conv.qualification ?? 0;

    showDialog(
      context: context,
      builder: (_) => Theme(
        data: Theme.of(
          context,
        ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text("Valorar conversación"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setStateDialog(() => _rating = i + 1),
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.manrope(color: AppColors.primary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Map<String, dynamic> resultResponse = {
                      "qualification": _rating,
                    };
                    await serviceController.updateCalification(
                      conv.id,
                      resultResponse,
                    );
                    setState(() {
                      resultados = serviceController.getConversationsStudent(
                        studentID,
                      );
                      Navigator.pop(context);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "⭐ Valoración actualizada",
                          style: GoogleFonts.manrope(color: Colors.white),
                        ),
                        backgroundColor: AppColors.secundary,
                      ),
                    );
                  },
                  child: Text(
                    "Guardar",
                    style: GoogleFonts.manrope(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
        appBarTheme: theme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Mis Conversaciones"),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: FutureBuilder<List<Conversation>>(
          future: resultados,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "❌ No se pudo cargar las conversaciones.\nVerifica tu conexión.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(color: Colors.redAccent),
                ),
              );
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No hay conversaciones aún.",
                  style: GoogleFonts.manrope(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 16,
                  ),
                ),
              );
            }

            final resultadosData = snapshot.data!;
            return ListView.builder(
              itemCount: resultadosData.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final conv = resultadosData[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: theme.cardColor,
                  child: ListTile(
                    title: Text(
                      conv.nameConversation ?? "Sin nombre",
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "📅 ${DateFormat("yyyy-MM-dd HH:mm").format(conv.fechaInicio!)}",
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < (conv.qualification ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      color: theme.cardColor,
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white : Colors.black54,
                      ),
                      onSelected: (value) {
                        if (value == "rename") _renombrarChat(conv);
                        if (value == "rate") _valorarChat(conv);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "rename",
                          child: Text("Renombrar"),
                        ),
                        const PopupMenuItem(
                          value: "rate",
                          child: Text("Valorar"),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(conv.openaiId ?? ".", conv.id),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _isCreating ? Colors.grey : AppColors.secundary,
          onPressed: _isCreating ? null : _nuevoChat,
          child: _isCreating
              ? const Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
