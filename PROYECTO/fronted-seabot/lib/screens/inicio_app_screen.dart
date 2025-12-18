import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/screens/bienvenida_screen.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/services/user_service.dart';
import 'package:seabot/main.dart'; // << importa el navigatorKey global

class InicioAppScreen extends StatefulWidget {
  const InicioAppScreen({super.key});

  @override
  State<InicioAppScreen> createState() => _InicioAppScreenState();
}

class _InicioAppScreenState extends State<InicioAppScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final storage = const FlutterSecureStorage();

  late AnimationController _circleController;
  late Animation<double> _circleAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  //final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 🔵 Animación de "respiración" del círculo
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _circleAnim = Tween<double>(begin: 0.9, end: 1.2).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.easeInOut),
    );

    // ✨ Animación de opacidad del texto
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnim = Tween<double>(begin: 0.5, end: 1).animate(_fadeController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final token = await _authService.getToken();
    final studentId = await storage.read(key: "student_id");
    final userId = await storage.read(key: "user_id");
    print("TOKEN: $token");
    print("STUDENT_ID: $studentId");
    print("USER_ID: $userId");

    if (token != null && token.isNotEmpty && studentId != null) {
      if (userId != null) AppData.userID = int.parse(userId);
      AppData.studentID = int.parse(studentId);

      await Future.delayed(const Duration(seconds: 1));

      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } else {
      await Future.delayed(const Duration(seconds: 2));

      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  void dispose() {
    _circleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 71, 226, 193),
            Color(0xFFA3D5F4),
            Color(0xFFA3D5F4),
            Color.fromARGB(255, 71, 226, 193),
            Color(0xFFA3D5F4),
            Color(0xFFA3D5F4),
            Color.fromARGB(255, 71, 226, 193),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🌿 Círculo que respira
              ScaleTransition(
                scale: _circleAnim,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.07),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 25,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),

              // 💬 Texto central
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "SeaBot",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          "Respira hondo…",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Estás en un lugar seguro.",
                          style: GoogleFonts.manrope(
                            color: Colors.white,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Sincronizando tu bienestar...",
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 13,
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
}
