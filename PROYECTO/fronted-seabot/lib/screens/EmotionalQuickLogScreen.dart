import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/core/responsive_helper.dart';
import 'package:seabot/models/emotional_register.dart';
import 'package:seabot/repositories/emotional_registers_repository.dart';
import 'package:seabot/services/emotional_register_service.dart';

class EmotionalQuickLogScreen extends StatefulWidget {
  const EmotionalQuickLogScreen({super.key});

  @override
  State<EmotionalQuickLogScreen> createState() =>
      _EmotionalQuickLogScreenState();
}

class _EmotionalQuickLogScreenState extends State<EmotionalQuickLogScreen> {
  int studentID = AppData.studentID;
  final EmotionalRegisterService serviceController = EmotionalRegisterService();
  late Future<List<EmotionalRegister>> resultados;
  final EmotionsRepository repository = EmotionsRepository();

  String? _selectedEmotion;
  bool _isRegistering = false;

  //bool _isHistoryLoading = false;

  final List<Map<String, String>> _emotions = const [
    {"emoji": "😀", "label": "Alegría"},
    {"emoji": "😢", "label": "Tristeza"},
    {"emoji": "😡", "label": "Ira"},
    {"emoji": "😨", "label": "Miedo"},
  ];

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    bool online = await _hasInternet();
    if (!mounted) return;
    setState(() {
      resultados = repository.fetchAndSyncEmotion(studentID, online);
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

  Future<void> _onEmotionPressed(String emoji, String label) async {
    if (_isRegistering) return;

    setState(() {
      _selectedEmotion = label;
    });

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

    await _registrarEmocion(emoji, label);
  }

  String _getEmojiForEmotion(String? emotion) {
    switch (emotion) {
      case "Alegría":
        return "😀";
      case "Tristeza":
        return "😢";
      case "Ira":
        return "😡";
      case "Miedo":
        return "😨";
      default:
        return "🙂";
    }
  }

  Future<void> _registrarEmocion(String emoji, String label) async {
    if (_isRegistering) return;

    setState(() => _isRegistering = true);

    try {
      bool hecho = await serviceController.hasTakenToday(studentID);
      if (hecho) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1F232B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                "Aviso importante",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: Text(
                "Ya realizaste el registro emocional rápido hoy.\nIntenta nuevamente mañana.",
                style: GoogleFonts.manrope(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Entendido",
                    style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return;
      }

      final ahora = DateTime.now().toUtc();
      final resultResponse = {
        "emotion": label,
        "fecha_hora": ahora.toIso8601String(),
        "student_id": studentID,
      };

      await serviceController.createRegister(resultResponse);

      final data = await serviceController.getLast8ByStudent(studentID);

      if (!mounted) return;
      setState(() {
        resultados = Future.value(data);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Estado registrado: $label $emoji",
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
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Widget _buildEmotionButton(String emoji, String label, bool isDark) {
    final isSelected = _selectedEmotion == label;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _onEmotionPressed(emoji, label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.secundaryStart.withOpacity(0.12)
                : (isDark
                      ? const Color(0xFF171C24)
                      : Colors.white.withOpacity(0.95)),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? AppColors.secundaryStart
                  : (isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.secundary.withOpacity(0.18)
                      : AppColors.secundary.withOpacity(0.12),
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF18202A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(dynamic fechaHora) {
    final value = fechaHora?.toString() ?? "";
    if (value.isEmpty) return "Sin fecha";
    return value;
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
                  _buildHeaderPremium(
                    title: "Registro Emocional Rápido",
                    subtitle: "Registra cómo te sientes en este momento",
                  ),
                  Expanded(
                    child: ResponsiveHelper.centeredConstraint(
                      context: context,
                      maxTabletWidth: 600,
                      child: Column(
                        children: [
                        Expanded(
                          flex: 4,
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                            child: Column(
                              children: [
                                _buildIntroCard(isDark),
                                const SizedBox(height: 18),
                                Text(
                                  "¿Cómo te sientes ahora?",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF18202A),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Selecciona la emoción que mejor describa tu estado actual.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.2,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: _emotions.map((emotion) {
                                    return _buildEmotionButton(
                                      emotion["emoji"]!,
                                      emotion["label"]!,
                                      isDark,
                                    );
                                  }).toList(),
                                ),
                                if (_isRegistering) ...[
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.secundaryStart,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Registrando emoción...",
                                        style: GoogleFonts.manrope(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                          child: _buildHistoryLauncher(isDark),
                        ),
                        //Expanded(
                        //  flex: 5,
                        //  child: Container(
                        //    width: double.infinity,
                        //    margin: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                        //    decoration: BoxDecoration(
                        //      color: isDark
                        //          ? const Color(0xFF171C24)
                        //          : Colors.white.withOpacity(0.95),
                        //      borderRadius: BorderRadius.circular(28),
                        //      border: Border.all(
                        //        color: isDark
                        //            ? Colors.white.withOpacity(0.04)
                        //            : Colors.black.withOpacity(0.04),
                        //      ),
                        //      boxShadow: [
                        //        BoxShadow(
                        //          color: Colors.black.withOpacity(
                        //            isDark ? 0.20 : 0.06,
                        //          ),
                        //          blurRadius: 22,
                        //          offset: const Offset(0, 12),
                        //        ),
                        //      ],
                        //    ),
                        //    child: Column(
                        //      children: [
                        //        Padding(
                        //          padding: const EdgeInsets.fromLTRB(
                        //            18,
                        //            18,
                        //            18,
                        //            10,
                        //          ),
                        //          child: Row(
                        //            children: [
                        //              Text(
                        //                "Historial reciente",
                        //                style: GoogleFonts.manrope(
                        //                  fontSize: 16.5,
                        //                  fontWeight: FontWeight.w800,
                        //                  color: isDark
                        //                      ? Colors.white
                        //                      : const Color(0xFF18202A),
                        //                ),
                        //              ),
                        //              const Spacer(),
                        //              Icon(
                        //                Icons.history_rounded,
                        //                color: isDark
                        //                    ? Colors.white54
                        //                    : Colors.black45,
                        //              ),
                        //            ],
                        //          ),
                        //        ),
                        //        Divider(
                        //          height: 1,
                        //          color: isDark
                        //              ? Colors.white.withOpacity(0.06)
                        //              : Colors.black.withOpacity(0.06),
                        //        ),
                        //        Expanded(
                        //          child: FutureBuilder<List<EmotionalRegister>>(
                        //            future: resultados,
                        //            builder: (context, snapshot) {
                        //              if (snapshot.connectionState ==
                        //                  ConnectionState.waiting) {
                        //                return const Center(
                        //                  child: CircularProgressIndicator(),
                        //                );
                        //              } else if (snapshot.hasError) {
                        //                return Center(
                        //                  child: Padding(
                        //                    padding: const EdgeInsets.symmetric(
                        //                      horizontal: 20,
                        //                    ),
                        //                    child: Text(
                        //                      "Error: ${snapshot.error}",
                        //                      textAlign: TextAlign.center,
                        //                      style: GoogleFonts.manrope(
                        //                        color: Colors.redAccent,
                        //                        fontWeight: FontWeight.w600,
                        //                      ),
                        //                    ),
                        //                  ),
                        //                );
                        //              } else if (!snapshot.hasData ||
                        //                  snapshot.data!.isEmpty) {
                        //                return Center(
                        //                  child: Padding(
                        //                    padding: const EdgeInsets.symmetric(
                        //                      horizontal: 24,
                        //                    ),
                        //                    child: Column(
                        //                      mainAxisSize: MainAxisSize.min,
                        //                      children: [
                        //                        Container(
                        //                          width: 68,
                        //                          height: 68,
                        //                          decoration: BoxDecoration(
                        //                            color: AppColors.primary
                        //                                .withOpacity(0.12),
                        //                            shape: BoxShape.circle,
                        //                          ),
                        //                          child: const Icon(
                        //                            Icons.mood_rounded,
                        //                            color: AppColors.primary,
                        //                            size: 34,
                        //                          ),
                        //                        ),
                        //                        const SizedBox(height: 16),
                        //                        Text(
                        //                          "No hay registros emocionales aún",
                        //                          textAlign: TextAlign.center,
                        //                          style: GoogleFonts.manrope(
                        //                            fontSize: 17,
                        //                            fontWeight: FontWeight.w800,
                        //                            color: isDark
                        //                                ? Colors.white
                        //                                : const Color(
                        //                                    0xFF18202A,
                        //                                  ),
                        //                          ),
                        //                        ),
                        //                        const SizedBox(height: 8),
                        //                        Text(
                        //                          "Realiza tu primer registro para empezar a ver tu historial 💭",
                        //                          textAlign: TextAlign.center,
                        //                          style: GoogleFonts.manrope(
                        //                            fontSize: 14,
                        //                            height: 1.5,
                        //                            color: isDark
                        //                                ? Colors.white70
                        //                                : Colors.black54,
                        //                          ),
                        //                        ),
                        //                      ],
                        //                    ),
                        //                  ),
                        //                );
                        //              }
                        //
                        //              final resultadosData = snapshot.data!;
                        //              return ListView.builder(
                        //                physics:
                        //                    const BouncingScrollPhysics(),
                        //                padding: const EdgeInsets.all(14),
                        //                itemCount: resultadosData.length,
                        //                itemBuilder: (context, index) {
                        //                  final r = resultadosData[index];
                        //                  return Container(
                        //                    margin: const EdgeInsets.only(
                        //                      bottom: 12,
                        //                    ),
                        //                    padding: const EdgeInsets.all(14),
                        //                    decoration: BoxDecoration(
                        //                      color: isDark
                        //                          ? Colors.white.withOpacity(
                        //                              0.04,
                        //                            )
                        //                          : const Color(0xFFF7F9FC),
                        //                      borderRadius:
                        //                          BorderRadius.circular(20),
                        //                      border: Border.all(
                        //                        color: isDark
                        //                            ? Colors.white.withOpacity(
                        //                                0.05,
                        //                              )
                        //                            : Colors.black.withOpacity(
                        //                                0.04,
                        //                              ),
                        //                      ),
                        //                    ),
                        //                    child: Row(
                        //                      children: [
                        //                        Container(
                        //                          width: 52,
                        //                          height: 52,
                        //                          decoration: BoxDecoration(
                        //                            color: AppColors.secundary
                        //                                .withOpacity(0.12),
                        //                            shape: BoxShape.circle,
                        //                          ),
                        //                          child: Center(
                        //                            child: Text(
                        //                              _getEmojiForEmotion(
                        //                                r.emotion,
                        //                              ),
                        //                              style: const TextStyle(
                        //                                fontSize: 28,
                        //                              ),
                        //                            ),
                        //                          ),
                        //                        ),
                        //                        const SizedBox(width: 12),
                        //                        Expanded(
                        //                          child: Column(
                        //                            crossAxisAlignment:
                        //                                CrossAxisAlignment
                        //                                    .start,
                        //                            children: [
                        //                              Text(
                        //                                r.emotion ?? "",
                        //                                style:
                        //                                    GoogleFonts.manrope(
                        //                                  color: isDark
                        //                                      ? Colors.white
                        //                                      : Colors.black87,
                        //                                  fontWeight:
                        //                                      FontWeight.w800,
                        //                                  fontSize: 15,
                        //                                ),
                        //                              ),
                        //                              const SizedBox(height: 5),
                        //                              Text(
                        //                                "📅 ${_formatFecha(r.fechaHora)}",
                        //                                style:
                        //                                    GoogleFonts.manrope(
                        //                                  fontSize: 13,
                        //                                  color: isDark
                        //                                      ? Colors.white60
                        //                                      : Colors.black54,
                        //                                  fontWeight:
                        //                                      FontWeight.w500,
                        //                                ),
                        //                              ),
                        //                            ],
                        //                          ),
                        //                        ),
                        //                      ],
                        //                    ),
                        //                  );
                        //                },
                        //              );
                        //            },
                        //          ),
                        //        ),
                        //      ],
                        //    ),
                        //  ),
                        //),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildHistoryLauncher(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: _openHistoryBottomSheet,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secundary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Historial reciente",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF18202A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Toca para ver tus últimos registros emocionales",
                      style: GoogleFonts.manrope(
                        fontSize: 13.2,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF3F6FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHistoryBottomSheet() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.58,
          minChildSize: 0.38,
          maxChildSize: 0.88,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171C24)
                    : const Color(0xFFFDFEFE),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 52,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.18)
                          : Colors.black.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secundary],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Historial reciente",
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF18202A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Tus últimos estados emocionales registrados",
                                style: GoogleFonts.manrope(
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                  Expanded(
                    child: FutureBuilder<List<EmotionalRegister>>(
                      future: resultados,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                "Error: ${snapshot.error}",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(
                                        0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mood_rounded,
                                      color: AppColors.primary,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No hay registros emocionales aún",
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
                                    "Realiza tu primer registro para empezar a ver tu historial 💭",
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
                          );
                        }

                        final resultadosData = snapshot.data!;

                        return ListView.builder(
                          controller: scrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: resultadosData.length,
                          itemBuilder: (context, index) {
                            final r = resultadosData[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : const Color(0xFFF7F9FC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black.withOpacity(0.04),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: AppColors.secundary.withOpacity(
                                        0.12,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getEmojiForEmotion(r.emotion),
                                        style: const TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r.emotion ?? "",
                                          style: GoogleFonts.manrope(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          "📅 ${_formatFecha(r.fechaHora)}",
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white60
                                                : Colors.black54,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderPremium({
    required String title,
    String? subtitle,
    Future<bool> Function()? onWillPopCustom,
  }) {
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
      child: ResponsiveHelper.centeredConstraint(
        context: context,
        maxTabletWidth: 600,
        child: Stack(
          children: [
          // 🔹 decoración
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

          // 🔹 contenido
          Row(
            children: [
              // 🔥 BOTÓN BACK REUTILIZABLE
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    if (onWillPopCustom != null) {
                      final canLeave = await onWillPopCustom();
                      if (canLeave && mounted) Navigator.pop(context);
                    } else {
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildIntroCard(bool isDark) {
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
              Icons.favorite_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Este registro te ayuda a reconocer tu estado emocional del día.",
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
}
