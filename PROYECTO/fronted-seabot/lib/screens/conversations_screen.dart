import 'dart:io';
import 'dart:ui';
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
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    resultados = _getInitialConversations();
  }

  Future<List<Conversation>> _getInitialConversations() async {
    final online = await hasInternet();
    debugPrint("📌 studentID: $studentID");
    return repository.fetchAndSyncConversations(studentID, online);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final online = await hasInternet();
    if (!mounted) return;
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
    if (_isCreating) return;
    setState(() => _isCreating = true);

    final hasNet = await hasInternet();
    if (!hasNet) {
      if (mounted) {
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
      }
      if (mounted) setState(() => _isCreating = false);
      return;
    }

    try {
      Conversation conversation = await repository.createAndSaveConversation(
        studentID,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Conversación creada con éxito (${conversation.nameConversation})",
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

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ChatScreen(conversation.openaiId!, conversation.id),
        ),
      ).then((_) {
        if (!mounted) return;
        _loadConversations();
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
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "⚠️ Error",
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            content: Text(
              e.toString().replaceFirst("Exception: ", ""),
              style: GoogleFonts.manrope(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
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
    _renameController.text = conv.nameConversation ?? "";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
          child: AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1F232B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              "Renombrar conversación",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: TextField(
              controller: _renameController,
              style: GoogleFonts.manrope(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                labelText: "Nuevo nombre",
                filled: true,
                fillColor: isDark ? const Color(0xFF171C24) : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  "Cancelar",
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secundary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final nuevoNombre = _renameController.text.trim();
                  if (nuevoNombre.isEmpty) return;

                  final online = await hasInternet();

                  if (!online) {
                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Sin conexión a internet",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  try {
                    await serviceController.updateName(conv.id, {
                      "name_conversation": nuevoNombre,
                    });
                    await repository.updateLocalConversationName(
                      conv.id,
                      nuevoNombre,
                    );

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    _loadConversations();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✅ Conversación renombrada",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: AppColors.secundary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "❌ Error al renombrar conversación",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: Text(
                  "Guardar",
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _valorarChat(Conversation conv) {
    int rating = conv.qualification ?? 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogContext) => Theme(
        data: Theme.of(
          context,
        ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F232B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                "Valorar conversación",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Selecciona una puntuación del 1 al 5",
                    style: GoogleFonts.manrope(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () => setStateDialog(() => rating = i + 1),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "Cancelar",
                    style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secundary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final online = await hasInternet();

                    if (!online) {
                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Sin conexión a internet",
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

                    try {
                      Map<String, dynamic> resultResponse = {
                        "qualification": rating,
                      };

                      await serviceController.updateCalification(
                        conv.id,
                        resultResponse,
                      );

                      await repository.updateLocalConversationQualification(
                        conv.id,
                        rating,
                      );

                      if (!mounted) return;

                      Navigator.pop(dialogContext);

                      _loadConversations();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "⭐ Valoración actualizada",
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

                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Error al valorar la conversación",
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
                  },
                  child: Text(
                    "Guardar",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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
      ),
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F1115)
            : const Color(0xFFF6F8FB),
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
                            const Color(0xFFF6F8FB),
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
              top: 220,
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
                    child: FutureBuilder<List<Conversation>>(
                      future: resultados,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF171C24)
                                    : Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const CircularProgressIndicator(),
                            ),
                          );
                        } else if (snapshot.hasError) {
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
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.black.withOpacity(0.04),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.wifi_off_rounded,
                                      color: Colors.redAccent,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      "No se pudo cargar las conversaciones",
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
                                      "Verifica tu conexión e inténtalo nuevamente.",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        height: 1.5,
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
                        } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                          return _buildEmptyState(isDark);
                        }

                        final resultadosData = snapshot.data!;
                        return ListView.builder(
                          physics: const ClampingScrollPhysics(),
                          itemCount: resultadosData.length + 1,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                          itemBuilder: (context, index) {
                            if (index == resultadosData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _buildIntroCard(
                                  isDark,
                                  resultadosData.length,
                                ),
                              );
                            }
                            // Para todos los demás índices, mostramos la conversación (empezando desde el index 0)
                            final conv = resultadosData[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildConversationCard(conv, isDark),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.secundary.withOpacity(0.28),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: FloatingActionButton(
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
                : const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationCard(Conversation conv, bool isDark) {
    final dateText = conv.fechaInicio != null
        ? DateFormat("yyyy-MM-dd HH:mm").format(conv.fechaInicio!)
        : "Sin fecha";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(conv.openaiId ?? ".", conv.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
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
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secundary],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conv.nameConversation ?? "Sin nombre",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "📅 $dateText",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Icon(
                            i < (conv.qualification ?? 0)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: Colors.amber,
                            size: 18,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: isDark ? const Color(0xFF1F232B) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : Colors.black54,
                ),
                onSelected: (value) {
                  if (value == "rename") _renombrarChat(conv);
                  if (value == "rate") _valorarChat(conv);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: "rename",
                    child: Text(
                      "Renombrar",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                  ),
                  PopupMenuItem(
                    value: "rate",
                    child: Text(
                      "Valorar",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
                  Icons.forum_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "No hay conversaciones aún",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF18202A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Crea tu primera conversación para empezar a hablar con SeaBot.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isCreating ? null : _nuevoChat,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  "Nueva conversación",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secundary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(bool isDark, int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C24)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
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
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secundary],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Has usado $total de 3 conversaciones ${total == 1 ? 'disponible' : 'disponibles'}.",
              style: GoogleFonts.manrope(
                fontSize: 13.8,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
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
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Mis conversaciones",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Accede y organiza tus chats con SeaBot",
                      style: GoogleFonts.manrope(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 13.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
