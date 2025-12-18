import 'dart:io';
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


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int studentID = AppData.studentID;
  final TextEditingController _controllerAlias = TextEditingController();
  final TextEditingController _controllerSafeContact = TextEditingController();
  final StudentService serviceController = StudentService();
  final StudentRepository repository = StudentRepository();
  late Future<Student?> perfil;

  String _avatar = "😀";
  bool? _notificaciones;

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

  @override
  void initState() {
    super.initState();
    perfil = Future.value();
    _loadResult();
    _cargarPreferenciasLocales();
    _cargarAvatarLocal();
  }

  Future<void> _loadResult() async {
    bool online = await _hasInternet();
    setState(() {
      perfil = repository.fetchAndSyncStudent(studentID, online);
    });
  }

  Future<void> _cargarAvatarLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarGuardado = prefs.getString('selected_avatar');
    if (avatarGuardado != null) {
      setState(() {
        _avatar = avatarGuardado;
      });
    }
  }

  Future<void> _cargarPreferenciasLocales() async {
    bool valorGuardado = await _leerPreferenciaNotificaciones();
    setState(() {
      _notificaciones = valorGuardado;
    });
  }

  Future<void> _guardarPreferenciaNotificaciones(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', valor);
  }

  Future<bool> _leerPreferenciaNotificaciones() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? false;
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

  Future<void> _onSavePressed() async {
    final connected = await _hasInternet();

    if (!connected) {
      if (!mounted) return;
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
    await _modificarperfil();
  }

  final List<String> _avatares = [
    "😀",
    "😎",
    "🤗",
    "🤓",
    "🐼",
    "🦊",
    "😃",
    "🥰",
    "😴",
    "🥳",
  ];

  void _cambiarAvatar(String nuevoAvatar) async {
    setState(() => _avatar = nuevoAvatar);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_avatar', nuevoAvatar);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "✅ Avatar actualizado correctamente",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarSelectorAvatares() {
    showDialog(
      context: context,
      builder: (_) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Text(
            "Selecciona tu avatar",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: DefaultTabController(
            length: 2,
            child: SizedBox(
              width: double.maxFinite,
              height: 360, // ✅ Altura fija del contenido
              child: Column(
                children: [
                  TabBar(
                    labelColor: theme.colorScheme.primary,
                    indicatorColor: theme.colorScheme.secondary,
                    tabs: const [
                      Tab(icon: Icon(Icons.emoji_emotions), text: "Emojis"),
                      Tab(icon: Icon(Icons.image), text: "Imágenes"),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ✅ El contenido del TabBarView debe tener un tamaño fijo también
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 🟢 TAB 1 - EMOJIS
                        SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _avatares
                                .map(
                                  (emoji) => GestureDetector(
                                    onTap: () => _cambiarAvatar(emoji),
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 26),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),

                        // 🟣 TAB 2 - IMÁGENES
                        SizedBox(
                          height: 300, // ✅ Fija la altura del GridView
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _avatarImages.length,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                ),
                            itemBuilder: (context, index) {
                              final path = _avatarImages[index];
                              return GestureDetector(
                                onTap: () => _cambiarAvatar(path),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(path),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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

  Future<void> _modificarperfil() async {
    final alias = _controllerAlias.text.trim();
    final contacto = _controllerSafeContact.text.trim();
    if (alias.isEmpty || contacto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Completa todos los campos")),
      );
      return;
    }

    Map<String, dynamic> resultResponse = {
      "alias": alias,
      "safe_contact": contacto,
    };

    try {
      await serviceController.updateStudent(studentID, resultResponse);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Perfil actualizado correctamente",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.secundary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Error al actualizar el perfil",
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Perfil",
          style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secundary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🧍 Avatar y Alias
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _mostrarSelectorAvatares,
                    child: _avatar.contains('assets/avatars/')
                        ? CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(_avatar),
                          )
                        : CircleAvatar(
                            radius: 40,
                            backgroundColor: theme.colorScheme.secondary
                                .withOpacity(0.2),
                            child: Text(
                              _avatar,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),

                  // 🔹 Alias sin contador visual
                  FutureBuilder<Student?>(
                    future: perfil,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (!snapshot.hasData) {
                        return Text(
                          "No hay datos",
                          style: baseTextStyle.bodyMedium,
                        );
                      }

                      final student = snapshot.data!;
                      _controllerAlias.text = _controllerAlias.text.isEmpty
                          ? student.alias ?? ""
                          : _controllerAlias.text;

                      return TextField(
                        controller: _controllerAlias,
                        maxLength: 20,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null, // ✅ Sin contador visible
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(
                            20,
                          ), // ✅ bloquea más de 20
                        ],
                        style: baseTextStyle.bodyMedium,
                        decoration: InputDecoration(
                          labelText: "Alias",
                          labelStyle: baseTextStyle.bodyMedium,
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🌙 Tema oscuro
            SwitchListTile(
              title: Text("Tema oscuro", style: baseTextStyle.bodyLarge),
              secondary: Icon(Icons.dark_mode, color: theme.iconTheme.color),
              value: context.watch<ThemeNotifier>().isDarkMode,
              activeColor: AppColors.secondaryDark,
              onChanged: (val) {
                context.read<ThemeNotifier>().toggleTheme(val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? "🌙 Tema oscuro activado"
                          : "☀️ Tema claro activado",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: val
                        ? AppColors.secondaryDark
                        : AppColors.primary,
                  ),
                );
              },
            ),

            // 🔔 Notificaciones
            SwitchListTile(
              title: Text(
                "Recibir notificaciones",
                style: baseTextStyle.bodyLarge,
              ),
              secondary: Icon(
                Icons.notifications,
                color: theme.iconTheme.color,
              ),
              value: _notificaciones ?? false,
              activeColor: AppColors.secondaryDark,
              onChanged: (val) async {
                setState(() => _notificaciones = val);
                await _guardarPreferenciaNotificaciones(val);

                if (val) {
                  await NotificationService.showNotification(
                    title: 'Bienvenido 😊',
                    body: 'Has activado las notificaciones.',
                  );
                  await NotificationService.scheduleDailyNotification(
                    title: '¿Cómo te sientes hoy?',
                    body: 'Registra tus emociones 🌱',
                    hour: 9,
                    minute: 0,
                  );
                } else {
                  await NotificationService.cancelAll();
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? "🔔 Notificaciones activadas"
                          : "🔕 Notificaciones desactivadas",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: val ? Colors.green : Colors.orangeAccent,
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // 📞 Contacto seguro (sin contador, texto simplificado)
            FutureBuilder<Student?>(
              future: perfil,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Text("No hay datos", style: baseTextStyle.bodyMedium);
                }

                final student = snapshot.data!;
                _controllerSafeContact.text =
                    _controllerSafeContact.text.isEmpty
                    ? student.safeContact ?? ""
                    : _controllerSafeContact.text;

                return TextField(
                  controller: _controllerSafeContact,
                  maxLength: 9,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  inputFormatters: [LengthLimitingTextInputFormatter(9)],
                  style: baseTextStyle.bodyMedium,
                  decoration: InputDecoration(
                    labelText: "Contacto seguro", // ✅ texto simplificado
                    prefixIcon: const Icon(Icons.contact_phone),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: theme.colorScheme.primary),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 💾 Botón Guardar
            ElevatedButton.icon(
              onPressed: _onSavePressed,
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                "Guardar", // ✅ texto unificado
                style: baseTextStyle.labelLarge?.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secundary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
