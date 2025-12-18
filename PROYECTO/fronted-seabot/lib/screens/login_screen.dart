import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/screens/AdminDashboardScreen.dart';
import 'package:seabot/screens/bienvenida_screen.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreenUser extends StatefulWidget {
  const LoginScreenUser({super.key});

  @override
  State<LoginScreenUser> createState() => _LoginScreenUserState();
}

class _LoginScreenUserState extends State<LoginScreenUser> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isPasswordVisible = false;

  final AuthService _authService = AuthService();

  Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final connected = await _hasInternet();
      if (!mounted) return;

      if (!connected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "📵 No tienes conexión a internet",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      try {
        // 🔹 Realiza el login unificado
        final token = await _authService.login(
          _userController.text.trim(),
          _passController.text.trim(),
        );

        if (!mounted) return;

        if (token == null || token.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Usuario o contraseña incorrecta. Inténtalo de nuevo.",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // ✅ Leer el rol desde el almacenamiento seguro
        final storage = const FlutterSecureStorage();
        final role = await storage.read(key: "role");

        // 🔹 Navegar según el tipo de usuario
        if (role == "admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        String errorMessage = "Error inesperado. Inténtalo más tarde.";

        if (e.toString().contains("SocketException")) {
          errorMessage = "Error de conexión con el servidor.";
        } else if (e.toString().contains("401") ||
            e.toString().toLowerCase().contains("unauthorized")) {
          errorMessage = "Usuario o contraseña incorrecta.";
        } else if (e.toString().contains("Null") ||
            e.toString().contains("subtype")) {
          errorMessage = "Credenciales inválidas. Revisa tus datos.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ $errorMessage",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.secundary, Colors.white, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset("assets/images/SeaBot.png", height: 120),
                    const SizedBox(height: 20),

                    Text(
                      "Tu bienestar es lo más importante",
                      style: baseTextStyle.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Este es tu espacio seguro",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 🧍 Usuario
                    TextFormField(
                      controller: _userController,
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: "Usuario",
                        labelStyle: baseTextStyle.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        prefixIcon: const Icon(
                          Icons.person,
                          color: AppColors.primaryDark,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.secundary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese su usuario" : null,
                    ),

                    const SizedBox(height: 20),

                    // 🔒 Contraseña
                    TextFormField(
                      controller: _passController,
                      obscureText: !_isPasswordVisible,
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        labelStyle: baseTextStyle.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: AppColors.primaryDark,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.primaryDark,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: AppColors.secundary,
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? "Ingrese su contraseña" : null,
                    ),

                    const SizedBox(height: 30),

                    // 🔵 Botón de login
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secundary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "Iniciar Sesión",
                        style: baseTextStyle.labelLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔙 Texto para volver
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SplashScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "¿Volver?",
                        style: baseTextStyle.labelLarge?.copyWith(
                          fontSize: 16,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
