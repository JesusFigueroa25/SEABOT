import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/message.dart';
import 'package:seabot/repositories/messages_repository.dart';
import 'package:seabot/services/message_service.dart';
import 'dart:async';

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
  final FocusNode _inputFocusNode = FocusNode();
  final MessageRepository repository = MessageRepository();

  late Future<List<Message>> resultados;
  bool _loadingInitialMessages = true;

  bool _showScrollToBottom = false;
  bool _initialScrollDone = false;
  bool _botTyping = false;
  bool _sendingMessage = false;

  static const int maxChars = 250;
  static const double _scrollToBottomThreshold = 260;
  static const Duration _streamUiUpdateInterval = Duration(milliseconds: 80);
  List<Message> _localMessages = [];

  //  bool _showingNoInternetSnack = false;

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;
      final shouldShow =
          _distanceFromBottom() > _scrollToBottomThreshold;

      if (mounted && shouldShow != _showScrollToBottom) {
        setState(() => _showScrollToBottom = shouldShow);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadResults() async {
    try {
      final pending = await repository.isConversationPending(
        widget.conversationId,
      );

      final hasInternet = await _hasInternet();

      if (hasInternet) {
        final remoteMessages = await repository.fetchAndSyncMessages(
          widget.conversationId,
          true,
        );

        if (!mounted) return;

        setState(() {
          resultados = Future.value(remoteMessages);
          _localMessages.clear();
          _sendingMessage = pending;
          _botTyping = pending;
          _loadingInitialMessages = false;
        });
      } else {
        final localMessages = await repository.getLocalMessages(
          widget.conversationId,
        );

        if (!mounted) return;

        setState(() {
          resultados = Future.value(localMessages);
          _sendingMessage = false;
          _botTyping = false;
          _loadingInitialMessages = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom(animated: false);
      });
    } catch (e) {
      final localMessages = await repository.getLocalMessages(
        widget.conversationId,
      );

      if (!mounted) return;

      setState(() {
        resultados = Future.value(localMessages);
        _sendingMessage = false;
        _botTyping = false;
        _loadingInitialMessages = false;
      });
    }
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
    if (_sendingMessage) return;

    final connected = await _hasInternet();
    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📵 No tienes conexión a internet",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    await _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El mensaje no puede estar vacío",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    if (text.length > maxChars) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Máximo $maxChars caracteres permitidos",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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

    final tempUserId = DateTime.now().millisecondsSinceEpoch * -1;
    final localMessage = Message(
      id: tempUserId,
      role: "user",
      content: text,
      fechaHora: ahora,
      conversationID: widget.conversationId,
    );

    setState(() {
      _sendingMessage = true;
      _controller.clear();
      _localMessages.add(localMessage);
      _botTyping = true;
      _loadingInitialMessages = false;
    });
    await repository.saveLocalMessage(localMessage);
    await repository.markConversationPending(widget.conversationId, true);

    _scrollToBottom(animated: true);

    int? tempBotId;
    DateTime? botMessageDate;
    String streamedText = "";
    DateTime lastStreamUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);

    void flushStreamedText({bool force = false}) {
      if (!mounted) return;

      final now = DateTime.now();
      if (!force &&
          now.difference(lastStreamUiUpdate) < _streamUiUpdateInterval) {
        return;
      }

      lastStreamUiUpdate = now;
      final shouldAutoScroll = _isNearBottom();

      setState(() {
        _loadingInitialMessages = false;

        if (tempBotId != null && botMessageDate != null) {
          _replaceLocalMessageContent(
            id: tempBotId!,
            role: "assistant",
            content: streamedText,
            fechaHora: botMessageDate!,
          );
        }
      });

      if (shouldAutoScroll) {
        _scrollToBottom(animated: false, settle: false);
      }
    }

    try {
      tempBotId = DateTime.now().millisecondsSinceEpoch * -1;
      botMessageDate = DateTime.now().toUtc();

      final botLocalMessage = Message(
        id: tempBotId!,
        role: "assistant",
        content: "",
        fechaHora: botMessageDate!,
        conversationID: widget.conversationId,
      );

      final shouldAutoScrollAfterBotBubble = _isNearBottom();

      setState(() {
        _botTyping = false;
        _localMessages.add(botLocalMessage);
        _loadingInitialMessages = false;
      });

      if (shouldAutoScrollAfterBotBubble) {
        _scrollToBottom(animated: false, settle: false);
      }

      await for (final chunk in serviceController.createMessageStream(
        inputResponse,
      )) {
        if (!mounted) return;

        if (chunk.contains("[ERROR_STREAM]")) {
          throw Exception("Error en streaming");
        }

        streamedText += chunk;

        flushStreamedText();
      }

      flushStreamedText(force: true);

      await Future.delayed(const Duration(milliseconds: 300));

      final syncedMessages = await repository.fetchAndSyncMessages(
        widget.conversationId,
        true,
      );

      await repository.markConversationPending(widget.conversationId, false);

      if (!mounted) return;

      setState(() {
        resultados = Future.value(syncedMessages);
        _localMessages.clear();
        _sendingMessage = false;
        _botTyping = false;
        _loadingInitialMessages = false;
      });

      if (mounted) {
        _scrollToBottom(animated: true);
      }
    } catch (e) {
      await repository.markConversationPending(widget.conversationId, false);

      if (!mounted) return;

      setState(() {
        _botTyping = false;
        if (tempBotId != null) {
          _removeEmptyLocalMessage(tempBotId!);
        }
        _loadingInitialMessages = false;
      });

      final errorText = e.toString().toLowerCase();

      final isConnectionError =
          errorText.contains("socketexception") ||
          errorText.contains("clientexception") ||
          errorText.contains("connection abort") ||
          errorText.contains("connection reset") ||
          errorText.contains("failed host lookup") ||
          errorText.contains("network is unreachable") ||
          errorText.contains("software caused connection abort");

      final hasInternet = await _hasInternet();

      final errorMessage = (!hasInternet || isConnectionError)
          ? "No tienes conexión a internet"
          : "Ocurrió un problema al enviar el mensaje";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingMessage = false);
      }
    }
  }

  double _distanceFromBottom() {
    if (!_scrollController.hasClients) return 0;
    return _scrollController.position.maxScrollExtent -
        _scrollController.offset;
  }

  bool _isNearBottom({double threshold = 140}) {
    if (!_scrollController.hasClients) return true;
    return _distanceFromBottom() <= threshold;
  }

  void _replaceLocalMessageContent({
    required int id,
    required String role,
    required String content,
    required DateTime fechaHora,
  }) {
    final index = _localMessages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    _localMessages[index] = Message(
      id: id,
      role: role,
      content: content,
      fechaHora: fechaHora,
      conversationID: widget.conversationId,
    );
  }

  void _removeEmptyLocalMessage(int id) {
    final index = _localMessages.indexWhere((m) => m.id == id);
    if (index == -1) return;

    if (_localMessages[index].content.trim().isEmpty) {
      _localMessages.removeAt(index);
    }
  }

  Future<void> _scrollToBottom({
    bool animated = true,
    bool settle = true,
  }) async {
    await Future.delayed(const Duration(milliseconds: 80));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_scrollController.hasClients) return;

      await Future.delayed(const Duration(milliseconds: 80));

      final target = _scrollController.position.maxScrollExtent;

      if (animated) {
        await _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(target);
      }

      if (!settle) return;

      await Future.delayed(const Duration(milliseconds: 120));

      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _copyMessage(String content) async {
    final text = content.trim();

    if (text.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El mensaje aún no está disponible para copiar",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: text));

      // Validación técnica: confirma que el texto realmente quedó en el portapapeles.
      final clipboardData = await Clipboard.getData('text/plain');

      if (clipboardData == null || clipboardData.text != text) {
        throw Exception("No se pudo validar el contenido del portapapeles");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Mensaje copiado al portapapeles",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.secundary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No se pudo copiar el mensaje",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const backgroundLight = Color(0xFFF7FAFC);
    const userBubble = Color(0xFFA3D5F4);
    final botBubble = isDark
        ? const Color(0xFF222833)
        : const Color(0xFFFFF8F7);
    final background = isDark ? const Color(0xFF0F1115) : backgroundLight;
    final inputFill = isDark
        ? const Color(0xFF1A202A)
        : const Color(0xFFFDFCF9);
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black45;

    return PopScope(
      canPop: !_sendingMessage,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Espera a que SeaBot termine de responder.",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            backgroundColor: AppColors.secundary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: background,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF0F1115),
                            const Color(0xFF151A22),
                            const Color(0xFF0F1115),
                          ]
                        : [
                            const Color(0xFFF7FAFC),
                            const Color(0xFFF9FBFD),
                            const Color(0xFFF3F6FA),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -70,
              right: -30,
              child: _buildBlurOrb(
                size: 220,
                color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.16),
              ),
            ),
            Positioned(
              top: 230,
              left: -70,
              child: _buildBlurOrb(
                size: 180,
                color: AppColors.secundary.withOpacity(isDark ? 0.10 : 0.12),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
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

                          WidgetsBinding.instance.addPostFrameCallback((
                            _,
                          ) async {
                            await Future.delayed(
                              const Duration(milliseconds: 500),
                            );

                            if (!_scrollController.hasClients) return;

                            _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent,
                            );
                          });
                        }

                        final allMessages = [
                          ...mensajesBackend,
                          ..._localMessages,
                        ];
                        final totalCount =
                            allMessages.length + (_botTyping ? 1 : 0);

                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            allMessages.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF171C24)
                                      : Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 42,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Error al cargar mensajes",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF18202A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "${snapshot.error}",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                        if (_loadingInitialMessages) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (allMessages.isEmpty && !_botTyping) {
                          return _buildEmptyState(isDark);
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 18, 14, 90),
                          itemCount: totalCount,
                          itemBuilder: (context, index) {
                            if (_botTyping && index == allMessages.length) {
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: _buildTypingBubble(botBubble, isDark),
                                ),
                              );
                            }

                            final message = allMessages[index];
                            final isUser = message.role == "user";
                            final bubbleColor = isUser ? userBubble : botBubble;
                            final textColor = isUser
                                ? AppColors.black
                                : (isDark ? Colors.white : AppColors.black);
                            final screenWidth = MediaQuery.sizeOf(
                              context,
                            ).width;
                            final bubbleMaxWidth =
                                ((screenWidth - 28) * 0.82)
                                    .clamp(220.0, 560.0)
                                    .toDouble();

                            return GestureDetector(
                              onLongPress: () async =>
                                  await _copyMessage(message.content),
                              child: Align(
                                alignment: isUser
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: bubbleMaxWidth,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      14,
                                      14,
                                      10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bubbleColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(24),
                                        topRight: const Radius.circular(24),
                                        bottomLeft: isUser
                                            ? const Radius.circular(24)
                                            : const Radius.circular(8),
                                        bottomRight: isUser
                                            ? const Radius.circular(8)
                                            : const Radius.circular(24),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(
                                            isDark ? 0.18 : 0.06,
                                          ),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.content,
                                          style: GoogleFonts.manrope(
                                            color: textColor,
                                            fontSize: 15.6,
                                            height: 1.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
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
                  SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 4),
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 6,
                        bottom: MediaQuery.of(context).viewInsets.bottom > 0
                            ? 4
                            : MediaQuery.of(context).padding.bottom + 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF171C24)
                              : Colors.white.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.04),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.18 : 0.06,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 46,
                                  maxHeight: 150,
                                ),
                                child: Scrollbar(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _inputFocusNode,
                                    maxLength: maxChars,
                                    maxLines: null,
                                    keyboardType: TextInputType.multiline,
                                    style: GoogleFonts.manrope(
                                      color: inputTextColor,
                                      fontSize: 15.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      counterText: "",
                                      hintText: "Escribe tu mensaje aquí...",
                                      hintStyle: GoogleFonts.manrope(
                                        color: hintColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: inputFill,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    onSubmitted: (_) => _onSendPressed(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _sendingMessage
                                    ? Colors.grey
                                    : const Color(0xFFA3D5F4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFA3D5F4,
                                    ).withOpacity(0.25),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: _sendingMessage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.send_rounded,
                                        color: Colors.white,
                                      ),
                                onPressed: _sendingMessage
                                    ? null
                                    : _onSendPressed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _showScrollToBottom
            ? Padding(
                padding: const EdgeInsets.only(bottom: 76),
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF9FE2D4),
                  elevation: 6,
                  child: const Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                  ),
                  onPressed: _scrollToBottom,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.secundary,
            AppColors.secundary.withOpacity(0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _sendingMessage
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Espera a que SeaBot termine de responder.",
                            style: GoogleFonts.manrope(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          backgroundColor: AppColors.secundary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  : () => Navigator.pop(context),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.24)),
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    "assets/images/SeaBot.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SeaBot",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _sendingMessage
                      ? "Escribiendo una respuesta..."
                      : "Siempre disponible para ti. 💬😇",
                  style: GoogleFonts.manrope(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : Colors.black.withOpacity(0.04),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.20 : 0.06),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "Empieza una conversación",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF18202A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Escribe tu primer mensaje y SeaBot te responderá aquí.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble(Color botBubble, bool isDark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: botBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.16 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const TypingIndicator(),
      ),
    );
  }

  Widget _buildBlurOrb({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

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
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = (_controller.value + index * 0.2) % 1.0;
        final scale = 0.75 + (t < 0.5 ? t : 1 - t) * 0.8;
        final opacity = 0.35 + (t < 0.5 ? t : 1 - t) * 1.1;

        return Opacity(
          opacity: opacity.clamp(0.35, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primaryDarkText,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            "SeaBot escribiendo",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              color: AppColors.primaryDarkText,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0),
            const SizedBox(width: 4),
            _dot(1),
            const SizedBox(width: 4),
            _dot(2),
          ],
        ),
      ],
    );
  }
}
