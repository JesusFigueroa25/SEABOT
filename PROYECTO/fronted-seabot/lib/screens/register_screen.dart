import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/screens/home_screen.dart';
import 'package:seabot/screens/login_screen.dart';
import 'package:seabot/services/student_service.dart';
import 'package:seabot/services/user_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  UserService serviceController = UserService();
  StudentService studentService = StudentService();
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on Exception {
      return false;
    }
  }

  Future<void> _onRegisterPressed() async {
    if (_isLoading) return; // 🔥 evita doble click

    final connected = await _hasInternet();

    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("📵 No tienes conexión a internet"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _register();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true; // 🔥 INICIA LA ANIMACIÓN DE CARGA
    });

    // 🔹 Normalizar
    String cleanUser = _userController.text.trim();
    String cleanPass = _passController.text.trim();
    String cleanConfirm = _confirmPassController.text.trim();

    // Reemplazar en los controles para mostrar al usuario
    _userController.text = cleanUser;
    _passController.text = cleanPass;
    _confirmPassController.text = cleanConfirm;

    // Normalizar...
    if (cleanUser.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El nombre de usuario no puede estar vacío"),
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (cleanPass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La contraseña no puede estar vacía")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (cleanPass != cleanConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1️⃣ Crear usuario
      Map<String, dynamic> userData = {
        "nameuser": cleanUser,
        "enable": true,
        "role": "user",
        "password": cleanPass,
      };
      final user = await serviceController.createUser(userData);

      // 2️⃣ Crear estudiante vinculado
      Map<String, dynamic> studentData = {
        "alias": cleanUser,
        "safe_contact": "987456123",
        "user_id": user.id,
      };
      final student = await studentService.createStudent(studentData);

      print("✅ Usuario creado con ID: ${user.id}");
      print("✅ Estudiante creado con ID: ${student.id}");

      // 3️⃣ Login automático (para obtener el token JWT)
      final auth = AuthService();
      final token = await auth.loginUser(cleanUser, cleanPass);

      if (token == null) {
        throw Exception("No se pudo iniciar sesión automáticamente");
      }

      // 4️⃣ Guardar IDs y token en memoria
      final storage = const FlutterSecureStorage();
      await storage.write(key: "auth_token", value: token);
      await storage.write(key: "user_id", value: user.id.toString());
      await storage.write(key: "student_id", value: student.id.toString());

      AppData.userID = user.id;
      AppData.studentID = student.id!;
      AppData.token = token;

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🎉 Registro exitoso. Sesión iniciada."),
          backgroundColor: Colors.green,
        ),
      );

      // 5️⃣ Redirigir al Home directamente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al registrar: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // 🔥 DETIENE LA ANIMACIÓN SI FALLA
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle =
        theme.textTheme; // 🔹 Usa el estilo global de main.dart

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, Colors.white, AppColors.secundary],
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
                    // Logo
                    Image.asset("assets/images/SeaBot.png", height: 100),
                    const SizedBox(height: 15),

                    // Título
                    Text(
                      "Crear Cuenta",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Usuario
                    TextFormField(
                      controller: _userController,
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
                      style: const TextStyle(color: Colors.black87),
                      cursorColor: AppColors.primary,
                      validator: (value) => value!.isEmpty
                          ? "Ingrese un nombre de usuario"
                          : null,
                    ),
                    const SizedBox(height: 20),

                    // Contraseña
                    TextFormField(
                      controller: _passController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        labelStyle: baseTextStyle.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black54,
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
                      style: const TextStyle(color: Colors.black87),
                      cursorColor: AppColors.primary,
                      validator: (value) =>
                          value!.length < 4 ? "Mínimo 4 caracteres" : null,
                    ),

                    const SizedBox(height: 20),

                    // Confirmar contraseña
                    TextFormField(
                      controller: _confirmPassController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Confirmar contraseña",
                        labelStyle: baseTextStyle.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
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
                      style: const TextStyle(color: Colors.black87),
                      cursorColor: AppColors.primary,
                      validator: (value) => value != _passController.text
                          ? "Las contraseñas no coinciden"
                          : null,
                    ),

                    const SizedBox(height: 30),

                    // Botón de registrar
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : _onRegisterPressed, // 🔥 bloqueado mientras carga
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secundary,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 28,
                              width: 28,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Text(
                              "Registrarse",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),

                    const SizedBox(height: 15),

                    // Volver a login
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreenUser(),
                          ),
                        );
                      },
                      child: Text(
                        "¿Ya tienes cuenta? Inicia sesión",
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: AppColors.primaryDark,
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
