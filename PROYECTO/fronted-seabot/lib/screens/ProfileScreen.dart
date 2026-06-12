import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:seabot/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/student.dart';
import 'package:seabot/repositories/student_repository.dart';
import 'package:seabot/services/student_service.dart';
import 'package:provider/provider.dart';
import 'package:seabot/theme/theme_notifier.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  int studentID = AppData.studentID;
  final TextEditingController _controllerAlias = TextEditingController();
  final TextEditingController _controllerSafeContact = TextEditingController();
  final TextEditingController _controllerCorreo = TextEditingController();
  final StudentService serviceController = StudentService();
  final StudentRepository repository = StudentRepository();
  late Future<Student?> perfil;

  String _originalAlias = "";
  String _originalContacto = "";
  String _originalCorreo = "";

  String _avatar = "😀";
  bool? _notificaciones;
  bool _notificacionPruebaActiva = false;

  final List<String> _avatarImages = [
    'assets/avatars/avatar1.png',
    'assets/avatars/avatar2.png',
    'assets/avatars/avatar3.png',
    'assets/avatars/avatar4.png',
    'assets/avatars/avatar5.png',
    'assets/avatars/avatar6.png',
    'assets/avatars/avatar7.png',
    'assets/avatars/avatar8.png',
    'assets/avatars/avatar9.png',
    'assets/avatars/avatar10.png',
  ];

  final List<String> _avatares = [
    "👽",
    "😺",
    "🐵",
    "🐶",
    "🐼",
    "🐺",
    "🦝",
    "🦊",
    "🐯",
    "🦁",
    "🐱",
    "🐮",
    "🐷",
    "🐭",
    "🐰",
    "🐹",
    "🐸",
    "🐨",
    "🐻‍❄️",
    "🐻",
    "🐧",
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    perfil = Future.value();
    _loadResult();
    _cargarPreferenciasLocales();
    _cargarEstadoNotificacionPrueba();
    _cargarAvatarLocal();

    _controllerAlias.addListener(_onFormChanged);
    _controllerSafeContact.addListener(_onFormChanged);
    _controllerCorreo.addListener(_onFormChanged);
  }

  Future<void> _cargarEstadoNotificacionPrueba() async {
    final pending = await NotificationService.isTestNotificationPending();

    if (!mounted) return;
    setState(() {
      _notificacionPruebaActiva = pending;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controllerAlias.dispose();
    _controllerSafeContact.dispose();
    _controllerCorreo.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _cargarPreferenciasLocales();
      _cargarEstadoNotificacionPrueba();
    }
  }

  void _onFormChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadResult() async {
    bool online = await _hasInternet();
    if (!mounted) return;
    setState(() {
      perfil = repository.fetchAndSyncStudent(studentID, online);
    });
  }

  Future<void> _cargarAvatarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarGuardado = prefs.getString('selected_avatar');
    if (avatarGuardado != null && mounted) {
      setState(() {
        _avatar = avatarGuardado;
      });
    }
  }

  Future<void> _cargarPreferenciasLocales() async {
    final enabled =
        await NotificationService.syncNotificationPreferenceWithPermission(
          rescheduleIfEnabled: true,
        );

    if (!mounted) return;
    setState(() {
      _notificaciones = enabled;
    });
  }

  Future<void> _guardarPreferenciaNotificaciones(bool valor) async {
    await NotificationService.setNotificationsPreference(valor);
  }

  void _mostrarSnackNotificaciones({
    required String message,
    required Color color,
  }) {
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

  Future<void> _onNotificationsChanged(bool enabled) async {
    if (!enabled) {
      await _guardarPreferenciaNotificaciones(false);
      await NotificationService.cancelDailyNotifications();

      if (!mounted) return;
      setState(() => _notificaciones = false);
      _mostrarSnackNotificaciones(
        message: "Notificaciones desactivadas",
        color: Colors.orangeAccent,
      );
      return;
    }

    final permissionGranted =
        await NotificationService.requestNotificationPermission();

    if (!permissionGranted) {
      await _guardarPreferenciaNotificaciones(false);
      await NotificationService.cancelDailyNotifications();

      if (!mounted) return;
      setState(() => _notificaciones = false);
      _mostrarSnackNotificaciones(
        message:
            "No se activaron las notificaciones. Habilita los permisos de notificación desde la configuración del dispositivo.",
        color: Colors.redAccent,
      );
      return;
    }

    await _guardarPreferenciaNotificaciones(true);
    await NotificationService.scheduleDefaultDailyNotifications();
    await NotificationService.showNotification(
      title: 'Notificaciones activadas',
      body: 'Recibirás recordatorios a las 9:00 AM, 1:00 PM y 8:00 PM.',
    );

    if (!mounted) return;
    setState(() => _notificaciones = true);
    _mostrarSnackNotificaciones(
      message:
          "Notificaciones activadas\nRecibirás recordatorios a las 9:00 AM, 1:00 PM y 8:00 PM.",
      color: Colors.green,
    );
  }

  Future<bool> _hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _hasChanges() {
    return _controllerAlias.text.trim() != _originalAlias ||
        _controllerSafeContact.text.trim() != _originalContacto ||
        _controllerCorreo.text.trim() != _originalCorreo;
  }

  Future<void> _onSavePressed() async {
    final connected = await _hasInternet();

    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📵 No tienes conexión a internet",
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
    await _modificarperfil();
  }

  Future<void> _cambiarAvatar(String nuevoAvatar) async {
    final connected = await _hasInternet();

    if (!mounted) return;

    if (!connected) {
      // Cierra la ventana de selección de avatar
      Navigator.pop(context);

      // Espera un momento para que el modal se cierre visualmente
      await Future.delayed(const Duration(milliseconds: 200));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No tienes conexión a internet. No se pudo actualizar el avatar.",
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

    setState(() => _avatar = nuevoAvatar);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_avatar', nuevoAvatar);

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Avatar actualizado correctamente",
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
  }

  void _mostrarSelectorAvatares() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) {
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
                width: double.maxFinite,
                height: 420,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.30 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 14, 10),
                        child: Row(
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
                                Icons.face_retouching_natural_rounded,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "Selecciona tu avatar",
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.black.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TabBar(
                            isScrollable:
                                false, // 🔥 CLAVE → divide el espacio en partes iguales
                            indicatorSize: TabBarIndicatorSize
                                .tab, // 🔥 el indicador ocupa TODO el tab

                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secundary,
                                ],
                              ),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: isDark
                                ? Colors.white70
                                : Colors.black54,
                            labelStyle: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                            ),
                            tabs: const [
                              Tab(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.emoji_emotions),
                                    SizedBox(height: 2),
                                    Text("Emojis"),
                                  ],
                                ),
                              ),
                              Tab(icon: Icon(Icons.image), text: "Imágenes"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Reemplaza el contenido de tu primer hijo en el TabBarView
                            SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: GridView.builder(
                                shrinkWrap:
                                    true, // Importante para que funcione dentro de ScrollView
                                physics:
                                    const NeverScrollableScrollPhysics(), // El scroll lo maneja el SingleChildScrollView
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  18,
                                ),
                                itemCount: _avatares.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          3, // 👈 Igualamos a las imágenes para consistencia visual
                                      mainAxisSpacing: 20,
                                      crossAxisSpacing: 20,
                                    ),
                                itemBuilder: (context, index) {
                                  final emoji = _avatares[index];
                                  final isSelected = _avatar == emoji;

                                  return GestureDetector(
                                    onTap: () => _cambiarAvatar(emoji),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 220,
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? AppColors.primary.withOpacity(
                                                0.12,
                                              )
                                            : (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.05,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.03,
                                                    )),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                          width: 2.5,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.2),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(
                                            fontSize: 32,
                                          ), // Un poco más grande para mejor legibilidad
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            GridView.builder(
                              padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                              itemCount: _avatarImages.length,
                              physics: const ClampingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                  ),
                              itemBuilder: (context, index) {
                                final path = _avatarImages[index];
                                final isSelected = _avatar == path;
                                return GestureDetector(
                                  onTap: () => _cambiarAvatar(path),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppColors.primary
                                                    .withOpacity(0.22),
                                                blurRadius: 14,
                                                offset: const Offset(0, 8),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundImage: AssetImage(path),
                                    ),
                                  ),
                                );
                              },
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
  }

  Future<void> _modificarperfil() async {
    final alias = _controllerAlias.text.trim();
    final contacto = _controllerSafeContact.text.trim();
    final correo = _controllerCorreo.text.trim();

    final aliasRegex = RegExp(r'^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ_ ]+$');

    if (!aliasRegex.hasMatch(alias)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El alias solo puede contener letras, números, espacios y guion bajo",
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

    if (alias.isEmpty || contacto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ Completa todos los campos",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!correo.contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Correo inválido",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Map<String, dynamic> resultResponse = {
      "alias": alias,
      "safe_contact": contacto,
      "correo": correo,
    };

    try {
      await serviceController.updateStudent(studentID, resultResponse);

      _originalAlias = alias;
      _originalContacto = contacto;
      _originalCorreo = correo;

      setState(() {}); // 🔥 refresca UI (oculta botón)

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Perfil actualizado correctamente",
            style: GoogleFonts.manrope(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: AppColors.secundary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Error al actualizar el perfil",
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

  //Prueba
  Future<void> _onTestNotificationChanged(bool enabled) async {
    if (!enabled) {
      await NotificationService.cancelTestNotification();

      if (!mounted) return;
      setState(() => _notificacionPruebaActiva = false);

      _mostrarSnackNotificaciones(
        message: "Prueba de notificación cancelada",
        color: Colors.orangeAccent,
      );
      return;
    }

    final permissionGranted =
        await NotificationService.requestNotificationPermission();

    if (!permissionGranted) {
      await NotificationService.cancelTestNotification();

      if (!mounted) return;
      setState(() => _notificacionPruebaActiva = false);

      _mostrarSnackNotificaciones(
        message:
            "No se pudo programar la prueba. Habilita los permisos de notificación en la tablet.",
        color: Colors.redAccent,
      );
      return;
    }

    await NotificationService.scheduleTestNotificationAfter(seconds: 10);
    await NotificationService.scheduleTestNotificationAtFiveFifteen();

    final pending = await NotificationService.isTestNotificationPending();

    if (!mounted) return;
    setState(() => _notificacionPruebaActiva = pending);

    _mostrarSnackNotificaciones(
      message: "Pruebas programadas: una en 10 segundos y otra a las 5:10 PM",
      color: Colors.green,
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

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _hasChanges()
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _onSavePressed,
                    icon: const Icon(Icons.save_rounded),
                    label: Text(
                      "Guardar cambios",
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secundary,
                      foregroundColor: Colors.white,
                      elevation: 10,
                      shadowColor: AppColors.secundary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,

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
            top: 200,
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
                  title: "Mi perfil",
                  subtitle: "Gestiona tu información",
                ),
                Expanded(
                  child: FutureBuilder<Student?>(
                    future: perfil,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final student = snapshot.data;

                      if (student != null) {
                        if (_originalAlias.isEmpty) {
                          _originalAlias = student.alias ?? "";
                          _originalContacto = student.safeContact ?? "";
                          _originalCorreo = student.correo ?? "";

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;

                            _controllerAlias.text = _originalAlias;
                            _controllerSafeContact.text = _originalContacto;
                            _controllerCorreo.text = _originalCorreo;

                            setState(() {});
                          });
                        }
                      }
                      return ListView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                        children: [
                          _buildProfileHeroCard(isDark, isLoading, student),
                          const SizedBox(height: 18),

                          _buildSectionTitle("Información personal", isDark),
                          const SizedBox(height: 12),
                          _buildCard(
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildPremiumField(
                                  context: context,
                                  controller: _controllerAlias,
                                  label: "Alias",
                                  icon: Icons.person_rounded,
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[a-zA-Z0-9áéíóúÁÉÍÓÚñÑ_ ]'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildPremiumField(
                                  context: context,
                                  controller: _controllerSafeContact,
                                  label: "Contacto seguro",
                                  icon: Icons.contact_phone_rounded,
                                  maxLength: 9,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildPremiumField(
                                  context: context,
                                  controller: _controllerCorreo,
                                  label: "Correo",
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildSectionTitle("Preferencias", isDark),
                          const SizedBox(height: 12),
                          _buildCard(
                            isDark: isDark,
                            child: Column(
                              children: [
                                _buildSwitchTile(
                                  isDark: isDark,
                                  icon: Icons.dark_mode_rounded,
                                  iconColor: const Color(0xFF7C4DFF),
                                  title: "Tema oscuro",
                                  subtitle:
                                      "Personaliza la apariencia de la app",
                                  value: context
                                      .watch<ThemeNotifier>()
                                      .isDarkMode,
                                  onChanged: (val) {
                                    context.read<ThemeNotifier>().toggleTheme(
                                      val,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          val
                                              ? "🌙 Tema oscuro activado"
                                              : "☀️ Tema claro activado",
                                          style: GoogleFonts.manrope(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        backgroundColor: val
                                            ? AppColors.secondaryDark
                                            : AppColors.primary,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildDivider(isDark),
                                _buildSwitchTile(
                                  isDark: isDark,
                                  icon: Icons.notifications_rounded,
                                  iconColor: Colors.orange,
                                  title: "Recibir notificaciones",
                                  subtitle:
                                      "Recordatorios diarios de bienestar",
                                  value: _notificaciones ?? false,
                                  onChanged: (val) async {
                                    await _onNotificationsChanged(val);
                                  },
                                ),

                               // _buildDivider(isDark),
                               // _buildSwitchTile(
                               //   isDark: isDark,
                               //   icon: Icons.timer_rounded,
                               //   iconColor: Colors.blueAccent,
                               //   title: "Prueba de notificación",
                               //   subtitle:
                               //       "Programa una notificación en segundos",
                               //   value: _notificacionPruebaActiva,
                               //   onChanged: (val) async {
                               //     await _onTestNotificationChanged(val);
                               //   },
                               // ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          const SizedBox(height: 24),
                          const SizedBox(height: 24),
                          //SizedBox(
                          //  width: double.infinity,
                          //  child: FilledButton.icon(
                          //    onPressed: _onSavePressed,
                          //    icon: const Icon(Icons.save_rounded),
                          //    label: Text(
                          //      "Guardar cambios",
                          //      style: GoogleFonts.manrope(
                          //        fontSize: 15,
                          //        fontWeight: FontWeight.w800,
                          //      ),
                          //    ),
                          //    style: FilledButton.styleFrom(
                          //      backgroundColor: AppColors.secundary,
                          //      foregroundColor: Colors.white,
                          //      elevation: 0,
                          //      padding: const EdgeInsets.symmetric(
                          //        vertical: 16,
                          //      ),
                          //      shape: RoundedRectangleBorder(
                          //        borderRadius: BorderRadius.circular(18),
                          //      ),
                          //    ),
                          //  ),
                          //),
                          if (!isLoading && student == null) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                "No se encontraron datos del perfil.",
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ],
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
          child: const SizedBox.expand(),
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

  Widget _buildProfileHeroCard(bool isDark, bool isLoading, Student? student) {
    final displayAlias = _controllerAlias.text.isNotEmpty
        ? _controllerAlias.text
        : (student?.alias?.isNotEmpty == true ? student!.alias! : "Tu alias");

    final displayEmail = _controllerCorreo.text.isNotEmpty
        ? _controllerCorreo.text
        : (student?.correo?.isNotEmpty == true
              ? student!.correo!
              : "correo@ejemplo.com");

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF171C24)
            : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(28),
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
        children: [
          GestureDetector(
            onTap: _mostrarSelectorAvatares,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secundary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _avatar.contains('assets/avatars/')
                      ? CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          backgroundImage: AssetImage(_avatar),
                        )
                      : CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.white,
                          child: Text(
                            _avatar,
                            style: const TextStyle(fontSize: 42),
                          ),
                        ),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.secundary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const CircularProgressIndicator()
          else ...[
            Text(
              displayAlias,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF18202A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayEmail,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

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

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: iconColor, size: 25),
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
                  color: isDark ? Colors.white : const Color(0xFF18202A),
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
        Switch(
          value: value,
          activeColor: AppColors.secondaryDark,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.06),
      ),
    );
  }

  Widget _buildPremiumField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formatters = <TextInputFormatter>[
      if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      if (inputFormatters != null) ...inputFormatters,
    ];

    return TextField(
      controller: controller,
      maxLength: maxLength,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
      inputFormatters: formatters,
      keyboardType: keyboardType,
      style: GoogleFonts.manrope(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white : const Color(0xFF18202A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.04)
            : const Color(0xFFF7F9FC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
