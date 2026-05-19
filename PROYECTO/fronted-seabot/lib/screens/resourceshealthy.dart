import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/screens/breathing_exercise_screen.dart';
import 'package:seabot/screens/info_detail_screen.dart';
import 'package:seabot/screens/resources_educational_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse("tel:$number");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack("No se pudo iniciar la llamada.", Colors.red);
      }
    } catch (e) {
      _showSnack("Error al intentar llamar: $e", Colors.red);
    }
  }

  void _showEmergencyNumbersDialog() {
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
              constraints: const BoxConstraints(maxHeight: 620),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.95)
                    : Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 14, 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.redAccent, Color(0xFFFF8A80)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.local_phone_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Líneas Nacionales de Emergencia",
                            style: GoogleFonts.manrope(
                              fontSize: 18,
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        children: [
                          _buildPhoneItem("La línea 113", "113"),
                          _buildPhoneItem(
                            "Atención médica EsSalud (violencia familiar)",
                            "014118000",
                          ),
                          _buildPhoneItem(
                            "Denuncia contra la violencia familiar y sexual",
                            "100",
                          ),
                          _buildPhoneItem("Central policial", "105"),
                          _buildPhoneItem(
                            "EsSalud - Información COVID-19",
                            "107",
                          ),
                          _buildPhoneItem("Policía de carreteras", "110"),
                          _buildPhoneItem("Defensa Civil", "115"),
                          _buildPhoneItem("Bomberos", "116"),
                          _buildPhoneItem("Cruz Roja", "012660481"),
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
    );
  }

    Future<void> _sendEmail(String email, String subject) async {
    final Uri uri = Uri.parse(
      'mailto:$email?subject=${Uri.encodeComponent(subject)}',
    );

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showSnack(
          "No se encontró una aplicación de correo instalada.",
          Colors.redAccent,
        );
      }
    } catch (e) {
      _showSnack("No se pudo abrir el correo.", Colors.redAccent);
    }
  }



    void _showPsychologyDialog() {
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
              constraints: const BoxConstraints(maxHeight: 620),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.95)
                    : Colors.white.withOpacity(0.97),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 14, 12),
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
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Centro de Psicología Universitaria (UPC)",
                            style: GoogleFonts.manrope(
                              fontSize: 18,
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
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                      child: Column(
                        children: [
                          _buildEmailItem(
                            "Campus Monterrico",
                            "orientacionpsicopedagogicamo@upc.pe",
                          ),
                          _buildEmailItem(
                            "Campus San Isidro",
                            "orientacionpsicopedagogicasi@upc.pe",
                          ),
                          _buildEmailItem(
                            "Campus San Miguel",
                            "orientacionpsicopedagogicasm@upc.pe",
                          ),
                          _buildEmailItem(
                            "Campus Villa",
                            "orientacionpsicopedagogicavi@upc.pe",
                          ),
                          _buildEmailItem(
                            "Oficina Corporativa",
                            "orientacionpsicopedagogica@upc.pe",
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
    );
  }

  Widget _buildEmailItem(String label, String email) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.email_rounded, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: () =>
                _sendEmail(email, "Consulta de orientación psicológica"),
          ),
        ],
      ),
    );
  }

  

  Widget _buildPhoneItem(String label, String number) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.call_rounded, color: Colors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 14.2,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  number,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onPressed: () => _callNumber(number),
          ),
        ],
      ),
    );
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
            top: 220,
            left: -70,
            child: _buildBlurOrb(
              size: 180,
              color: AppColors.secundary.withOpacity(isDark ? 0.10 : 0.12),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeaderPremium(
                  title: "Recursos de Bienestar",
                  subtitle: "Herramientas y apoyo para acompañarte",
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 22),
                        _buildSectionTitle("Contactos de ayuda", isDark),
                        const SizedBox(height: 12),
                        _buildHelpCard(
                          titulo: "Líneas Nacionales de Emergencia",
                          subtitulo: "Llama directamente según tu necesidad",
                          icono: Icons.local_phone_rounded,
                          colorcito: AppColors.primary,
                          onTap: _showEmergencyNumbersDialog,
                        ),

                        //Keo - Amigos
                        _buildHelpCard(
                          titulo: "Centro de Psicología Universitaria (UPC)",
                          subtitulo: "Correos y ubicaciones por campus",
                          icono: Icons.psychology_rounded,
                          colorcito: AppColors.secundary,
                          onTap: _showPsychologyDialog,
                        ),
                        _buildHelpCard(
                          titulo: "Bienestar Estudiantil UPC",
                          subtitulo: "Consejería académica y personal",
                          icono: Icons.school_rounded,
                          colorcito: const Color(0xFF8074EF),
                          onTap: () => _showSnack(
                            "Puedes escribir a: bienestar.estudiantil@upc.pe",
                            Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Recursos principales", isDark),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          isDark: isDark,
                          icon: Icons.menu_book_rounded,
                          iconColor: const Color(0xFF6C63FF),
                          title: "Recursos Educativos",
                          subtitle:
                              "Encuentra artículos, videos y guías sobre bienestar emocional",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ResourcesEducationalScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildFeatureCard(
                          isDark: isDark,
                          icon: Icons.air_rounded,
                          iconColor: Colors.teal,
                          title: "Ejercicio de Respiración 4-7-8",
                          subtitle: "Relaja tu mente y cuerpo en 1 minuto",
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BreathingExerciseScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Frases motivacionales", isDark),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 184,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            children: [
                              _buildFrasesMotivadoras(
                                "Cada día es una nueva oportunidad para crecer y convertirte en la mejor versión de ti mismo.",
                                AppColors.primary,
                              ),
                              _buildFrasesMotivadoras(
                                "Tu valor no se mide por tus logros académicos, sino por la persona maravillosa que eres.",
                                AppColors.secundary,
                              ),
                              _buildFrasesMotivadoras(
                                "Está bien no estar bien. Lo importante es que sigas adelante, un paso a la vez.",
                                const Color(0xFF89A1F4),
                              ),
                              _buildFrasesMotivadoras(
                                "Eres más fuerte de lo que crees, más valiente de lo que sientes y más amado de lo que imaginas.",
                                const Color(0xFFFF7E6C),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Guías informativas", isDark),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          theme,
                          title: "Guía para la prevención del suicidio - MINSA",
                          subtitle: "Documento PDF oficial del MINSA",
                          assetPath: "assets/docs/guia_minsa.pdf",
                          isPdf: true,
                        ),
                        _buildInfoCard(
                          theme,
                          title: "Infografía sobre depresión - UPC",
                          subtitle:
                              "Imagen informativa de bienestar estudiantil",
                          assetPath: "assets/images/infografia_upc.png",
                          isPdf: false,
                        ),
                      ],
                    ),
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

  /*  Widget _buildQuickEmergencyBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.sos_rounded,
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
                  "¿Necesitas ayuda inmediata?",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Accede rápido a líneas de apoyo o a tu contacto seguro.",
                  style: GoogleFonts.manrope(
                    fontSize: 13.2,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.92),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _showEmergencyOptions(context),
            child: Text(
              "Abrir",
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }*/

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF18202A),
      ),
    );
  }

  Widget _buildFeatureCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        fontSize: 15.3,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF18202A),
                      ),
                    ),
                    const SizedBox(height: 5),
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

  Widget _buildHeaderPremium({
    required String title,
    String? subtitle,
    Future<bool> Function()? onWillPopCustom,
  }) {
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
          // 🔹 decoración
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

          // 🔹 contenido
          Row(
            children: [
              // 🔥 BOTÓN BACK REUTILIZABLE
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    if (onWillPopCustom != null) {
                      final canLeave = await onWillPopCustom();
                      if (canLeave && mounted) Navigator.pop(context);
                    } else {
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.24)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.manrope(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrasesMotivadoras(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 14),
      width: 290,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: Colors.white,
              size: 28,
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 16,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String assetPath,
    required bool isPdf,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InfoDetailScreen(
                  title: title,
                  assetPath: assetPath,
                  isPdf: isPdf,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF18202A),
                        ),
                      ),
                      const SizedBox(height: 5),
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
      ),
    );
  }

  Widget _buildHelpCard({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorcito,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
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
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorcito.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icono, color: colorcito, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: GoogleFonts.manrope(
                          fontSize: 15.2,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF18202A),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitulo,
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
      ),
    );
  }
}
