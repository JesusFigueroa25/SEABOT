import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/support_report.dart';
import 'package:seabot/services/support_report_service.dart';

class SupportReportsAdminScreen extends StatefulWidget {
  const SupportReportsAdminScreen({super.key});

  @override
  State<SupportReportsAdminScreen> createState() =>
      _SupportReportsAdminScreenState();
}

class _SupportReportsAdminScreenState extends State<SupportReportsAdminScreen> {
  final SupportReportService _supportReportService = SupportReportService();

  late Future<List<SupportReport>> _reportsFuture;

  final List<String> _statusOptions = const [
    "Recibido",
    "En proceso",
    "Cerrado",
  ];

  @override
  void initState() {
    super.initState();
    _reportsFuture = _supportReportService.getAdminReports();
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _supportReportService.getAdminReports();
    });

    await _reportsFuture;
  }

  void _showSnackBar({required String message, required Color color}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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



/*  
  Future<void> _updateReportStatus({
    required SupportReport report,
    required String newStatus,
  }) async {
    try {
      await _supportReportService.updateReportStatus(report.id, {
        "status": newStatus,
      });

      if (!mounted) return;

      _showSnackBar(
        message: "Estado actualizado a: $newStatus",
        color: Colors.green,
      );

      await _refreshReports();
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().replaceFirst("Exception: ", "");

      _showSnackBar(message: errorText, color: Colors.redAccent);
    }
  }

void _showStatusBottomSheet(SupportReport report) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF171B22).withOpacity(0.97)
                    : Colors.white.withOpacity(0.98),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.05),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.manage_history_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            "Cambiar estado.",
                            style: GoogleFonts.manrope(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF18202A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ..._statusOptions.map((status) {
                      final bool selected = report.status == status;
                      final Color statusColor = _getStatusColor(status);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.pop(context);

                            if (!selected) {
                              _updateReportStatus(
                                report: report,
                                newStatus: status,
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? statusColor.withOpacity(0.13)
                                  : (isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : const Color(0xFFF4F7FA)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? statusColor.withOpacity(0.35)
                                    : (isDark
                                          ? Colors.white.withOpacity(0.06)
                                          : Colors.black.withOpacity(0.05)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  color: selected
                                      ? statusColor
                                      : (isDark
                                            ? Colors.white54
                                            : Colors.black38),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: GoogleFonts.manrope(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? statusColor
                                          : (isDark
                                                ? Colors.white
                                                : const Color(0xFF18202A)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
*/

  void _showImagePreview(String imageUrl) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.70),
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF171B22) : Colors.white,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Imagen adjunta",
                            style: GoogleFonts.manrope(
                              fontSize: 17,
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
                  Flexible(
                    child: InteractiveViewer(
                      minScale: 0.7,
                      maxScale: 4,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const SizedBox(
                            height: 320,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (_, __, ___) {
                          return Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.redAccent,
                                  size: 42,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No se pudo cargar la imagen. Actualiza la lista para generar una nueva URL.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Recibido":
        return AppColors.primary;
      case "En proceso":
        return Colors.orange;
      case "Cerrado":
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getReportIcon(String type) {
    switch (type) {
      case "Incidencia":
        return Icons.warning_amber_rounded;
      case "Reclamo":
        return Icons.record_voice_over_rounded;
      case "Reporte de error":
        return Icons.bug_report_rounded;
      case "Retroalimentación":
        return Icons.feedback_rounded;
      case "Sugerencia":
        return Icons.lightbulb_rounded;
      default:
        return Icons.support_agent_rounded;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Sin fecha";

    String twoDigits(int value) => value.toString().padLeft(2, "0");

    final day = twoDigits(date.day);
    final month = twoDigits(date.month);
    final year = date.year.toString();
    final hour = twoDigits(date.hour);
    final minute = twoDigits(date.minute);

    return "$day/$month/$year $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F1115)
          : const Color(0xFFF6F8FB),
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 70, // 👈 aumenta la altura
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Reportes de Soporte",
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Selecciona uno",
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF6F8FB),
              ),
            ),
          ],
        ),
      ),
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
          FutureBuilder<List<SupportReport>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(isDark);
              }

              if (snapshot.hasError) {
                return _buildErrorState(
                  isDark: isDark,
                  error: snapshot.error.toString(),
                );
              }

              final reports = snapshot.data ?? [];

              if (reports.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return RefreshIndicator(
                onRefresh: _refreshReports,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return _buildReportCard(
                      report: reports[index],
                      isDark: isDark,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detailText({
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              "$title:",
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF18202A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openReportDetail(SupportReport report) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String? imageUrl;
    bool loadingImage = false;
    bool requestedImage = false;
    bool dialogAlive = true;
    String? imageError;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> loadImageUrl() async {
              if (!dialogAlive) return;
              if (imageUrl != null || loadingImage) return;

              setDialogState(() {
                loadingImage = true;
                imageError = null;
              });

              try {
                final url = await _supportReportService.getReportImageUrl(
                  report.id,
                );

                if (!dialogAlive || !mounted) return;

                setDialogState(() {
                  imageUrl = url;
                  loadingImage = false;
                });
              } catch (e) {
                if (!dialogAlive || !mounted) return;

                final errorText = e.toString().replaceFirst("Exception: ", "");

                setDialogState(() {
                  imageError = errorText;
                  loadingImage = false;
                });
              }
            }

            final hasImage =
                report.rutaFoto != null && report.rutaFoto!.trim().isNotEmpty;

            if (hasImage &&
                imageUrl == null &&
                !loadingImage &&
                imageError == null &&
                !requestedImage) {
              requestedImage = true;
              Future.microtask(loadImageUrl);
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 28,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 680),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF171B22).withOpacity(0.97)
                          : Colors.white.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.support_agent_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Detalle del reporte",
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF18202A),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  dialogAlive = false;
                                  Navigator.pop(dialogContext);
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _detailText(
                            title: "Tipo",
                            value: report.reportType,
                            isDark: isDark,
                          ),
                          _detailText(
                            title: "Estado",
                            value: report.status,
                            isDark: isDark,
                          ),
                          _detailText(
                            title: "Estudiante ID",
                            value: report.studentId.toString(),
                            isDark: isDark,
                          ),
                          _detailText(
                            title: "Fecha",
                            value: _formatDate(report.createdAt),
                            isDark: isDark,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Descripción",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            report.description,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            "Imagen adjunta",
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),

                          if (!hasImage)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : const Color(0xFFF4F7FA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "Este reporte no tiene imagen adjunta.",
                                style: GoogleFonts.manrope(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else if (loadingImage)
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withOpacity(0.04)
                                    : const Color(0xFFF4F7FA),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (imageError != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    imageError!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.manrope(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton.icon(
                                    onPressed: () {
                                      requestedImage = false;
                                      loadImageUrl();
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text("Reintentar"),
                                  ),
                                ],
                              ),
                            )
                          else if (imageUrl != null)
                            GestureDetector(
                              onTap: () => _showImagePreview(imageUrl!),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.network(
                                  imageUrl!,
                                  height: 220,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          const SizedBox(height: 18),


                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                dialogAlive = false;
                                Navigator.pop(dialogContext);
                                _showAdminEmailDialog(report);
                              },
                              icon: const Icon(Icons.email_rounded),
                              label: Text(
                                "Actualizar reporte",
                                style: GoogleFonts.manrope(
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
    ).whenComplete(() {
      dialogAlive = false;
    });
  }

  Widget _buildReportCard({
    required SupportReport report,
    required bool isDark,
  }) {
    final statusColor = _getStatusColor(report.status);
    final bool hasImage =
        report.rutaFoto != null && report.rutaFoto!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openReportDetail(report),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.96),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _getReportIcon(report.reportType),
                        color: AppColors.primary,
                        size: 27,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.reportType,
                            style: GoogleFonts.manrope(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF18202A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Estudiante ID: ${report.studentId}",
                            style: GoogleFonts.manrope(
                              fontSize: 12.8,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(
                      status: report.status,
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  report.description,
                  style: GoogleFonts.manrope(
                    fontSize: 14.2,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 17,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(report.createdAt),
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
                if (hasImage) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _openReportDetail(report),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Ver imagen adjunta",
                              style: GoogleFonts.manrope(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : const Color(0xFFF4F7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_not_supported_rounded,
                          size: 20,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Sin imagen adjunta",
                          style: GoogleFonts.manrope(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                //SizedBox(
                //  width: double.infinity,
                //  child: OutlinedButton.icon(
                //    style: OutlinedButton.styleFrom(
                //      foregroundColor: AppColors.secundary,
                //      side: BorderSide(
                //        color: AppColors.secundary.withOpacity(0.35),
                //      ),
                //      padding: const EdgeInsets.symmetric(vertical: 13),
                //      shape: RoundedRectangleBorder(
                //        borderRadius: BorderRadius.circular(16),
                //      ),
                //    ),
                //    onPressed: () => _showStatusBottomSheet(report),
                //    icon: const Icon(Icons.edit_note_rounded),
                //    label: Text(
                //      "Cambiar estado",
                //      style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                //    ),
                //  ),
                //),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

void _showAdminEmailDialog(SupportReport report) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  final Color titleColor =
      isDark ? Colors.white : const Color(0xFF243447);

  final Color bodyColor =
      isDark ? Colors.white70 : const Color(0xFF52616F);

  final Color fieldColor = isDark
      ? Colors.white.withOpacity(0.055)
      : const Color(0xFFF7FAFC);

  final Color borderColor = isDark
      ? Colors.white.withOpacity(0.08)
      : const Color(0xFFE7EEF4);

  final subjectController = TextEditingController(
    text: report.status == "Cerrado"
        ? "Tu reporte fue resuelto - SeaBot"
        : "Actualización de tu reporte - SeaBot",
  );

  final messageController = TextEditingController(
    text: report.status == "Cerrado"
        ? "Hola, tu reporte ha sido revisado y marcado como resuelto. Gracias por ayudarnos a mejorar SeaBot."
        : "Hola, estamos revisando tu reporte. Te informaremos cuando tengamos una actualización.",
  );

  String selectedStatus = report.status;
  bool sending = false;

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.50),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> sendEmail() async {
            final subject = subjectController.text.trim();
            final message = messageController.text.trim();

            if (subject.isEmpty || message.isEmpty) {
              _showSnackBar(
                message: "Completa el asunto y el mensaje.",
                color: Colors.orange,
              );
              return;
            }

            setDialogState(() {
              sending = true;
            });

            try {
              await _supportReportService.sendAdminEmailToUser(report.id, {
                "subject": subject,
                "message": message,
                "status": selectedStatus,
              });

              if (!mounted) return;

              Navigator.pop(dialogContext);

              _showSnackBar(
                message: "Correo enviado correctamente al usuario.",
                color: Colors.green,
              );

              await _refreshReports();
            } catch (e) {
              if (!mounted) return;

              final errorText = e.toString().replaceFirst("Exception: ", "");

              setDialogState(() {
                sending = false;
              });

              _showSnackBar(
                message: errorText,
                color: Colors.redAccent,
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
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF171B22).withOpacity(0.98)
                        : Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.30 : 0.10),
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 20, 14, 18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.95),
                                AppColors.secundary.withOpacity(0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.24),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.mark_email_read_rounded,
                                  color: Colors.white,
                                  size: 27,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Actualizar reporte",
                                      style: GoogleFonts.manrope(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Notifica al usuario sobre el avance de su caso",
                                      style: GoogleFonts.manrope(
                                        fontSize: 12.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withOpacity(0.90),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: sending
                                    ? null
                                    : () => Navigator.pop(dialogContext),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primary,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "El correo se enviará al estudiante asociado a este reporte.",
                                        style: GoogleFonts.manrope(
                                          fontSize: 12.8,
                                          height: 1.4,
                                          fontWeight: FontWeight.w600,
                                          color: bodyColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "Nuevo estado",
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: fieldColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    dropdownColor: isDark
                                        ? const Color(0xFF1D232D)
                                        : Colors.white,
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: isDark
                                          ? Colors.white70
                                          : const Color(0xFF52616F),
                                    ),
                                    items: _statusOptions.map((status) {
                                      final color = _getStatusColor(status);

                                      return DropdownMenuItem<String>(
                                        value: status,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 9,
                                              height: 9,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              status,
                                              style: GoogleFonts.manrope(
                                                fontWeight: FontWeight.w700,
                                                color: titleColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: sending
                                        ? null
                                        : (value) {
                                            if (value == null) return;

                                            setDialogState(() {
                                              selectedStatus = value;

                                              if (value == "Cerrado") {
                                                subjectController.text =
                                                    "Tu reporte fue resuelto - SeaBot";
                                                messageController.text =
                                                    "Hola, tu reporte ha sido revisado y marcado como resuelto. Gracias por ayudarnos a mejorar SeaBot.";
                                              } else if (value ==
                                                  "En proceso") {
                                                subjectController.text =
                                                    "Actualización de tu reporte - SeaBot";
                                                messageController.text =
                                                    "Hola, estamos revisando tu reporte. Te informaremos cuando tengamos una actualización.";
                                              } else {
                                                subjectController.text =
                                                    "Reporte recibido - SeaBot";
                                                messageController.text =
                                                    "Hola, hemos recibido tu reporte y será revisado por el equipo de soporte de SeaBot.";
                                              }
                                            });
                                          },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "Asunto",
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: subjectController,
                                enabled: !sending,
                                style: GoogleFonts.manrope(
                                  color: titleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: fieldColor,
                                  hintText: "Asunto del correo",
                                  hintStyle: GoogleFonts.manrope(
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF8A9AA9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.65),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                "Mensaje",
                                style: GoogleFonts.manrope(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                controller: messageController,
                                enabled: !sending,
                                maxLines: 6,
                                maxLength: 800,
                                style: GoogleFonts.manrope(
                                  color: titleColor,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Escribe el mensaje para el usuario...",
                                  hintStyle: GoogleFonts.manrope(
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF8A9AA9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  counterStyle: GoogleFonts.manrope(
                                    color: isDark
                                        ? Colors.white38
                                        : const Color(0xFF8A9AA9),
                                  ),
                                  filled: true,
                                  fillColor: fieldColor,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 14,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: borderColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: AppColors.primary.withOpacity(0.65),
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: bodyColor,
                                        side: BorderSide(color: borderColor),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: sending
                                          ? null
                                          : () => Navigator.pop(dialogContext),
                                      child: Text(
                                        "Cancelar",
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppColors.secundary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      onPressed: sending ? null : sendEmail,
                                      icon: sending
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(Icons.send_rounded),
                                      label: Text(
                                        sending ? "Enviando..." : "Enviar",
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


  Widget _buildStatusBadge({required String status, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: GoogleFonts.manrope(
          fontSize: 11.8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(child: CircularProgressIndicator(color: AppColors.secundary));
  }

  Widget _buildEmptyState(bool isDark) {
    return RefreshIndicator(
      onRefresh: _refreshReports,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 72,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 18),
          Text(
            "No hay reportes registrados",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF18202A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Cuando los usuarios envíen incidencias, reclamos o sugerencias, aparecerán aquí.",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({required bool isDark, required String error}) {
    final cleanError = error.replaceFirst("Exception: ", "");

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF171C24)
                : Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
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
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                "No se pudieron cargar los reportes",
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF18202A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                cleanError,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13.5,
                  height: 1.45,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secundary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _refreshReports,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  "Reintentar",
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
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
}
