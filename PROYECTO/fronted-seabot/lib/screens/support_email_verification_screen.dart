import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/services/support_report_service.dart';

class SupportEmailVerificationScreen extends StatefulWidget {
  const SupportEmailVerificationScreen({super.key});

  @override
  State<SupportEmailVerificationScreen> createState() =>
      _SupportEmailVerificationScreenState();
}

class _SupportEmailVerificationScreenState
    extends State<SupportEmailVerificationScreen> {
  final SupportReportService _supportService = SupportReportService();
  final TextEditingController _codeController = TextEditingController();

  bool _sendingCode = false;
  bool _verifyingCode = false;
  bool _codeSent = false;

  String? _correoDestino;
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
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

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
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

  Future<void> _sendCode() async {
    final hasInternet = await _hasInternet();

    if (!mounted) return;

    if (!hasInternet) {
      _showSnackBar(
        message: "No tienes conexión a internet.",
        color: Colors.redAccent,
      );
      return;
    }

    if (AppData.studentID == 0) {
      _showSnackBar(
        message: "No se encontró el identificador del estudiante.",
        color: Colors.redAccent,
      );
      return;
    }

    setState(() {
      _sendingCode = true;
    });

    try {
      final response = await _supportService.sendEmailVerificationCode({
        "student_id": AppData.studentID,
      });

      if (!mounted) return;

      setState(() {
        _codeSent = true;
        _correoDestino = response.correo;
      });

      _startTimer();

      _showSnackBar(
        message:
            "Te enviamos un código de verificación. Si no lo recibes, revisa que tu correo esté escrito correctamente en tu perfil.",
        color: AppColors.secundary,
      );
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().replaceFirst("Exception: ", "");

      _showSnackBar(message: errorText, color: Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _sendingCode = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final codigo = _codeController.text.trim();

    if (codigo.isEmpty) {
      _showSnackBar(
        message: "Ingresa el código recibido en tu correo.",
        color: Colors.orange,
      );
      return;
    }

    if (codigo.length < 4) {
      _showSnackBar(
        message: "El código ingresado no es válido.",
        color: Colors.orange,
      );
      return;
    }

    final hasInternet = await _hasInternet();

    if (!mounted) return;

    if (!hasInternet) {
      _showSnackBar(
        message: "No tienes conexión a internet.",
        color: Colors.redAccent,
      );
      return;
    }

    setState(() {
      _verifyingCode = true;
    });

    try {
      final response = await _supportService.verifyEmailCode({
        "student_id": AppData.studentID,
        "codigo": codigo,
      });

      if (!mounted) return;

      _showSnackBar(
        message: response.message.isNotEmpty
            ? response.message
            : "Correo verificado correctamente.",
        color: Colors.green,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      final errorText = e.toString().replaceFirst("Exception: ", "");

      _showSnackBar(message: errorText, color: Colors.redAccent);
    } finally {
      if (mounted) {
        setState(() {
          _verifyingCode = false;
        });
      }
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
            top: 210,
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                    child: Column(
                      children: [
                        _buildInfoCard(isDark),
                        const SizedBox(height: 18),
                        _buildVerificationCard(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 20, 24),
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
          Row(
            children: [
              IconButton(
                onPressed: _sendingCode || _verifyingCode
                    ? null
                    : () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
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
                      "Verificar correo",
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Confirma tu correo para usar soporte",
                      style: GoogleFonts.manrope(
                        color: Colors.white.withOpacity(0.92),
                        fontSize: 13.5,
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

  Widget _buildInfoCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Validación por código OTP",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF18202A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Te enviaremos un código temporal a tu correo registrado. Ingresa el código recibido para confirmar que el correo te pertenece.",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 14.2,
              height: 1.55,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_correoDestino != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secundary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _correoDestino!,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secundary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationCard(bool isDark) {
    final canResend = _secondsRemaining == 0 && !_sendingCode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Paso 1",
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secundary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _sendingCode || !canResend ? null : _sendCode,
              icon: _sendingCode
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
                _secondsRemaining > 0
                    ? "Reenviar código en ${_secondsRemaining}s"
                    : (_codeSent ? "Reenviar código" : "Enviar código"),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            "Paso 2",
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            enabled: !_verifyingCode,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF18202A),
            ),
            decoration: InputDecoration(
              hintText: "------",
              hintStyle: GoogleFonts.manrope(
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              counterText: "",
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : const Color(0xFFF4F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: _verifyingCode ? null : _verifyCode,
              child: _verifyingCode
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      "Verificar correo",
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "Si no recibes el código, revisa que tu correo esté escrito correctamente en tu perfil.",
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              height: 1.45,
              color: isDark ? Colors.white54 : Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF171C24) : Colors.white.withOpacity(0.95),
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
