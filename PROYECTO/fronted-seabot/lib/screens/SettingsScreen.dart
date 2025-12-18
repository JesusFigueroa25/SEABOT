import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/services/user_service.dart';
import 'package:seabot/screens/bienvenida_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();

    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;

      setState(() {
        isConnected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    setState(() {
      isConnected = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _showTermsAndConditions() {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Términos y Condiciones de Uso",
          style: baseTextStyle.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            """
1. Finalidad del servicio  
SeaBot es una aplicación diseñada para brindar acompañamiento emocional y orientación general basada en inteligencia artificial. No sustituye la atención profesional de psicólogos, psiquiatras ni otros especialistas en salud mental.

2. Confidencialidad y protección de datos  
Toda la información proporcionada por el usuario se maneja de forma confidencial, conforme a la Ley N° 29733 de Protección de Datos Personales (Perú). Los datos se almacenan temporalmente y de manera anonimizada para mejorar la experiencia y garantizar la seguridad del usuario.

3. Consentimiento informado  
Al usar la aplicación, el usuario reconoce que las interacciones con el chatbot son de carácter orientativo y acepta voluntariamente participar, comprendiendo que no se trata de un servicio clínico o de diagnóstico.

4. Limitaciones de responsabilidad  
SeaBot no asume responsabilidad por decisiones tomadas a partir de la información proporcionada por el chatbot. Las respuestas generadas provienen del modelo de lenguaje GPT-4, el cual utiliza inteligencia artificial y puede ofrecer información imprecisa, desactualizada o interpretaciones erradas de las consultas del usuario.
El contenido tiene únicamente fines de acompañamiento emocional y orientación general. Ante cualquier situación de riesgo, crisis o emergencia, el usuario debe comunicarse de inmediato con servicios profesionales de salud mental o líneas de ayuda disponibles en su país.

5. Uso responsable de la aplicación  
El usuario se compromete a hacer un uso adecuado del contenido y las funciones de SeaBot, evitando lenguaje ofensivo, manipulación del sistema o difusión de información falsa.

6. Propiedad intelectual  
El contenido, diseño, logotipo, estructura y código fuente de la aplicación son propiedad del equipo desarrollador del proyecto académico “SeaBot”, quedando prohibida su copia o distribución no autorizada.

7. Derechos del usuario  
El usuario puede solicitar la eliminación o desactivación de su cuenta en cualquier momento, conforme a los procedimientos internos de la aplicación. Además, puede revocar su consentimiento de uso de datos personales enviando una solicitud por los canales indicados.

8. Actualización de los términos  
SeaBot se reserva el derecho de modificar estos términos para mejorar la experiencia, seguridad o cumplimiento legal. Toda actualización será notificada dentro de la aplicación.

9. Contacto y soporte  
Para consultas, comentarios o sugerencias, los usuarios pueden comunicarse a través del correo de soporte institucional o las vías de contacto descritas en la sección de ayuda de la aplicación.

Al continuar, confirmas que has leído y aceptas estos términos y condiciones de uso.
""",
            style: baseTextStyle.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.9),
              height: 1.45,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: baseTextStyle.bodyMedium?.copyWith(
                color: AppColors.secundaryStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cerrarSesion() async {
    final authService = AuthService();
    await authService.logout();
    AppData.studentID = 0;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Sesión cerrada correctamente.",
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }

  void _eliminarCuenta() {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Eliminar cuenta",
          style: baseTextStyle.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Text(
          "¿Estás seguro de que deseas eliminar (desactivar) tu cuenta?\n"
          "Tu información no se eliminará, pero no podrás iniciar sesión hasta reactivarla.",
          style: baseTextStyle.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.9),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: baseTextStyle.bodyMedium),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              final connectivityResult = await Connectivity()
                  .checkConnectivity();
              if (connectivityResult == ConnectivityResult.none) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "❌ No hay conexión a internet. Intenta nuevamente.",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              try {
                final userService = UserService();
                final userId = AppData.userID;
                await userService.updateEnable(userId, {"enable": false});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "✅ Tu cuenta ha sido desactivada correctamente.",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                final authService = AuthService();
                await authService.logout();
                AppData.userID = 0;
                AppData.studentID = 0;

                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "❌ Error al desactivar cuenta: $e",
                      style: baseTextStyle.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: Text(
              "Eliminar",
              style: baseTextStyle.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Configuración",
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
          children: [
            ListTile(
              leading: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.redAccent,
              ),
              title: Text(
                "Estado de conexión",
                style: baseTextStyle.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isConnected ? "Conectado" : "Sin conexión",
                style: baseTextStyle.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            // const Divider(),

            // 🔹 Términos y condiciones
            ListTile(
              leading: const Icon(
                Icons.description_rounded,
                color: AppColors.primary,
              ),
              title: Text(
                "Términos y condiciones",
                style: baseTextStyle.bodyLarge,
              ),
              onTap: _showTermsAndConditions,
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.iconTheme.color?.withOpacity(0.6),
              ),
            ),
            //const Divider(),

            // 🔹 Cerrar sesión
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.orange),
              title: Text("Cerrar sesión", style: baseTextStyle.bodyLarge),
              onTap: _cerrarSesion,
            ),

            // 🔹 Eliminar cuenta
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
              ),
              title: Text("Eliminar cuenta", style: baseTextStyle.bodyLarge),
              onTap: _eliminarCuenta,
            ),
          ],
        ),
      ),
    );
  }
}
