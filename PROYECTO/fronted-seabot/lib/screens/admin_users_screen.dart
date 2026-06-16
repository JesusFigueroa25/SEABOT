import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/responsive_helper.dart';
import 'package:seabot/models/student.dart';
import 'package:seabot/models/user.dart';
import 'package:seabot/screens/widgets/seabot_widgets.dart';
import 'package:seabot/services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

enum _FiltroUsuarios { todos, activos, inactivos }

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService serviceController = UserService();
  late Future<List<User>> resultados;
  _FiltroUsuarios _filtroUsuarios = _FiltroUsuarios.todos;

  @override
  void initState() {
    super.initState();
    resultados = serviceController.getUsersStudent();
  }

  List<User> _filtrarUsuarios(List<User> usuarios) {
    switch (_filtroUsuarios) {
      case _FiltroUsuarios.activos:
        return usuarios.where((usuario) => usuario.enable ?? false).toList();

      case _FiltroUsuarios.inactivos:
        return usuarios.where((usuario) => !(usuario.enable ?? false)).toList();

      case _FiltroUsuarios.todos:
        final usuariosOrdenados = List<User>.from(usuarios);

        usuariosOrdenados.sort((a, b) {
          final aActivo = a.enable ?? false;
          final bActivo = b.enable ?? false;

          if (aActivo == bActivo) return 0;

          // Activos arriba, inactivos abajo
          return aActivo ? -1 : 1;
        });

        return usuariosOrdenados;
    }
  }

  Widget _buildFiltrosUsuarios({
    required int total,
    required int activos,
    required int inactivos,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: const Color(0xFFF7F9FB),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFiltroChip(
              label: "Todos",
              count: total,
              icon: Icons.people_alt_rounded,
              filtro: _FiltroUsuarios.todos,
              color: AppColors.primaryDarkText,
            ),
            const SizedBox(width: 8),
            _buildFiltroChip(
              label: "Activos",
              count: activos,
              icon: Icons.check_circle_rounded,
              filtro: _FiltroUsuarios.activos,
              color: AppColors.secondaryDarkText,
            ),
            const SizedBox(width: 8),
            _buildFiltroChip(
              label: "Inactivos",
              count: inactivos,
              icon: Icons.block_rounded,
              filtro: _FiltroUsuarios.inactivos,
              color: AppColors.rojo,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroChip({
    required String label,
    required int count,
    required IconData icon,
    required _FiltroUsuarios filtro,
    required Color color,
  }) {
    final selected = _filtroUsuarios == filtro;

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      backgroundColor: AppColors.cardLight,
      selectedColor: color,
      side: BorderSide(color: selected ? color : color.withOpacity(0.35)),
      avatar: Icon(icon, size: 18, color: selected ? AppColors.white : color),
      label: Text(
        "$label ($count)",
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.white : AppColors.textLight,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _filtroUsuarios = filtro;
        });
      },
    );
  }

  Widget _buildEmptyFilterState() {
    String message;

    switch (_filtroUsuarios) {
      case _FiltroUsuarios.activos:
        message = "No hay usuarios activos.";
        break;
      case _FiltroUsuarios.inactivos:
        message = "No hay usuarios inactivos.";
        break;
      case _FiltroUsuarios.todos:
        message = "No hay usuarios disponibles.";
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_alt_off_rounded,
              size: 46,
              color: AppColors.subtitleLight.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.subtitleLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verUsuario(User usuario) async {
    Student estudiante = await serviceController.usersDetail(usuario.id);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Theme(
        data: ThemeData.light().copyWith(
          textTheme: GoogleFonts.manropeTextTheme(),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secundary,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                usuario.nameuser,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    (usuario.enable ?? false)
                        ? Icons.check_circle
                        : Icons.block,
                    color: (usuario.enable ?? false)
                        ? Colors.green
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (usuario.enable ?? false) ? "Activo" : "Bloqueado",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      color: (usuario.enable ?? false)
                          ? Colors.green
                          : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildInfoTile("Alias", estudiante.alias ?? "-"),
              _buildInfoTile("Contacto seguro", estudiante.safeContact ?? "-"),
              _buildInfoTile("Rol", estudiante.user?.role ?? "user"),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.grey),
              label: Text(
                "Cerrar",
                style: GoogleFonts.manrope(color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.arrow_right, color: Colors.grey),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.manrope(color: Colors.grey[700]),
      ),
    );
  }

  Future<void> _bloquearUsuario(User usuario) async {
    final estaActivo = usuario.enable ?? false;

    showDialog(
      context: context,
      builder: (_) => Theme(
        data: ThemeData.light().copyWith(
          textTheme: GoogleFonts.manropeTextTheme(),
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.secundary,
          ),
        ),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            estaActivo ? "Bloquear usuario" : "Desbloquear usuario",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            estaActivo
                ? "¿Estás seguro de bloquear a ${usuario.nameuser}?"
                : "¿Deseas desbloquear a ${usuario.nameuser}?",
            style: GoogleFonts.manrope(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar", style: GoogleFonts.manrope()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    estaActivo ? Colors.redAccent : AppColors.secundary,
              ),
              onPressed: () async {
                final resultResponse = {"enable": !estaActivo};

                await serviceController.updateEnable(
                  usuario.id,
                  resultResponse,
                );

                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      estaActivo
                          ? "${usuario.nameuser} fue bloqueado ❌"
                          : "${usuario.nameuser} fue desbloqueado ✅",
                    ),
                    backgroundColor:
                        estaActivo ? Colors.redAccent : Colors.green,
                  ),
                );

                setState(() {
                  resultados = serviceController.getUsersStudent();
                });
              },
              child: Text(
                estaActivo ? "Bloquear" : "Desbloquear",
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              "Sin conexión a internet",
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUsuarioCard(User usuario) {
    final activo = usuario.enable ?? false;

    return Card(
      key: ValueKey(usuario.id),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: activo
              ? AppColors.secundary.withOpacity(0.2)
              : AppColors.rojo.withOpacity(0.2),
          child: Icon(
            activo ? Icons.person : Icons.block,
            color: activo ? AppColors.secondaryDarkText : AppColors.rojo,
          ),
        ),
        title: Text(
          usuario.nameuser,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            color: AppColors.textLight,
          ),
        ),
        subtitle: Text(
          activo ? "Usuario activo" : "Usuario inactivo",
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: activo ? AppColors.secondaryDarkText : AppColors.rojo,
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          icon: const Icon(
            Icons.more_vert,
            color: Colors.black87,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: "ver",
              child: Text("Visualizar"),
            ),
            PopupMenuItem(
              value: "bloquear",
              child: Text(
                activo ? "Bloquear" : "Desbloquear",
              ),
            ),
          ],
          onSelected: (value) {
            if (value == "ver") {
              _verUsuario(usuario);
            } else if (value == "bloquear") {
              _bloquearUsuario(usuario);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7F9FB),
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        titleTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secundary,
      ),
    );

    return Theme(
      data: lightTheme,
      child: Scaffold(
        backgroundColor: lightTheme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Gestión de Usuarios"),
          centerTitle: true,
        ),
        body: FutureBuilder<List<User>>(
          future: resultados,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SeaBotLoadingState(text: "Cargando usuarios...");
            }

            if (snapshot.hasError) {
              return const Center(
                child: SeaBotEmptyState(
                  icon: Icons.wifi_off_rounded,
                  message: "Sin conexión a internet",
                  subMessage: "Por favor, verifica tu conexión.",
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: SeaBotEmptyState(
                  icon: Icons.people_outline_rounded,
                  message: "No hay datos disponibles.",
                  subMessage: "No se encontraron alumnos registrados.",
                ),
              );
            }

            final resultadosData = snapshot.data!;

            final activos = resultadosData
                .where((usuario) => usuario.enable ?? false)
                .length;

            final inactivos = resultadosData
                .where((usuario) => !(usuario.enable ?? false))
                .length;

            final usuariosFiltrados = _filtrarUsuarios(resultadosData);

            return ResponsiveHelper.centeredConstraint(
              context: context,
              maxTabletWidth: 800,
              child: Column(
                children: [
                  _buildFiltrosUsuarios(
                    total: resultadosData.length,
                    activos: activos,
                    inactivos: inactivos,
                  ),
                  Expanded(
                    child: usuariosFiltrados.isEmpty
                        ? _buildEmptyFilterState()
                        : ListView.builder(
                            itemCount: usuariosFiltrados.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final usuario = usuariosFiltrados[index];
                              return _buildUsuarioCard(usuario);
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}