import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/services/user_service.dart';
import 'package:seabot/screens/bienvenida_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seabot/services/support_report_service.dart';
import 'package:seabot/screens/support_email_verification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      if (!mounted) return;
      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    if (!mounted) return;
    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  Future<bool> _hasInternet() async {
    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.none)) return false;

    try {
      final result = await InternetAddress.lookup(
        'seabot-backend-993787742289.us-central1.run.app',
      ).timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _showTermsAndConditions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 640),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.94)
                    : Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 14, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.secundary],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.22),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Términos y Condiciones",
                            style: GoogleFonts.manrope(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF18202A),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.06),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Text(
                        """
1. Finalidad del servicio  
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

9. Contacto y soporte  
Para consultas, comentarios o sugerencias, los usuarios pueden comunicarse a través del correo de soporte institucional o las vías de contacto descritas en la sección de ayuda de la aplicación.

Al continuar, confirmas que has leído y aceptas estos términos y condiciones de uso.
""",
                        style: GoogleFonts.manrope(
                          fontSize: 14.2,
                          height: 1.65,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.secundary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cerrar",
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _cerrarSesion() async {
    final hasInternet = await _hasInternet();

    if (!mounted) return;

    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No tienes conexión a internet. No se pudo cerrar sesión.",
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

    final authService = AuthService();
    await authService.logout();

    AppData.token = "";
    AppData.userID = 0;
    AppData.studentID = 0;

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sesión cerrada correctamente.",
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.secundary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  Future<void> _handleTermsAndConditionsTap() async {
    final hasInternet = await _hasInternet();

    if (!mounted) return;

    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No tienes conexión a internet. No se pudieron cargar los términos y condiciones.",
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

    _showTermsAndConditions();
  }

  void _eliminarCuenta() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.95)
                    : Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.delete_forever_rounded,
                      color: Colors.redAccent,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Eliminar cuenta",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF18202A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "¿Estás seguro de que deseas eliminar tu cuenta?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14.3,
                      height: 1.55,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white
                                : Colors.black87,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancelar",
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);

                            final hasInternet = await _hasInternet();

                            if (!mounted) return;

                            if (!hasInternet) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error al eliminar cuenta. Verifica tu conexión a internet.",
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

                            try {
                              final userService = UserService();
                              final userId = AppData.userID;
                              await userService.updateEnable(userId, {
                                "enable": false,
                              });

                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "✅ Tu cuenta ha sido desactivada correctamente.",
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              );

                              final authService = AuthService();
                              await authService.logout();
                              AppData.userID = 0;
                              AppData.studentID = 0;

                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SplashScreen(),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "❌ Error al desactivar cuenta: $e",
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
                            }
                          },
                          child: Text(
                            "Eliminar",
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
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportReportDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final SupportReportService supportService = SupportReportService();
    final TextEditingController descriptionController = TextEditingController();

    final List<String> reportTypes = [
      "Incidencia",
      "Reclamo",
      "Reporte de error",
      "Retroalimentación",
      "Sugerencia",
    ];

    String selectedReportType = reportTypes.first;
    File? selectedImage;
    bool sending = false;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
              try {
                final picker = ImagePicker();

                final XFile? pickedImage = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );

                if (pickedImage == null) return;

                setDialogState(() {
                  selectedImage = File(pickedImage.path);
                });
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "No se pudo seleccionar la imagen.",
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
              }
            }

            Future<void> sendReport() async {
              final description = descriptionController.text.trim();

              if (description.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Describe brevemente el motivo del reporte.",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
                return;
              }

              final hasInternet = await _hasInternet();

              if (!mounted) return;

              if (!hasInternet) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "No tienes conexión a internet.",
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

              setDialogState(() {
                sending = true;
              });

              try {
                await supportService.createSupportReport(
                  studentId: AppData.studentID,
                  reportType: selectedReportType,
                  description: description,
                  foto: selectedImage,
                );

                if (!mounted) return;

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Reporte enviado correctamente a soporte.",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;

                final errorText = e.toString().replaceFirst("Exception: ", "");

                setDialogState(() {
                  sending = false;
                });

                if (errorText.contains("Debe verificar su correo")) {
                  _showEmailVerificationRequiredDialog(dialogContext);
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errorText,
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
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF171B22).withOpacity(0.96)
                          : Colors.white.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secundary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "Reporte a soporte",
                                  style: GoogleFonts.manrope(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF18202A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: sending
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Text(
                            "Tipo de reporte",
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF4F7FA),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : Colors.black.withOpacity(0.06),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedReportType,
                                isExpanded: true,
                                dropdownColor: isDark
                                    ? const Color(0xFF1D232D)
                                    : Colors.white,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                ),
                                items: reportTypes.map((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      type,
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF18202A),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: sending
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setDialogState(() {
                                          selectedReportType = value;
                                        });
                                      },
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "Descripción",
                            style: GoogleFonts.manrope(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextField(
                            controller: descriptionController,
                            enabled: !sending,
                            maxLines: 5,
                            maxLength: 500,
                            style: GoogleFonts.manrope(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  "Describe el problema, reclamo o sugerencia...",
                              hintStyle: GoogleFonts.manrope(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontWeight: FontWeight.w500,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : const Color(0xFFF4F7FA),
                              counterStyle: GoogleFonts.manrope(
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: sending ? null : pickImage,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selectedImage == null
                                    ? AppColors.primary.withOpacity(0.10)
                                    : Colors.green.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selectedImage == null
                                      ? AppColors.primary.withOpacity(0.22)
                                      : Colors.green.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedImage == null
                                        ? Icons.image_outlined
                                        : Icons.check_circle_rounded,
                                    color: selectedImage == null
                                        ? AppColors.primary
                                        : Colors.green,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      selectedImage == null
                                          ? "Adjuntar imagen opcional"
                                          : "Imagen seleccionada",
                                      style: GoogleFonts.manrope(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: selectedImage == null
                                            ? AppColors.primary
                                            : Colors.green,
                                      ),
                                    ),
                                  ),
                                  if (selectedImage != null)
                                    IconButton(
                                      onPressed: sending
                                          ? null
                                          : () {
                                              setDialogState(() {
                                                selectedImage = null;
                                              });
                                            },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          if (selectedImage != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                selectedImage!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.secundary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: sending ? null : sendReport,
                              child: sending
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      "Enviar reporte",
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEmailVerificationRequiredDialog([
    BuildContext? reportDialogContext,
  ]) {
    if (reportDialogContext != null) {
      Navigator.pop(reportDialogContext);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.96)
                    : Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                    blurRadius: 28,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Verifica tu correo",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF18202A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Para enviar reportes a soporte, primero debes verificar tu correo electrónico mediante un código OTP.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 14.3,
                      height: 1.55,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.white
                                : Colors.black87,
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.08),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancelar",
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.secundary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);

                            final verified = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const SupportEmailVerificationScreen(),
                              ),
                            );

                            if (verified == true && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Correo verificado. Ya puedes enviar tu reporte.",
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              );

                              _showSupportReportDialog();
                            }
                          },
                          child: Text(
                            "Verificar",
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSupportTap() async {
    final hasInternet = await _hasInternet();

    if (!mounted) return;

    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No tienes conexión a internet.",
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

    if (AppData.studentID == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No se encontró el identificador del estudiante.",
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

    try {
      final supportService = SupportReportService();

      final isVerified = await supportService.isSupportEmailVerified(
        AppData.studentID,
      );

      if (!mounted) return;

      if (isVerified) {
        _showSupportReportDialog();
      } else {
        _showEmailVerificationRequiredDialog();
      }
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().replaceFirst("Exception: ", "");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorText,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
              size: 210,
              color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.16),
            ),
          ),
          Positioned(
            top: 190,
            left: -70,
            child: _buildBlurOrb(
              size: 180,
              color: AppColors.secundary.withOpacity(isDark ? 0.10 : 0.12),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    children: [
                      _buildConnectionCard(isDark),
                      const SizedBox(height: 18),

                      _buildSettingsCard(
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            isDark: isDark,
                            icon: Icons.logout_rounded,
                            iconColor: Colors.orange,
                            title: "Cerrar sesión",
                            subtitle: "Salir de tu cuenta actual",
                            onTap: _cerrarSesion,
                          ),
                          _buildDivider(isDark),
                        ],
                      ),

                      const SizedBox(height: 18),

                      _buildSettingsCard(
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            isDark: isDark,
                            icon: Icons.description_rounded,
                            iconColor: AppColors.primary,
                            title: "Términos y condiciones",
                            subtitle:
                                "Consulta las políticas de uso y privacidad",
                            onTap: _handleTermsAndConditionsTap,
                          ),
                          _buildDivider(isDark),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _buildSettingsCard(
                        isDark: isDark,
                        children: [
                          _buildDivider(isDark),
                          _buildSettingsTile(
                            isDark: isDark,
                            icon: Icons.delete_forever_rounded,
                            iconColor: Colors.redAccent,
                            title: "Eliminar cuenta",
                            subtitle: "Desactivar temporalmente tu acceso",
                            onTap: _eliminarCuenta,
                            isDestructive: true,
                          ),
                          _buildDivider(isDark),
                        ],
                      ),
                      const SizedBox(height: 18),

                      _buildSettingsCard(
                        isDark: isDark,
                        children: [
                          _buildSettingsTile(
                            isDark: isDark,
                            icon: Icons.support_agent_rounded,
                            iconColor: AppColors.primary,
                            title: "Soporte",
                            subtitle: "Enviar reporte, sugerencia o incidencia",
                            onTap: _handleSupportTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildHeader(bool isDark) {
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
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: const Icon(
                  Icons.settings_rounded,
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
                      "Configuración",
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
                      "Gestiona tu cuenta y preferencias",
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

  Widget _buildConnectionCard(bool isDark) {
    final statusColor = isConnected ? Colors.green : Colors.redAccent;

    return Container(
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
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isConnected
                        ? [const Color(0xFF41C98A), const Color(0xFF72E2A7)]
                        : [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  "Estado de conexión",
                  style: GoogleFonts.manrope(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isConnected ? "Conectado" : "Sin red",
                  style: GoogleFonts.manrope(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withOpacity(0.12)),
            ),
            child: Text(
              isConnected
                  ? "Funciones en línea disponibles: chat, perfil, soporte, test, recursos y sincronización."
                  : "Sin conexión: solo podrás consultar información guardada previamente.",
              style: GoogleFonts.manrope(
                fontSize: 12.8,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  //Widget _buildSectionLabel(String title, bool isDark) {
  //  return Text(
  //    title,
  //    style: GoogleFonts.manrope(
  //      fontSize: 17,
  //      fontWeight: FontWeight.w800,
  //      color: isDark ? Colors.white : const Color(0xFF18202A),
  //    ),
  //  );
  //}

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15.2,
                        fontWeight: FontWeight.w800,
                        color: isDestructive
                            ? Colors.redAccent
                            : (isDark ? Colors.white : const Color(0xFF18202A)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.06),
    );
  }
}
