import 'package:flutter/material.dart';
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
          const SnackBar(content: Text("⚠️ Formato no compatible")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme; 

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Recursos Emocionales Educativos",
          style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: FutureBuilder<List<HelpResource>>(
        future: recursos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No hay recursos disponibles en este momento.",
                style: baseTextStyle.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }

          final recursosActivos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recursosActivos.length,
            itemBuilder: (context, index) {
              final r = recursosActivos[index];
              final tipo = r.resourceType ?? "";
              final colorIcon = _getColor(tipo);

              return Card(
                elevation: 3,
                color: theme.colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorIcon.withOpacity(0.2),
                    child: Icon(_getIcon(tipo), color: colorIcon),
                  ),
                  title: Text(
                    r.nameResource,
                    style: baseTextStyle.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    r.description ?? "Sin descripción",
                    style: baseTextStyle.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.open_in_new_rounded,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    onPressed: () => _abrirRecurso(r),
                  ),
                  onTap: () => _abrirRecurso(r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
