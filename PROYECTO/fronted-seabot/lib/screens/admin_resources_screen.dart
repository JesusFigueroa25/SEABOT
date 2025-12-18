import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/models/help_resource.dart';
import 'package:seabot/services/help_resource_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminResourcesScreen extends StatefulWidget {
  const AdminResourcesScreen({super.key});

  @override
  State<AdminResourcesScreen> createState() => _AdminResourcesScreenState();
}

class _AdminResourcesScreenState extends State<AdminResourcesScreen> {
  final HelpResourceService serviceController = HelpResourceService();
  late Future<List<HelpResource>> resultados;

  @override
  void initState() {
    super.initState();
    resultados = serviceController.getAllResources();
  }

  // 🟣 Diálogo reutilizable para agregar o editar
  void _showResourceDialog({HelpResource? resource}) {
    final TextEditingController _nameCtrl = TextEditingController(
      text: resource?.nameResource ?? '',
    );
    final TextEditingController _descCtrl = TextEditingController(
      text: resource?.description ?? '',
    );
    final TextEditingController _urlCtrl = TextEditingController(
      text: resource?.url ?? '',
    );
    String _tipo = resource?.resourceType ?? "Artículo";

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
            resource == null ? "Agregar Recurso de Apoyo" : "Editar Recurso",
            style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Título del recurso",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "Descripción"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _urlCtrl,
                  decoration: const InputDecoration(labelText: "Enlace (URL)"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _tipo,
                  decoration: const InputDecoration(labelText: "Tipo de recurso"),
                  items: ["Artículo", "Video", "Guía"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => _tipo = v!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancelar",
                style: GoogleFonts.manrope(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secundary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (_nameCtrl.text.isEmpty) return;

                final Map<String, dynamic> body = {
                  "name_resource": _nameCtrl.text,
                  "description": _descCtrl.text,
                  "resource_type": _tipo,
                  "url": _urlCtrl.text,
                  "enable": resource?.enable ?? true,
                };

                if (resource == null) {
                  await serviceController.createResource(body);
                } else {
                  await serviceController.updateResource(resource.id, body);
                }

                final nuevosDatos = await serviceController.getAllResources();

                if (mounted) {
                  setState(() {
                    resultados = Future.value(nuevosDatos);
                  });
                }

                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      resource == null
                          ? "✅ Recurso agregado correctamente"
                          : "✅ Recurso actualizado correctamente",
                    ),
                    backgroundColor: AppColors.secundary,
                  ),
                );
              },
              child: Text(
                resource == null ? "Guardar" : "Actualizar",
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

  // 🟣 Card visual de cada recurso
  Widget _buildResourceCard(HelpResource r) {
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          r.nameResource,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          r.resourceType ?? "Sin tipo",
          style: GoogleFonts.manrope(
            color: Colors.grey[700],
          ),
        ),
        trailing: PopupMenuButton<String>(
          color: Colors.white,
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (v) async {
            if (v == "Editar") {
              _showResourceDialog(resource: r);
            } else if (v == "Eliminar") {
              await serviceController.deleteResource(r.id);
              final nuevosDatos = await serviceController.getAllResources();

              if (mounted) {
                setState(() {
                  resultados = Future.value(nuevosDatos);
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🗑️ Recurso eliminado correctamente"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            } else if (v == "Estado") {
              await serviceController.modifyEnable(r.id, {"enable": !r.enable});
              final nuevosDatos = await serviceController.getAllResources();

              if (mounted) {
                setState(() {
                  resultados = Future.value(nuevosDatos);
                });
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    !r.enable
                        ? "✅ Recurso activado correctamente"
                        : "🚫 Recurso bloqueado correctamente",
                  ),
                  backgroundColor:
                      !r.enable ? Colors.green : Colors.orangeAccent,
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: "Editar", child: Text("Editar")),
            PopupMenuItem(value: "Estado", child: Text("Bloquear/Desbloquear")),
            PopupMenuItem(value: "Eliminar", child: Text("Eliminar")),
          ],
        ),
        children: [
          if (r.description != null && r.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                r.description!,
                style: GoogleFonts.manrope(color: Colors.grey[700]),
              ),
            ),
          if (r.url != null && r.url!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextButton.icon(
                icon: const Icon(Icons.link, color: AppColors.primary),
                label: Text(
                  "Abrir recurso",
                  style: GoogleFonts.manrope(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => launchUrl(Uri.parse(r.url!)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Chip(
                  label: Text(
                    r.enable ? "Activo" : "Bloqueado",
                    style: GoogleFonts.manrope(color: Colors.white),
                  ),
                  backgroundColor:
                      r.enable ? Colors.greenAccent[700] : Colors.redAccent,
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌞 Tema fijo claro con fuente Manrope
    final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFD),
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
          title: const Text("Gestión de Recursos de Apoyo"),
          centerTitle: true,
        ),
        body: FutureBuilder<List<HelpResource>>(
          future: resultados,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;
            if (data.isEmpty) {
              return Center(
                child: Text(
                  "No hay recursos aún.",
                  style: GoogleFonts.manrope(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              );
            }
            return ListView(children: data.map(_buildResourceCard).toList());
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.secundary,
          onPressed: () => _showResourceDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
