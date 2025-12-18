import 'package:flutter/material.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/screens/breathing_exercise_screen.dart';
import 'package:seabot/screens/info_detail_screen.dart';
import 'package:seabot/screens/resources_educational_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/repositories/student_repository.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  Future<void> _showEmergencyOptions(BuildContext context) async {
    final studentRepository = StudentRepository();
    final studentID = AppData.studentID;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        final theme = Theme.of(context);
        final baseTextStyle = theme.textTheme;
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            "Selecciona una opción de ayuda",
            style: baseTextStyle.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Puedes comunicarte con la línea nacional o con tu contacto seguro.",
            style: baseTextStyle.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _callEmergencyNumber("113");
              },
              icon: const Icon(Icons.phone, color: Colors.redAccent),
              label: Text("Línea 113", style: baseTextStyle.bodyMedium),
            ),
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _callSafeContact(studentRepository, studentID);
              },
              icon: const Icon(Icons.person, color: Colors.blue),
              label: Text("Contacto Seguro", style: baseTextStyle.bodyMedium),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callEmergencyNumber(String number) async {
    final uri = Uri.parse("tel:$number");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (!mounted) return;
        _showSnack("📞 Llamando a la línea $number...", Colors.green);
      } else {
        _showSnack("No se pudo iniciar la llamada.", Colors.red);
      }
    } catch (e) {
      _showSnack("⚠️ Error al intentar la llamada: $e", Colors.red);
    }
  }

  Future<void> _callSafeContact(
    StudentRepository repository,
    int studentID,
  ) async {
    try {
      final student = await repository
          .fetchAndSyncStudent(studentID, true)
          .timeout(const Duration(seconds: 5));

      if (student == null ||
          student.safeContact == null ||
          student.safeContact!.isEmpty) {
        _showSnack(
          "⚠️ No tienes un contacto seguro registrado.",
          Colors.orange,
        );
        return;
      }

      final safeContact = student.safeContact!.trim();
      final uri = Uri.parse("tel:$safeContact");

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _showSnack(
          "📞 Llamando a tu contacto seguro ($safeContact)...",
          Colors.green,
        );
      } else {
        _showSnack(
          "No se pudo iniciar la llamada al contacto seguro.",
          Colors.red,
        );
      }
    } catch (e) {
      _showSnack("Error al obtener contacto seguro: $e", Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse("tel:$number");
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack("No se pudo iniciar la llamada.", Colors.red);
      }
    } catch (e) {
      _showSnack("Error al intentar llamar: $e", Colors.red);
    }
  }

  Future<void> _sendEmail(String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': subject},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showSnack("No se pudo abrir el correo.", Colors.red);
      }
    } catch (e) {
      _showSnack("Error al abrir el correo: $e", Colors.red);
    }
  }

  void _showEmergencyNumbersDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("📞 Líneas Nacionales de Emergencia"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhoneItem(
                "Atención médica EsSalud (violencia familiar)",
                "014118000",
              ),
              _buildPhoneItem(
                "Denuncia contra la violencia familiar y sexual",
                "100",
              ),
              _buildPhoneItem("Central policial", "105"),
              _buildPhoneItem("EsSalud - Información COVID-19", "107"),
              _buildPhoneItem("Policía de carreteras", "110"),
              _buildPhoneItem("Defensa Civil", "115"),
              _buildPhoneItem("Bomberos", "116"),
              _buildPhoneItem("Cruz Roja", "012660481"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.primary, // 🔹 color adaptable
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPsychologyDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🧠 Centro de Psicología Universitaria (UPC)"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEmailItem(
                "Campus Monterrico",
                "orientacionpsicopedagogicamo@upc.pe",
              ),
              _buildEmailItem(
                "Campus San Isidro",
                "orientacionpsicopedagogicasi@upc.pe",
              ),
              _buildEmailItem(
                "Campus San Miguel",
                "orientacionpsicopedagogicasm@upc.pe",
              ),
              _buildEmailItem(
                "Campus Villa",
                "orientacionpsicopedagogicavi@upc.pe",
              ),
              _buildEmailItem(
                "Oficina Corporativa",
                "orientacionpsicopedagogica@upc.pe",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailItem(String label, String email) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(email),
      trailing: IconButton(
        icon: const Icon(Icons.email, color: Colors.blueAccent),
        onPressed: () =>
            _sendEmail(email, "Consulta de orientación psicológica"),
      ),
    );
  }

  Widget _buildPhoneItem(String label, String number) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text(number),
      trailing: IconButton(
        icon: const Icon(Icons.call, color: Colors.teal),
        onPressed: () => _callNumber(number),
      ),
    );
  }

  // 🔹 Construcción visual
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;
    final textColor = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Recursos de Bienestar",
          style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🫂 Recursos educativos
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  "🫂 Recursos educativos",
                  style: baseTextStyle.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              _buildEducationalResources(theme),
              const SizedBox(height: 20),
              // 🫁 Ejercicio de Respiración
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  "🫁 Ejercicio de Respiración",
                  style: baseTextStyle.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              _buildBreathingExercise(theme),

              const SizedBox(height: 20),

              // 💬 Frases motivacionales
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  "💬 Frases Motivacionales",
                  style: baseTextStyle.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(
                height: 174,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFrasesMotivadoras(
                      "Cada día es una nueva oportunidad para crecer y convertirte en la mejor versión de ti mismo.",
                      AppColors.primary,
                    ),
                    _buildFrasesMotivadoras(
                      "Tu valor no se mide por tus logros académicos, sino por la persona maravillosa que eres.",
                      AppColors.secundary,
                    ),
                    _buildFrasesMotivadoras(
                      "Está bien no estar bien. Lo importante es que sigas adelante, un paso a la vez.",
                      const Color(0xFF89A1F4),
                    ),
                    _buildFrasesMotivadoras(
                      "Eres más fuerte de lo que crees, más valiente de lo que sientes y más amado de lo que imaginas.",
                      const Color(0xFFFF7E6C),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildInfoSection(theme),
              const SizedBox(height: 20),

              // ☎️ Contactos de ayuda
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Text(
                  "☎️ Contactos de Ayuda",
                  style: baseTextStyle.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),

              _buildHelpCard(
                titulo: "Líneas Nacionales de Emergencia",
                subtitulo: "Llama directamente según tu necesidad",
                icono: Icons.local_phone,
                colorcito: AppColors.primary,
                onTap: _showEmergencyNumbersDialog,
              ),
              _buildHelpCard(
                titulo: "Centro de Psicología Universitaria (UPC)",
                subtitulo: "Correos y ubicaciones por campus",
                icono: Icons.psychology,
                colorcito: AppColors.secundary,
                onTap: _showPsychologyDialog,
              ),
              _buildHelpCard(
                titulo: "Bienestar Estudiantil UPC",
                subtitulo: "Consejería académica y personal",
                icono: Icons.school,
                colorcito: const Color(0xFF8074EF),
                onTap: () => _showSnack(
                  "Puedes escribir a: bienestar.estudiantil@upc.pe",
                  Colors.teal,
                ),
              ),

              const SizedBox(height: 20),

              //// 🔴 Botón de emergencia
              //Center(
              //  child: ElevatedButton.icon(
              //    onPressed: () => _showEmergencyOptions(context),
              //    icon: const Icon(Icons.sos, color: Colors.white),
              //    label: Text(
              //      "Botón de Emergencia",
              //      style: baseTextStyle.titleMedium?.copyWith(
              //        color: Colors.white,
              //        fontSize: 18,
              //      ),
              //    ),
              //    style: ElevatedButton.styleFrom(
              //      backgroundColor: Colors.redAccent,
              //      padding: const EdgeInsets.symmetric(
              //        horizontal: 24,
              //        vertical: 16,
              //      ),
              //      shape: RoundedRectangleBorder(
              //        borderRadius: BorderRadius.circular(15),
              //      ),
              //    ),
              //  ),
              //),
            ],
          ),
        ),
      ),
    );
  }

  // 🫁 Ejercicio de respiración
  Widget _buildBreathingExercise(ThemeData theme) {
    final baseTextStyle = theme.textTheme;
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.air, color: Colors.teal, size: 35),
        title: Text(
          "🫁 Ejercicio de Respiración 4-7-8",
          style: baseTextStyle.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Relaja tu mente y cuerpo en 1 minuto",
          style: baseTextStyle.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),

        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BreathingExerciseScreen()),
          );
        },
      ),
    );
  }

  // 📚 Recursos Educativos
  Widget _buildEducationalResources(ThemeData theme) {
    final baseTextStyle = theme.textTheme;
    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: ListTile(
        leading: const Icon(
          Icons.menu_book,
          color: Color(0xFF6C63FF),
          size: 35,
        ),
        title: Text(
          "📚 Recursos Educativos",
          style: baseTextStyle.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "Encuentra artículos, videos y guías sobre bienestar emocional",
          style: baseTextStyle.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ResourcesEducationalScreen(),
            ),
          );
        },
      ),
    );
  }

  // 💬 Frases motivadoras
  Widget _buildFrasesMotivadoras(String label, Color color) {
    return Container(
      margin: const EdgeInsets.all(8),
      width: 280,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // 📘 Guías informativas
  Widget _buildInfoSection(ThemeData theme) {
    final baseTextStyle = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Text(
            "📘 Guías Informativas (Offline)",
            style: baseTextStyle.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildInfoCard(
          theme,
          title: "Guía para la prevención del suicidio - MINSA",
          subtitle: "Documento PDF oficial del MINSA",
          assetPath: "assets/docs/guia_minsa.pdf",
          isPdf: true,
        ),
        _buildInfoCard(
          theme,
          title: "Infografía sobre depresión - UPC",
          subtitle: "Imagen informativa de bienestar estudiantil",
          assetPath: "assets/images/infografia_upc.png",
          isPdf: false,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required String assetPath,
    required bool isPdf,
  }) {
    final baseTextStyle = theme.textTheme;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => InfoDetailScreen(
              title: title,
              assetPath: assetPath,
              isPdf: isPdf,
            ),
          ),
        );
      },
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image,
              color: AppColors.primary,
            ),
          ),
          title: Text(
            title,
            style: baseTextStyle.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: baseTextStyle.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  // ☎️ Cards de ayuda
  Widget _buildHelpCard({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorcito,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Card(
        color: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: colorcito.withOpacity(0.2),
            child: Icon(icono, color: colorcito),
          ),
          title: Text(
            titulo,
            style: baseTextStyle.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            subtitulo,
            style: baseTextStyle.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: theme.iconTheme.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
