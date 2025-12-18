import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/message.dart';
import 'package:seabot/repositories/messages_repository.dart';
import 'package:seabot/services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final String openaiId;
  final int conversationId;
  const ChatScreen(this.openaiId, this.conversationId, {super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService serviceController = MessageService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final MessageRepository repository = MessageRepository();

  late Future<List<Message>> resultados;
  bool _showScrollToBottom = false;
  bool _initialScrollDone = false;
  bool _botTyping = false;
  static const int maxChars = 250;
  List<Message> _localMessages = [];

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();

    _scrollController.addListener(() {
      final distanceFromBottom =
          _scrollController.position.maxScrollExtent - _scrollController.offset;
      const threshold = 300;
      setState(() => _showScrollToBottom = distanceFromBottom > threshold);
    });
  }

  Future<void> _loadResults() async {
    bool online = await _hasInternet();
    setState(() {
      resultados = repository.fetchAndSyncMessages(
        widget.conversationId,
        online,
      );
    });
  }

  Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSendPressed() async {
    final connected = await _hasInternet();
    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📵 No tienes conexión a internet",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El mensaje no puede estar vacío",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (text.length > maxChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Máximo $maxChars caracteres permitidos",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final ahora = DateTime.now().toUtc();
    final inputResponse = {
      "role": "user",
      "content": text,
      "conversation_id": widget.conversationId,
      "openai_id": widget.openaiId,
      "fecha_hora": ahora.toIso8601String(),
      "response_id": "",
    };

    final localMessage = Message(
      id: 0,
      role: "user",
      content: text,
      fechaHora: ahora,
      conversationID: widget.conversationId,
    );

    setState(() {
      _controller.clear();
      _localMessages.add(localMessage);
      _botTyping = true;
    });
    _scrollToBottom();

    try {
      await serviceController.createMessage(inputResponse);
      setState(() {
        _botTyping = false;
        _localMessages.clear();
        resultados = serviceController.getMessageByConversation(
          widget.conversationId,
        );
      });
      _scrollToBottomAfterBuild(delayMs: 500);
    } catch (e) {
      setState(() {
        _botTyping = false;
        _localMessages.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottomAfterBuild({int delayMs = 300}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    });
  }

  void _copyMessage(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Mensaje copiado al portapapeles",
          style: GoogleFonts.manrope(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 🎨 Colores base Yana-style
    const backgroundLight = Colors.white;
    const userBubble = Color(0xFFA3D5F4);
    const botBubble = Color(0xFFfdf7f7);
    //const textColor = Color(0xFF2C3E50);

    final background = isDark ? const Color(0xFF1E1E1E) : backgroundLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 1,
        automaticallyImplyLeading: true,
        title: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Image.asset(
                "assets/images/SeaBot.png",
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
            //Text(
            //  "SeaBot",
            //  style: GoogleFonts.manrope(
            //    color: Colors.white,
            //    fontSize: 20,
            //    fontWeight: FontWeight.bold,
            //    letterSpacing: 0.5,
            //  ),
            //),
            //Text(
            //  "Siempre disponible para ti 💬",
            //  style: GoogleFonts.manrope(
            //    color: Colors.white.withOpacity(0.9),
            //    fontSize: 13,
            //    fontWeight: FontWeight.w400,
            //  ),
            //),
          ],
        ),
        centerTitle: true,
        toolbarHeight: 50, // 🔹 Más alto para el logo
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),

      body: Column(
        children: [
          // 💬 Lista de mensajes
          Expanded(
            child: FutureBuilder<List<Message>>(
              future: resultados,
              builder: (context, snapshot) {
                List<Message> mensajesBackend = [];
                if (snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData) {
                  mensajesBackend = snapshot.data!;
                }

                if (!_initialScrollDone && mensajesBackend.isNotEmpty) {
                  _initialScrollDone = true;
                  _scrollToBottomAfterBuild(delayMs: 400);
                }

                final allMessages = [...mensajesBackend, ..._localMessages];
                final totalCount = allMessages.length + (_botTyping ? 1 : 0);

                if (snapshot.connectionState == ConnectionState.waiting &&
                    allMessages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: GoogleFonts.manrope(color: Colors.redAccent),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: totalCount,
                  itemBuilder: (context, index) {
                    if (_botTyping && index == allMessages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: botBubble.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const TypingIndicator(),
                        ),
                      );
                    }

                    final message = allMessages[index];
                    final isUser = message.role == "user";
                    final bubbleColor = isUser ? userBubble : botBubble;
                    final textColor = isUser
                        ? AppColors.black
                        : AppColors.black;

                    return GestureDetector(
                      onLongPress: () => _copyMessage(message.content),
                      child: Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 280, // 🔹 límite visual tipo Yana
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(22),
                                topRight: const Radius.circular(22),
                                bottomLeft: isUser
                                    ? const Radius.circular(22)
                                    : const Radius.circular(8),
                                bottomRight: isUser
                                    ? const Radius.circular(8)
                                    : const Radius.circular(22),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              message.content,
                              style: GoogleFonts.manrope(
                                color: textColor,
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 📝 Campo inferior con SafeArea para evitar que la barra lo tape
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(
              bottom: 4,
            ), // un pequeño margen extra
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom > 0
                    ? 4
                    : MediaQuery.of(context).padding.bottom + 6,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 40,
                          maxHeight: 150,
                        ),
                        child: Scrollbar(
                          child: TextField(
                            controller: _controller,
                            maxLength: maxChars,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            style: GoogleFonts.manrope(
                              color: isDark ? Colors.black87 : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "Escribe tu mensaje aquí...",
                              hintStyle: GoogleFonts.manrope(
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFFDFCF9),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFFA3D5F4),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _onSendPressed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ⬇️ Botón flotante
      floatingActionButton: _showScrollToBottom
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton(
                backgroundColor: const Color(0xFF9FE2D4),
                child: const Icon(Icons.arrow_downward, color: Colors.white),
                onPressed: _scrollToBottom,
              ),
            )
          : null,
    );
  }
}

// ✨ Indicador de escritura
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "SeaBot está escribiendo",
          style: GoogleFonts.manrope(color: Colors.black87, fontSize: 15),
        ),
        const SizedBox(width: 6),
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            int dots = (3 * _controller.value).floor() + 1;
            return Text(
              '.' * dots,
              style: GoogleFonts.manrope(color: Colors.white, fontSize: 18),
            );
          },
        ),
      ],
    );
  }
}
