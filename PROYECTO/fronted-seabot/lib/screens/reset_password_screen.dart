import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/screens/login_screen.dart';
import 'package:seabot/services/user_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String correo;

  const ResetPasswordScreen({
    super.key,
    required this.correo,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final UserService _userService = UserService();

  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  Future<bool> _hasInternet() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;

    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _floatController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate() || _loading) return;

    FocusScope.of(context).unfocus();

    final connected = await _hasInternet();
    if (!mounted) return;

    if (!connected) {
      _showCustomSnackBar(
        message: "No tienes conexión a internet",
        color: const Color(0xFFE57373),
        icon: Icons.wifi_off_rounded,
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final message = await _userService.resetPassword(
        _codigoController.text.trim(),
        _newPasswordController.text.trim(),
      );

      if (!mounted) return;

      _showCustomSnackBar(
        message: message,
        color: const Color(0xFF49C9B0),
        icon: Icons.check_circle_outline_rounded,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenUser()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = "No se pudo actualizar la contraseña.";
      final errorText = e.toString().toLowerCase();

      if (errorText.contains("400")) {
        errorMessage = "Código inválido o expirado.";
      }

      _showCustomSnackBar(
        message: errorMessage,
        color: const Color(0xFFE57373),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showCustomSnackBar({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color mainTextColor =
        isDark ? AppColors.textDark : const Color(0xFF213547);

    final Color secondaryTextColor =
        isDark ? AppColors.subtitleDark : const Color(0xFF4F6475);

    final List<Color> lightGradient = const [
      AppColors.secundary,
      Color(0xFF9FE2D4),
      Color(0xFFF9FAFB),
      Color(0xFFA3D5F4),
    ];

    final List<Color> darkGradient = const [
      Color(0xFF222E3A),
      Color(0xFF2A3D4F),
      Color(0xFF324A5F),
      Color(0xFF253746),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark ? darkGradient : lightGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            _ResetBackgroundBlobs(isDark: isDark),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: child,
                        );
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          children: [
                            _ResetHeader(
                              isDark: isDark,
                              correo: widget.correo,
                              mainTextColor: mainTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            const SizedBox(height: 28),
                            _ResetGlassCard(
                              formKey: _formKey,
                              codigoController: _codigoController,
                              newPasswordController: _newPasswordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              isDark: isDark,
                              isLoading: _loading,
                              showPassword: _showPassword,
                              showConfirmPassword: _showConfirmPassword,
                              onTogglePassword: () {
                                setState(() => _showPassword = !_showPassword);
                              },
                              onToggleConfirmPassword: () {
                                setState(() => _showConfirmPassword =
                                    !_showConfirmPassword);
                              },
                              onSubmit: _resetPassword,
                            ),
                            const SizedBox(height: 20),
                            _BackResetLink(
                              isDark: isDark,
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
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

class _ResetHeader extends StatelessWidget {
  final bool isDark;
  final String correo;
  final Color mainTextColor;
  final Color secondaryTextColor;

  const _ResetHeader({
    required this.isDark,
    required this.correo,
    required this.mainTextColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(isDark ? 0.08 : 0.14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.05 : 0.14),
                blurRadius: 26,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF49C9B0).withOpacity(isDark ? 0.12 : 0.18),
                blurRadius: 36,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.12 : 0.24),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.white.withOpacity(0.08),
                            Colors.white.withOpacity(0.03),
                          ]
                        : [
                            Colors.white.withOpacity(0.30),
                            Colors.white.withOpacity(0.10),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    "assets/images/SeaBot.png",
                    height: 72,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          "Nueva contraseña",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: mainTextColor,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.9,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Hemos enviado un código a:",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: secondaryTextColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.48),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.40),
            ),
          ),
          child: Text(
            correo,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: isDark ? AppColors.textDark : const Color(0xFF2A3D4F),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetGlassCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController codigoController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool isDark;
  final bool isLoading;
  final bool showPassword;
  final bool showConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final VoidCallback onSubmit;

  const _ResetGlassCard({
    required this.formKey,
    required this.codigoController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.isDark,
    required this.isLoading,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor =
        isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.72);

    final Color borderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.white.withOpacity(0.42);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: cardColor,
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.16 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                _PremiumResetField(
                  controller: codigoController,
                  label: "Código de verificación",
                  hint: "Ingresa el código",
                  icon: Icons.verified_user_outlined,
                  keyboardType: TextInputType.number,
                  isDark: isDark,
                  validator: (value) {
                    final codigo = value?.trim() ?? "";
                    if (codigo.isEmpty) return "Ingrese el código";
                    if (codigo.length < 6) return "Código inválido";
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _PremiumResetField(
                  controller: newPasswordController,
                  label: "Nueva contraseña",
                  hint: "Ingresa tu nueva contraseña",
                  icon: Icons.lock_outline_rounded,
                  obscureText: !showPassword,
                  isDark: isDark,
                  suffixIcon: IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: isDark
                          ? AppColors.subtitleDark
                          : const Color(0xFF50697C),
                    ),
                  ),
                  validator: (value) {
                    final pass = value?.trim() ?? "";
                    if (pass.isEmpty) return "Ingrese una nueva contraseña";
                    if (pass.length < 4) {
                      return "Debe tener al menos 4 caracteres";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                _PremiumResetField(
                  controller: confirmPasswordController,
                  label: "Confirmar contraseña",
                  hint: "Vuelve a escribir la contraseña",
                  icon: Icons.lock_reset_outlined,
                  obscureText: !showConfirmPassword,
                  isDark: isDark,
                  suffixIcon: IconButton(
                    onPressed: onToggleConfirmPassword,
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      color: isDark
                          ? AppColors.subtitleDark
                          : const Color(0xFF50697C),
                    ),
                  ),
                  validator: (value) {
                    final confirm = value?.trim() ?? "";
                    if (confirm.isEmpty) return "Confirme la contraseña";
                    if (confirm != newPasswordController.text.trim()) {
                      return "Las contraseñas no coinciden";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF49C9B0),
                          Color(0xFF7FDAC7),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF49C9B0).withOpacity(0.24),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Actualizar contraseña",
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
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
    );
  }
}

class _PremiumResetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _PremiumResetField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final Color enabledBorderColor = isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFFD7E3EA);

    final Color fillColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.white.withOpacity(0.92);

    final Color textColor =
        isDark ? AppColors.textDark : const Color(0xFF243746);

    final Color hintColor =
        isDark ? AppColors.subtitleDark : const Color(0xFF8A9BA8);

    final Color iconColor =
        isDark ? AppColors.subtitleDark : const Color(0xFF4F6C7E);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : const Color(0xFF304656),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: hintColor,
              fontSize: 14,
            ),
            prefixIcon: Icon(icon, color: iconColor),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: enabledBorderColor,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF49C9B0),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFE57373),
                width: 1.4,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFFE57373),
                width: 1.6,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ],
    );
  }
}

class _BackResetLink extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _BackResetLink({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.subtitleDark : const Color(0xFF2A3D4F);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              "Volver",
              style: GoogleFonts.inter(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetBackgroundBlobs extends StatelessWidget {
  final bool isDark;

  const _ResetBackgroundBlobs({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -90,
          left: -50,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDark ? 0.05 : 0.12),
            ),
          ),
        ),
        Positioned(
          right: -80,
          top: 120,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDark ? 0.04 : 0.08),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: 10,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(isDark ? 0.03 : 0.06),
            ),
          ),
        ),
      ],
    );
  }
}