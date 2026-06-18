import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/responsive_helper.dart';
import 'package:seabot/screens/AdminDashboardScreen.dart';
import 'package:seabot/screens/widgets/seabot_widgets.dart';
import 'package:seabot/services/user_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  bool _isPasswordVisible = false;
  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final token = await _authService.login(
        _userController.text.trim(),
        _passController.text.trim(),
      );

      if (token != null) {
        print("Token recibido: $token");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nombre de usuario o contraseña incorrecta"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.secundary,
              AppColors.primary,
              AppColors.secundary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative blobs
            Positioned(
              top: -80,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              right: -80,
              top: 140,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ResponsiveHelper.centeredConstraint(
                    context: context,
                    maxTabletWidth: 430,
                    child: Column(
                      children: [
                        // Brand Logo Header
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.16),
                                blurRadius: 26,
                                spreadRadius: 3,
                              ),
                              BoxShadow(
                                color: const Color(0xFF49C9B0).withOpacity(0.18),
                                blurRadius: 38,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              "assets/images/SeaBot.png",
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Glassmorphic card container
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                color: Colors.white.withOpacity(0.72),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.42),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF34495E).withOpacity(0.10),
                                    blurRadius: 28,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Acceso Administrador",
                                        style: GoogleFonts.manrope(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF243746),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "Ingrese sus credenciales de administrador.",
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF617484),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // 🧍 Usuario administrador
                                    SeaBotTextField(
                                      controller: _userController,
                                      label: "Usuario administrador",
                                      hint: "Ingrese su usuario",
                                      icon: Icons.person_outline_rounded,
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? "Ingrese su usuario"
                                              : null,
                                    ),
                                    const SizedBox(height: 18),
                                    // 🔒 Contraseña
                                    SeaBotTextField(
                                      controller: _passController,
                                      label: "Contraseña",
                                      hint: "Ingrese su contraseña",
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: !_isPasswordVisible,
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility_rounded
                                              : Icons.visibility_off_rounded,
                                          color: const Color(0xFF50697C),
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? "Ingrese su contraseña"
                                              : null,
                                    ),
                                    const SizedBox(height: 28),
                                    // 🚪 Botón Iniciar Sesión
                                    SeaBotPrimaryButton(
                                      label: "Iniciar Sesión",
                                      onPressed: _login,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Volver text button to match user login style
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 18,
                                  color: Color(0xFF2A3D4F),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Volver",
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    color: const Color(0xFF2A3D4F),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
