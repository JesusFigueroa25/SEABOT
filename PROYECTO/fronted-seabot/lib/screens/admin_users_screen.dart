import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/student.dart';
import 'package:seabot/models/user.dart';
import 'package:seabot/services/user_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final UserService serviceController = UserService();
  late Future<List<User>> resultados;

  @override
  void initState() {
    super.initState();
    resultados = serviceController.getUsersStudent();
  }

  // 🔹 Ver detalles del usuario
  Future<void> _verUsuario(User usuario) async {
    Student estudiante = await serviceController.usersDetail(usuario.id);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              _buildInfoTile("Rol", estudiante.user?.role ?? "Sin rol"),
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

  // 🔹 Bloquear o desbloquear usuario
  Future<void> _bloquearUsuario(User usuario) async {
    final yaBloqueado = (usuario.enable ?? false);

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            yaBloqueado ? "Bloquear usuario" : "Desbloquear usuario",
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          content: Text(
            yaBloqueado
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
                    yaBloqueado ? Colors.redAccent : AppColors.secundary,
              ),
              onPressed: () async {
                Map<String, dynamic> resultResponse = {"enable": !yaBloqueado};
                await serviceController.updateEnable(usuario.id, resultResponse);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !yaBloqueado
                          ? "${usuario.nameuser} fue desbloqueado ✅"
                          : "${usuario.nameuser} fue bloqueado ❌",
                    ),
                    backgroundColor:
                        !yaBloqueado ? Colors.green : Colors.redAccent,
                  ),
                );

                setState(() {
                  resultados = serviceController.getUsersStudent();
                });
              },
              child: Text(
                yaBloqueado ? "Bloquear" : "Desbloquear",
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

  @override
  Widget build(BuildContext context) {
    // 🌞 Forzar modo claro + tipografía Manrope
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
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: GoogleFonts.manrope(color: Colors.redAccent),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  "No hay datos disponibles.",
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    color: Colors.redAccent,
                  ),
                ),
              );
            }

            final resultadosData = snapshot.data!;

            return ListView.builder(
              itemCount: resultadosData.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final usuario = resultadosData[index];
                final activo = usuario.enable ?? false;

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: activo
                          ? AppColors.secundary.withOpacity(0.2)
                          : Colors.redAccent.withOpacity(0.2),
                      child: Icon(
                        activo ? Icons.person : Icons.block,
                        color:
                            activo ? AppColors.secundary : Colors.redAccent,
                      ),
                    ),
                    title: Text(
                      usuario.nameuser,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      color: Colors.white,
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "ver",
                          child: Text("Visualizar"),
                        ),
                        PopupMenuItem(
                          value: "bloquear",
                          child: Text(activo ? "Bloquear" : "Desbloquear"),
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
              },
            );
          },
        ),
      ),
    );
  }
}
