import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/screens/bienvenida_screen.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/services/user_service.dart';
import 'package:seabot/main.dart';

class InicioAppScreen extends StatefulWidget {
  const InicioAppScreen({super.key});

  @override
  State<InicioAppScreen> createState() => _InicioAppScreenState();
}

class _InicioAppScreenState extends State<InicioAppScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late final AnimationController _breathController;
  late final Animation<double> _breathScale;

  late final AnimationController _textFadeController;
  late final Animation<double> _textFade;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _loaderController;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathScale = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _textFade = Tween<double>(begin: 0.65, end: 1).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _loaderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  /*
  Future<void> _checkSessionBefore() async {
    final token = await _authService.getToken();
    final studentIdStr = await storage.read(key: "student_id");
    final userIdStr = await storage.read(key: "user_id");

    debugPrint("TOKEN: $token");
    debugPrint("STUDENT_ID: $studentIdStr");
    debugPrint("USER_ID: $userIdStr");

    final studentId = int.tryParse(studentIdStr ?? "") ?? 0;
    final userId = int.tryParse(userIdStr ?? "") ?? 0;

    // 🔥 Si no hay sesión válida, limpiar y mandar al inicio/login
    if (token == null || token.isEmpty || studentId <= 0 || userId <= 0) {
      await storage.delete(key: "auth_token");
      await storage.delete(key: "student_id");
      await storage.delete(key: "user_id");

      AppData.token = "";
      AppData.studentID = 0;
      AppData.userID = 0;

      await Future.delayed(const Duration(milliseconds: 1800));

      if (!mounted) return;
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
      return;
    }

    // ✅ Sesión válida localmente
    AppData.token = token;
    AppData.studentID = studentId;
    AppData.userID = userId;

    await Future.delayed(const Duration(milliseconds: 1300));

    if (!mounted) return;
    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

*/

  Future<void> _checkSession() async {
    final token = await _authService.getToken();
    final studentIdStr = await storage.read(key: "student_id");
    final userIdStr = await storage.read(key: "user_id");
    final expiresAtStr = await storage.read(key: "auth_token_expires_at");

    debugPrint("TOKEN: $token");
    debugPrint("STUDENT_ID: $studentIdStr");
    debugPrint("USER_ID: $userIdStr");
    debugPrint("EXPIRES_AT: $expiresAtStr");

    final studentId = int.tryParse(studentIdStr ?? "") ?? 0;
    final userId = int.tryParse(userIdStr ?? "") ?? 0;

    final hasSessionData =
        token != null &&
        token.isNotEmpty &&
        studentId > 0 &&
        userId > 0 &&
        expiresAtStr != null &&
        expiresAtStr.isNotEmpty;

    // Si no existe sesión guardada completa
    if (!hasSessionData) {
      await _clearSessionAndGoToWelcome();
      return;
    }

    final expiresAt = DateTime.tryParse(expiresAtStr);

    // Si la fecha de expiración no existe o tiene formato inválido
    if (expiresAt == null) {
      await _clearSessionAndGoToWelcome();
      return;
    }

    debugPrint("NOW: ${DateTime.now()}");
    debugPrint("EXPIRES_AT_PARSED: $expiresAt");
    debugPrint("IS_EXPIRED: ${DateTime.now().isAfter(expiresAt)}");

    // Si el token ya expiró
    if (DateTime.now().isAfter(expiresAt)) {
      debugPrint("TOKEN EXPIRADO");

      await _clearSessionAndGoToWelcome();
      return;
    }

    // Token válido: recuperar sesión automáticamente
    debugPrint("TOKEN VÁLIDO");

    AppData.token = token;
    AppData.studentID = studentId;
    AppData.userID = userId;

    await Future.delayed(const Duration(milliseconds: 1300));

    if (!mounted) return;

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
    );
  }

  Future<void> _clearSessionAndGoToWelcome() async {
    await storage.delete(key: "auth_token");
    await storage.delete(key: "auth_token_expires_at");
    await storage.delete(key: "student_id");
    await storage.delete(key: "user_id");
    await storage.delete(key: "role");

    AppData.token = "";
    AppData.studentID = 0;
    AppData.userID = 0;
    AppData.role = "";

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    navigatorKey.currentState?.pushReplacement(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    _textFadeController.dispose();
    _floatController.dispose();
    _loaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secundary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const _BackgroundBlobs(),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _breathController,
                      _textFadeController,
                      _floatController,
                    ]),
                    builder: (context, _) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: _breathScale,
                              child: _BreathingGlassOrb(),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              "SeaBot",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeTransition(
                              opacity: _textFade,
                              child: Column(
                                children: [
                                  Text(
                                    "Respira hondo…",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Estás en un lugar seguro.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.88),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            _PremiumLoader(controller: _loaderController),
                            const SizedBox(height: 16),
                            Text(
                              "Sincronizando tu bienestar...",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.92),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingGlassOrb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.12),
                  blurRadius: 45,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: const Color(0xFF49C9B0).withOpacity(0.18),
                  blurRadius: 70,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 142,
                height: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.22),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.26),
                      Colors.white.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.95),
                          Colors.white.withOpacity(0.72),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 34,
                      color: const Color(0xFF49C9B0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumLoader extends StatelessWidget {
  final AnimationController controller;

  const _PremiumLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final progress = controller.value;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = ((progress - delay) % 1.0).clamp(0.0, 1.0);
              final opacity = 0.35 + (0.65 * (1 - (value - 0.5).abs() * 2));
              final scale = 0.8 + (0.35 * (1 - (value - 0.5).abs() * 2));

              return Transform.scale(
                scale: scale.clamp(0.8, 1.15),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(opacity.clamp(0.35, 1.0)),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _BackgroundBlobs extends StatelessWidget {
  const _BackgroundBlobs();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -50,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
        ),
        Positioned(
          right: -70,
          top: 100,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: 30,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
      ],
    );
  }
}
