import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/screens/widgets/seabot_widgets.dart';
import 'package:seabot/services/phq_result_service.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:seabot/core/responsive_helper.dart';

class TestPHQ9Screen extends StatefulWidget {
  const TestPHQ9Screen({super.key});

  @override
  State<TestPHQ9Screen> createState() => _TestPHQ9ScreenState();
}

class _TestPHQ9ScreenState extends State<TestPHQ9Screen> {
  bool _showIntro = true;
  int currentQuestion = 0;
  Map<int, int> respuestas = {};
  final PhqResultService service = PhqResultService();
  int studentID = AppData.studentID;
  bool isSubmitting = false;

  final List<String> preguntas = [
    "1. Poco interés o placer en hacer cosas",
    "2. Sentirse triste, deprimido o sin esperanza",
    "3. Dificultad para conciliar el sueño, mantenerse dormido o dormir demasiado",
    "4. Sentirse cansado o con poca energía",
    "5. Falta de apetito o comer en exceso",
    "6. Sentirse mal consigo mismo, o pensar que uno es un fracaso o que ha decepcionado a sí mismo o a su familia",
    "7. Dificultad para concentrarse en cosas como leer o ver televisión",
    "8. Moverse o hablar tan despacio que otros lo notan, o estar tan inquieto o nervioso que te has estado moviendo mucho más de lo habitual",
    "9. Pensamientos de que estarías mejor muerto o de hacerte daño de alguna manera",
  ];

  final List<String> opciones = [
    "0 - Nunca",
    "1 - Algunos días",
    "2 - Más de la mitad de los días",
    "3 - Casi todos los días",
  ];

  @override
  void initState() {
    super.initState();
    _verificarTestHoy();
  }

