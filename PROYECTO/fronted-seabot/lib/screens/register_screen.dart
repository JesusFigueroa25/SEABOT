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
  final TextEditingController _correoController = TextEditingController();
  UserService serviceController = UserService();
  StudentService studentService = StudentService();
  bool _isLoading = false;

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  bool _acceptedTerms = false;

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
    if (_isLoading) return;

    if (!_acceptedTerms) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Debes aceptar los términos y condiciones"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Términos y condiciones",
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              '''1. Finalidad del servicio  
SeaBot es una aplicación diseñada para brindar acompañamiento emocional y orientación general basada en inteligencia artificial. No sustituye la atención profesional de psicólogos, psiquiatras ni otros especialistas en salud mental.

2. Confidencialidad y protección de datos  
Toda la información proporcionada por el usuario se maneja de forma confidencial, conforme a la Ley N° 29733 de Protección de Datos Personales (Perú). Los datos se almacenan temporalmente y de manera anonimizada para mejorar la experiencia y garantizar la seguridad del usuario.

3. Consentimiento informado  
Al usar la aplicación, el usuario reconoce que las interacciones con el chatbot son de carácter orientativo y acepta voluntariamente participar, comprendiendo que no se trata de un servicio clínico o de diagnóstico.

4. Limitaciones de responsabilidad  
SeaBot no asume responsabilidad por decisiones tomadas a partir de la información proporcionada por el chatbot. Las respuestas generadas provienen del modelo de lenguaje GPT-4, el cual utiliza inteligencia artificial y puede ofrecer información imprecisa, desactualizada o interpretaciones erradas de las consultas del usuario.
El contenido tiene únicamente fines de acompañamiento emocional y orientación general. Ante cualquier situación de riesgo, crisis o emergencia, el usuario debe comunicarse de inmediato con servicios profesionales de salud mental o líneas de ayuda disponibles en su país.

5. Uso responsable de la aplicación  
El usuario se compromete a hacer un uso adecuado del contenido y las funciones de SeaBot, evitando lenguaje ofensivo, manipulación del sistema o difusión de información falsa.

6. Propiedad intelectual  
El contenido, diseño, logotipo, estructura y código fuente de la aplicación son propiedad del equipo desarrollador del proyecto académico “SeaBot”, quedando prohibida su copia o distribución no autorizada.

7. Derechos del usuario  
El usuario puede solicitar la eliminación o desactivación de su cuenta en cualquier momento, conforme a los procedimientos internos de la aplicación. Además, puede revocar su consentimiento de uso de datos personales enviando una solicitud por los canales indicados.

8. Actualización de los términos  
SeaBot se reserva el derecho de modificar estos términos para mejorar la experiencia, seguridad o cumplimiento legal. Toda actualización será notificada dentro de la aplicación.

Al continuar, confirmas que has leído y aceptas estos términos y condiciones de uso.''',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    // 🔹 Normalizar
    String cleanUser = _userController.text.trim();
    String cleanPass = _passController.text.trim();
    //String cleanCorreo = _correoController.text.trim();
    String cleanCorreo = _correoController.text.trim().toLowerCase();
    String cleanConfirm = _confirmPassController.text.trim();

    // Reemplazar en los controles para mostrar al usuario
    _userController.text = cleanUser;
    _correoController.text = cleanCorreo;
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

    if (cleanCorreo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El correo no puede estar vacío")),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(cleanCorreo)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Correo inválido")));
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
      final correoExists = await studentService.existsCorreo(cleanCorreo);

      if (correoExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("El correo ya está registrado"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() => _isLoading = false);
        return;
      }
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
        "correo": cleanCorreo,
        "user_id": user.id,
      };
      final student = await studentService.createStudent(studentData);

      print("✅ Usuario creado con ID: ${user.id}");
      print("✅ Estudiante creado con ID: ${student.id}");
      print("✅ Correo: ${student.correo}");

      // 3️⃣ Login automático (para obtener el token JWT)
      final auth = AuthService();
      final token = await auth.login(cleanUser, cleanPass);

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

      String message = e.toString();

      if (message.contains("El nombre de usuario ya existe")) {
        message = "El nombre de usuario ya está registrado";
      } else if (message.contains("El correo ya está registrado")) {
        message = "El correo ya está registrado";
      } else if (message.contains("No se pudo validar el correo")) {
        message = "No se pudo validar el correo. Inténtalo nuevamente.";
      } else {
        message = "No se pudo completar el registro";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canRegister = _acceptedTerms && !_isLoading;
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF49C9B0),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF4F6475),
            fontWeight: FontWeight.w500,
          ),
          prefixIconColor: const Color(0xFF49C9B0),
          suffixIconColor: const Color(0xFF4F6475),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF49C9B0), width: 1.5),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF49C9B0);
            }
            return Colors.white;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: const BorderSide(color: Color(0xFF49C9B0), width: 1.4),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            disabledBackgroundColor: Colors.transparent,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF2A3D4F)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: GoogleFonts.nunito(
            color: const Color(0xFF213547),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          contentTextStyle: GoogleFonts.nunito(
            color: Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secundary,
                Color(0xFF9FE2D4),
                Color(0xFF9FE2D4),
                Color(0xFFF9FAFB),
                Color(0xFFA3D5F4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.15),
                                  blurRadius: 25,
                                ),
                                BoxShadow(
                                  color: const Color(
                                    0xFF49C9B0,
                                  ).withOpacity(0.2),
                                  blurRadius: 35,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/images/SeaBot.png",
                                height: 70,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Crear cuenta",
                            style: GoogleFonts.inter(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF213547),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Empieza tu camino hacia el bienestar emocional",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF4F6475),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white.withOpacity(0.75),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _input(_userController, "Usuario", Icons.person),

                              const SizedBox(height: 16),

                              _inputPassword(
                                _passController,
                                "Contraseña",
                                _isPasswordVisible,
                                () => setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                }),
                              ),

                              const SizedBox(height: 16),

                              _inputPassword(
                                _confirmPassController,
                                "Confirmar contraseña",
                                _isConfirmPasswordVisible,
                                () => setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                }),
                              ),

                              const SizedBox(height: 16),

                              _input(
                                _correoController,
                                "Correo",
                                Icons.email,
                                keyboard: TextInputType.emailAddress,
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Checkbox(
                                    value: _acceptedTerms,
                                    onChanged: (v) {
                                      setState(() {
                                        _acceptedTerms = v ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Wrap(
                                      children: [
                                        Text(
                                          "Acepto los ",
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: const Color(0xFF213547),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _showTermsDialog,
                                          child: Text(
                                            "términos y condiciones",
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                              color: const Color(0xFF2A3D4F),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(18),
                                    gradient: LinearGradient(
                                      colors: canRegister
                                          ? const [
                                              AppColors.secundary,
                                              Color(0xFF7FDAC7),
                                            ]
                                          : const [
                                              Color(0xFFBFD7D2),
                                              Color(0xFFD7E8E5),
                                            ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: canRegister
                                            ? AppColors.secundary.withOpacity(
                                                0.30,
                                              )
                                            : Colors.black.withOpacity(0.06),
                                        blurRadius: canRegister ? 20 : 10,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: canRegister
                                        ? _onRegisterPressed
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      disabledBackgroundColor:
                                          Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      surfaceTintColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.6,
                                            ),
                                          )
                                        : Text(
                                            "Registrarse",
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: canRegister
                                                  ? Colors.white
                                                  : const Color(0xFF6A8C86),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreenUser(),
                            ),
                          );
                        },
                        child: Text(
                          "¿Ya tienes cuenta?  Inicia sesión",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF2A3D4F),
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
      ),
    );
  }

  Widget _input(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: GoogleFonts.inter(
        color: const Color(0xFF213547),
        fontWeight: FontWeight.w500,
      ),
      cursorColor: const Color(0xFF49C9B0),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF49C9B0)),
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF4F6475),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF49C9B0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
      validator: (v) => v!.isEmpty ? "Campo requerido" : null,
    );
  }

  Widget _inputPassword(
    TextEditingController controller,
    String label,
    bool visible,
    VoidCallback toggle,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      style: GoogleFonts.inter(
        color: const Color(0xFF213547),
        fontWeight: FontWeight.w500,
      ),
      cursorColor: const Color(0xFF49C9B0),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF49C9B0)),
        suffixIcon: IconButton(
          icon: Icon(
            visible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFF4F6475),
          ),
          onPressed: toggle,
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: GoogleFonts.inter(
          color: const Color(0xFF4F6475),
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1E8ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF49C9B0), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
      validator: (v) => v!.length < 4 ? "Mínimo 4 caracteres" : null,
    );
  }
}
