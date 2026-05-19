import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/help_resource.dart';
import 'package:seabot/screens/PDFViewerScreen.dart';
import 'package:seabot/screens/WebResourceViewer.dart';
import 'package:seabot/services/help_resource_service.dart';

class ResourcesEducationalScreen extends StatefulWidget {
  const ResourcesEducationalScreen({super.key});

  @override
  State<ResourcesEducationalScreen> createState() =>
      _ResourcesEducationalScreenState();
}

class _ResourcesEducationalScreenState
    extends State<ResourcesEducationalScreen> {
  final HelpResourceService serviceController = HelpResourceService();
  late Future<List<HelpResource>> recursos;

  @override
  void initState() {
    super.initState();
    recursos = _obtenerRecursosActivos();
  }

  Future<List<HelpResource>> _obtenerRecursosActivos() async {
    final todos = await serviceController.getAllResources();
    return todos.where((r) => r.enable == true).toList();
  }

  IconData _getIcon(String tipo) {
    switch (tipo) {
      case "Video":
        return Icons.play_circle_fill_rounded;
      case "Guía":
        return Icons.menu_book_rounded;
      case "Artículo":
      default:
        return Icons.article_rounded;
    }
  }

  Color _getColor(String tipo) {
    switch (tipo) {
      case "Video":
        return Colors.redAccent;
      case "Guía":
        return Colors.green;
      case "Artículo":
      default:
        return Colors.blueAccent;
    }
  }

  String _getTypeLabel(String tipo) {
    switch (tipo) {
      case "Video":
        return "Video";
      case "Guía":
        return "Guía";
      case "Artículo":
      default:
        return "Artículo";
    }
  }

  void _abrirRecurso(HelpResource recurso) async {
    final tipo = recurso.resourceType ?? "";
    final url = recurso.url ?? "";

    if (tipo == "Artículo" || tipo == "Video") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              WebResourceViewer(url: url, title: recurso.nameResource),
        ),
      );
    } else if (tipo == "Guía") {
      if (url.contains("drive.google.com")) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                WebResourceViewer(url: url, title: recurso.nameResource),
          ),
        );
      } else if (url.endsWith(".pdf")) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PDFViewerScreen(url: url, title: recurso.nameResource),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Formato no compatible",
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
                _buildHeader(),
                Expanded(
                  child: FutureBuilder<List<HelpResource>>(
                    future: recursos,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState(isDark);
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(isDark);
                      }

                      final recursosActivos = snapshot.data!;

                      return ListView.builder(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                        itemCount: recursosActivos.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: _buildIntroCard(isDark, recursosActivos.length),
                            );
                          }

                          final r = recursosActivos[index - 1];
                          final tipo = r.resourceType ?? "";
                          final colorIcon = _getColor(tipo);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildResourceCard(
                              isDark: isDark,
                              recurso: r,
                              tipo: tipo,
                              colorIcon: colorIcon,
                            ),
                          );
                        },
                      );
                    },
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
                  Icons.menu_book_rounded,
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
                      "Recursos educativos",
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
                      "Lecturas, videos y guías para tu bienestar",
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

  Widget _buildIntroCard(bool isDark, int total) {
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
              Icons.auto_stories_rounded,
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
                  "Explora tus recursos disponibles",
                  style: GoogleFonts.manrope(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF18202A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Actualmente tienes $total recurso${total == 1 ? '' : 's'} activo${total == 1 ? '' : 's'} para consultar.",
                  style: GoogleFonts.manrope(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF171C24)
              : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(26),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: AppColors.primary,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "No hay recursos disponibles",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF18202A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Vuelve más tarde para revisar nuevos contenidos educativos.",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResourceCard({
    required bool isDark,
    required HelpResource recurso,
    required String tipo,
    required Color colorIcon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _abrirRecurso(recurso),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colorIcon.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_getIcon(tipo), color: colorIcon, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          recurso.nameResource,
                          style: GoogleFonts.manrope(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF18202A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorIcon.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _getTypeLabel(tipo),
                            style: GoogleFonts.manrope(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w800,
                              color: colorIcon,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recurso.description?.isNotEmpty == true
                          ? recurso.description!
                          : "Sin descripción",
                      style: GoogleFonts.manrope(
                        fontSize: 13.4,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.open_in_new_rounded,
                    size: 19,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () => _abrirRecurso(recurso),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}