  Future<void> _verificarTestHoy() async {
    final online = await _hasInternet();

    if (!online) {
      return; // deja entrar a la pantalla intro, pero luego "Iniciar test" validará conexión
    }

    try {
      bool hecho = await service.hasTakenRecently(studentID);

      if (hecho && mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              "Aviso importante",
              style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
            ),
            content: Text(
              "Ya realizaste el test PHQ-9 en los últimos 14 días. Intenta nuevamente cuando se cumplan dos semanas.",
              style: GoogleFonts.manrope(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Entendido",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );

        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error verificando test de hoy: $e");
    }
  }

  Future<bool> _onWillPop() async {
    if (!_showIntro &&
        respuestas.isNotEmpty &&
        respuestas.length < preguntas.length) {
      bool salir = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            "¿Deseas salir del test?",
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: Text(
            "Perderás tu progreso si sales ahora.",
            style: GoogleFonts.manrope(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancelar",
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                "Salir",
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
      return salir == true;
    }
    return true;
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();

    if (result.contains(ConnectivityResult.none)) {
      return false;
    }

    try {
      final lookup = await InternetAddress.lookup(
        'seabot-backend-993787742289.us-central1.run.app',
      ).timeout(const Duration(seconds: 3));

      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _nextQuestion() {
    if (respuestas[currentQuestion] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Por favor selecciona una respuesta antes de continuar.",
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
    if (currentQuestion < preguntas.length - 1) {
      setState(() => currentQuestion++);
    }
  }

  void _prevQuestion() {
    if (currentQuestion > 0) {
      setState(() => currentQuestion--);
    }
  }

  Future<void> _finalizarTest() async {
    if (isSubmitting) return;

    if (respuestas.length < preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Responde todas las preguntas antes de finalizar.",
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

    setState(() => isSubmitting = true);

    try {
      int total = respuestas.values.reduce((a, b) => a + b);
      String interpretacion = _interpretarPuntaje(total);
      final fecha = DateFormat("yyyy-MM-dd").format(DateTime.now());

      await service.createResult({
        "total_score": total,
        "interpretation": interpretacion,
        "fecha": fecha,
        "student_id": studentID,
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Resultado del Test PHQ-9",
            style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Puntaje total: $total",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Interpretación: $interpretacion",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Home()),
                    (route) => false,
                  );
                },
                child: Text(
                  "Cerrar",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  String _interpretarPuntaje(int score) {
    if (score <= 4) return "Ninguna depresión";
    if (score <= 9) return "Depresión leve";
    if (score <= 14) return "Depresión moderada";
    if (score <= 19) return "Depresión moderadamente severa";
    return "Depresión severa";
  }

  double get _progressValue => (currentQuestion + 1) / preguntas.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
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
                    child: ResponsiveHelper.centeredConstraint(
                      context: context,
                      maxTabletWidth: 600,
                      child: _showIntro
                          ? _buildIntroScreen(context, isDark)
                          : _buildTestScreen(context, isDark),
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
      child: ResponsiveHelper.centeredConstraint(
        context: context,
        maxTabletWidth: 600,
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
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final canLeave = await _onWillPop();
                    if (canLeave && mounted) Navigator.pop(context);
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
                      "Test PHQ-9",
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
                      _showIntro
                          ? "Evaluación breve de bienestar emocional"
                          : "Pregunta ${currentQuestion + 1} de ${preguntas.length}",
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
      ),
    );
  }

  Widget _buildIntroScreen(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
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
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secundary],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.20),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  "Test de Salud Mental PHQ-9",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.secundaryStart,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  "Este test evalúa la presencia y severidad de síntomas depresivos en las últimas dos semanas. No es un diagnóstico médico, pero puede orientarte sobre si sería útil buscar apoyo profesional.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Te tomará solo unos minutos y tus respuestas deben reflejar cómo te has sentido recientemente.",
                          style: GoogleFonts.manrope(
                            fontSize: 13.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDarkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SeaBotSecondaryButton(
                  label: "¿Qué es el test PHQ-9?",
                  icon: Icons.info_outline_rounded,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        title: Text(
                          "¿Qué es el PHQ-9?",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        content: Text(
                          "El PHQ-9 (Patient Health Questionnaire-9) es un cuestionario clínicamente validado utilizado para evaluar síntomas depresivos durante las últimas dos semanas. Sus resultados sirven como orientación inicial.",
                          style: GoogleFonts.manrope(height: 1.55),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Entendido",
                              style: GoogleFonts.manrope(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                SeaBotPrimaryButton(
                  label: "Iniciar test",
                  icon: Icons.play_arrow_rounded,
                  onPressed: () async {
                    final online = await _hasInternet();

                    if (!online) {
                      if (!mounted) return;

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

                    if (!mounted) return;
                    setState(() => _showIntro = false);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestScreen(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        children: [
          Container(
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
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "Progreso",
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF18202A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${currentQuestion + 1}/${preguntas.length}",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: _progressValue,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secundaryStart,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
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
              children: [
                Text(
                  "Durante las últimas dos semanas, ¿con qué frecuencia te han molestado los siguientes problemas?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  preguntas[currentQuestion],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 19,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 22),
                ...List.generate(opciones.length, (i) {
                  final isSelected = respuestas[currentQuestion] == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            respuestas[currentQuestion] = i;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secundaryStart.withOpacity(0.12)
                                : (isDark
                                      ? Colors.white.withOpacity(0.04)
                                      : const Color(0xFFF7F9FC)),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secundaryStart
                                  : (isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : Colors.black.withOpacity(0.05)),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.secundaryStart
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.secundaryStart
                                        : (isDark
                                              ? Colors.white54
                                              : Colors.black38),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opciones[i],
                                  style: GoogleFonts.manrope(
                                    fontSize: 14.3,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF18202A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (currentQuestion > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevQuestion,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.35),
                      ),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Anterior",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              if (currentQuestion > 0) const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : (currentQuestion < preguntas.length - 1
                            ? _nextQuestion
                            : _finalizarTest),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secundaryStart,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          currentQuestion < preguntas.length - 1
                              ? "Siguiente"
                              : "Finalizar test",
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
