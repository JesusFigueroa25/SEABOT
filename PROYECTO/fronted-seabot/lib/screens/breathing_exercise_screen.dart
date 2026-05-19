import 'dart:async';
import 'dart:ui';
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
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 19),
    );

    _circleAnimation = Tween<double>(
      begin: 0.72,
      end: 1.02,
    ).animate(
      CurvedAnimation(
        parent: _circleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startBreathing() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _phaseText = "Inhala durante 4 segundos...";
    });

    _circleController.repeat(reverse: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed++;

      setState(() {
        if (_elapsed < 4) {
          _phaseText = "Inhala durante 4 segundos...";
        } else if (_elapsed < 11) {
          _phaseText = "Mantén el aire 7 segundos...";
        } else if (_elapsed < 19) {
          _phaseText = "Exhala lentamente 8 segundos...";
        }

        if (_elapsed >= 19) {
          _elapsed = 0;
          _cycleCount++;
          _phaseText = "Inhala durante 4 segundos...";
        }
      });
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
      _elapsed = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _circleController.dispose();
    super.dispose();
  }

  String _getMiniPhaseLabel() {
    if (!_isRunning) return "Listo";
    if (_elapsed < 4) return "Inhala";
    if (_elapsed < 11) return "Mantén";
    return "Exhala";
  }

  double _getProgressValue() {
    if (!_isRunning) return 0;
    return (_elapsed / 19).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final circleSize = (screenWidth * 0.58).clamp(180.0, 270.0);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F1115) : const Color(0xFFF6F8FB),
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
              top: 240,
              left: -80,
              child: _buildBlurOrb(
                size: 190,
                color: AppColors.secundary.withOpacity(isDark ? 0.10 : 0.12),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      child: Column(
                        children: [
                          _buildIntroCard(isDark),
                          const SizedBox(height: 22),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF171C24)
                                  : Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : Colors.black.withOpacity(0.04),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.20 : 0.06,
                                  ),
                                  blurRadius: 22,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                AnimatedBuilder(
                                  animation: _circleAnimation,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isRunning
                                          ? _circleAnimation.value
                                          : 1.0,
                                      child: Container(
                                        width: circleSize,
                                        height: circleSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              AppColors.primary.withOpacity(
                                                isDark ? 0.70 : 0.65,
                                              ),
                                              AppColors.secundary.withOpacity(
                                                isDark ? 0.95 : 0.92,
                                              ),
                                            ],
                                            center: Alignment.center,
                                            radius: 0.88,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withOpacity(0.22),
                                              blurRadius: 30,
                                              spreadRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SizedBox(
                                              width: circleSize - 18,
                                              height: circleSize - 18,
                                              child: CircularProgressIndicator(
                                                value: _getProgressValue(),
                                                strokeWidth: 5,
                                                backgroundColor: Colors.white
                                                    .withOpacity(0.16),
                                                valueColor:
                                                    const AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _isRunning ? _getMiniPhaseLabel() : "Respira",
                                                  style: GoogleFonts.manrope(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  _isRunning ? "" : "🫁",
                                                  style: const TextStyle(
                                                    fontSize: 48,
                                                  ),
                                                ),
                                                if (_isRunning) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    "${19 - _elapsed}s",
                                                    style: GoogleFonts.manrope(
                                                      color: Colors.white
                                                          .withOpacity(0.95),
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 26),
                                Text(
                                  _phaseText,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.primaryDarkText,
                                    fontSize: screenWidth < 400 ? 14.5 : 16.5,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : const Color(0xFFF7F9FC),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.refresh_rounded,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Ciclos completados: $_cycleCount",
                                        style: GoogleFonts.manrope(
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize:
                                              screenWidth < 400 ? 13 : 14.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  label: "Iniciar",
                                  icon: Icons.play_arrow_rounded,
                                  color: AppColors.secundary,
                                  onPressed: _isRunning ? null : _startBreathing,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  label: "Detener",
                                  icon: Icons.pause_rounded,
                                  color: Colors.orangeAccent,
                                  onPressed: _isRunning ? _stopBreathing : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              label: "Reiniciar",
                              icon: Icons.refresh_rounded,
                              color: Colors.redAccent,
                              onPressed: _resetBreathing,
                            ),
                          ),

                          const SizedBox(height: 20),

                          _buildTipsCard(isDark),
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
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
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
                  border: Border.all(
                    color: Colors.white.withOpacity(0.24),
                  ),
                ),
                child: const Icon(
                  Icons.air_rounded,
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
                      "Respiración 4-7-8",
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
                      "Calma tu mente con una pausa guiada",
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
              Icons.self_improvement_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "Sigue el ritmo de inhalar, mantener y exhalar para reducir la tensión y recuperar calma.",
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

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(
        label,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: color.withOpacity(0.35),
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildTipsCard(bool isDark) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sugerencias",
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF18202A),
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem("Inhala por la nariz durante 4 segundos."),
          _buildTipItem("Mantén el aire suavemente por 7 segundos."),
          _buildTipItem("Exhala lento por la boca durante 8 segundos."),
          _buildTipItem("Repite varios ciclos hasta sentir más calma."),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: AppColors.secundary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 13.7,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}