import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/services/phq_result_service.dart';

class TestPHQ9Screen extends StatefulWidget {
  const TestPHQ9Screen({super.key});

  @override
  State<TestPHQ9Screen> createState() => _TestPHQ9ScreenState();
}

class _TestPHQ9ScreenState extends State<TestPHQ9Screen> {
  bool _showIntro = true; // 🌿 Nueva bandera para pantalla inicial
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
    "1 - Algunos días", // ✅ corregido
    "2 - Más de la mitad de los días",
    "3 - Casi todos los días",
  ];

  @override
  void initState() {
    super.initState();
    _verificarTestHoy();
  }

  Future<void> _verificarTestHoy() async {
    bool hecho = await service.hasTakenToday(studentID);
    if (hecho && mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Aviso importante"),
          content: const Text(
            "Ya realizaste el test PHQ-9 hoy. Intenta nuevamente mañana.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Entendido"),
            ),
          ],
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_showIntro &&
        respuestas.isNotEmpty &&
        respuestas.length < preguntas.length) {
      bool salir = await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("¿Deseas salir del test?"),
          content: const Text("Perderás tu progreso si sales ahora."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Salir"),
            ),
          ],
        ),
      );
      return salir == true;
    }
    return true;
  }

  void _nextQuestion() {
    if (respuestas[currentQuestion] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor selecciona una respuesta antes de continuar.",
          ),
          backgroundColor: Colors.redAccent,
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
    if (isSubmitting) return; // 🚫 evita doble envío
    isSubmitting = true;

    if (respuestas.length < preguntas.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Responde todas las preguntas antes de finalizar."),
          backgroundColor: Colors.redAccent,
        ),
      );
      isSubmitting = false; // habilita otra vez
      return;
    }

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
      barrierDismissible: false, // 🚫 ya NO puede cerrar tocando afuera
      builder: (_) => AlertDialog(
        title: const Text("Resultado del Test PHQ-9"),
        content: Text("Puntaje total: $total\nInterpretación: $interpretacion"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Home()),
                (route) => false,
              );
            },
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  String _interpretarPuntaje(int score) {
    if (score <= 4) return "Ninguna depresión";
    if (score <= 9) return "Depresión leve";
    if (score <= 14) return "Depresión moderada";
    if (score <= 19) return "Depresión moderadamente severa";
    return "Depresión severa";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Test PHQ-9",
            style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          centerTitle: true,
        ),
        body: SafeArea(
          child: _showIntro
              ? _buildIntroScreen(context, theme)
              : _buildTestScreen(context, baseTextStyle, theme),
        ),
      ),
    );
  }

  // 🌿 Nueva pantalla introductoria
  Widget _buildIntroScreen(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.psychology_alt_rounded,
            color: AppColors.secundaryStart,
            size: 90,
          ),
          const SizedBox(height: 20),
          Text(
            "Test de Salud Mental PHQ-9",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.secundaryStart,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Este test evalúa la presencia y severidad de síntomas depresivos en la últimas dos semanas. No es un diagnóstico médico, pero puede ayudar a identificar si es recomendable buscar apoyo profesional.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("¿Qué es el PHQ-9?"),
                  content: const Text(
                    "El PHQ-9 (Patient Health Questionnaire-9) es un cuestionario clínicamente validado utilizado en todo el mundo para evaluar el estado de ánimo y los síntomas de depresión durante la últimas dos semanas. "
                    "Sus resultados sirven como orientación para determinar si una persona podría necesitar atención profesional.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Entendido"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.info_outline_rounded),
            label: const Text("¿Qué es el test PHQ-9?"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showIntro = false),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Iniciar test"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secundaryStart,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🌼 Pantalla de preguntas del test
  Widget _buildTestScreen(
    BuildContext context,
    TextTheme baseTextStyle,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Durante la últimas dos semanas, ¿con qué frecuencia te han molestado los siguientes problemas?",
            textAlign: TextAlign.center,
            style: baseTextStyle.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            preguntas[currentQuestion],
            style: baseTextStyle.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ...List.generate(opciones.length, (i) {
            return RadioListTile<int>(
              value: i,
              groupValue: respuestas[currentQuestion],
              onChanged: (val) {
                setState(() {
                  respuestas[currentQuestion] = val!;
                });
              },
              title: Text(opciones[i], style: baseTextStyle.bodyMedium),
              activeColor: AppColors.secundaryStart,
            );
          }),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentQuestion > 0)
                ElevatedButton(
                  onPressed: _prevQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Anterior"),
                ),
              if (currentQuestion < preguntas.length - 1)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundaryStart,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Siguiente"),
                ),
              if (currentQuestion == preguntas.length - 1)
                ElevatedButton(
                  onPressed: _finalizarTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundaryStart,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Finalizar test"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
