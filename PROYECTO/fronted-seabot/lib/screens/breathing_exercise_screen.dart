import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';

class BreathingExerciseScreen extends StatefulWidget {
  const BreathingExerciseScreen({super.key});

  @override
  State<BreathingExerciseScreen> createState() =>
      _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  Timer? _timer;
  String _phaseText = "Presiona Iniciar para comenzar";
  int _cycleCount = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19), // 4 + 7 + 8 = 19
    );
    _circleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );
  }

  void _startBreathing() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
      _phaseText = "Inhala durante 4 segundos...";
    });

    _circleController.forward(from: 0);
    int elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsed++;
      setState(() {
        if (elapsed == 4) _phaseText = "Mantén el aire 7 segundos...";
        if (elapsed == 11) _phaseText = "Exhala lentamente 8 segundos...";
      });
      if (elapsed >= 19) {
        elapsed = 0;
        _cycleCount++;
        _phaseText = "Inhala durante 4 segundos...";
      }
    });
  }

  void _stopBreathing() {
    _timer?.cancel();
    _circleController.stop();
    setState(() {
      _isRunning = false;
      _phaseText = "Ejercicio detenido. Respira naturalmente.";
    });
  }

  void _resetBreathing() {
    _timer?.cancel();
    _circleController.reset();
    setState(() {
      _isRunning = false;
      _phaseText = "Presiona Iniciar para comenzar";
      _cycleCount = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Theme(
      // 🔹 Aplica fuente Manrope a toda la pantalla
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
        appBarTheme: theme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Ejercicio de Respiración 4-7-8"),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _circleAnimation,
                    builder: (context, child) {
                      double size = MediaQuery.of(context).size.width * 0.6;
                      return Transform.scale(
                        scale: _circleAnimation.value,
                        child: Container(
                          width: size.clamp(140, 240),
                          height: size.clamp(140, 240),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.secundary.withOpacity(0.9),
                              ],
                              center: Alignment.center,
                              radius: 0.85,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _isRunning ? "" : "🫁",
                            style: const TextStyle(fontSize: 50),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 35),
                  Text(
                    _phaseText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.bold,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : AppColors.primary,
                      fontSize: MediaQuery.of(context).size.width < 400 ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Ciclos completados: $_cycleCount",
                    style: GoogleFonts.manrope(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white70
                          : Colors.grey[700],
                      fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 15,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Wrap(
                    spacing: 15,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _startBreathing,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text("Iniciar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secundary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _stopBreathing : null,
                        icon: const Icon(Icons.pause),
                        label: const Text("Detener"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _resetBreathing,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Reiniciar"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
