import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/emotional_register.dart';
import 'package:seabot/repositories/emotional_registers_repository.dart';
import 'package:seabot/services/emotional_register_service.dart';

class EmotionalQuickLogScreen extends StatefulWidget {
  const EmotionalQuickLogScreen({super.key});

  @override
  State<EmotionalQuickLogScreen> createState() =>
      _EmotionalQuickLogScreenState();
}

class _EmotionalQuickLogScreenState extends State<EmotionalQuickLogScreen> {
  int studentID = AppData.studentID;
  final EmotionalRegisterService serviceController = EmotionalRegisterService();
  late Future<List<EmotionalRegister>> resultados;
  final EmotionsRepository repository = EmotionsRepository();

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    bool online = await _hasInternet();
    setState(() {
      resultados = repository.fetchAndSyncEmotion(studentID, online);
    });
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

  Future<void> _onEmotionPressed(String emoji, String label) async {
    final connected = await _hasInternet();

    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📵 No tienes conexión a internet",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _registrarEmocion(emoji, label);
  }

  String _getEmojiForEmotion(String? emotion) {
    switch (emotion) {
      case "Alegría":
        return "😀";
      case "Tristeza":
        return "😢";
      case "Ira":
        return "😡";
      case "Miedo":
        return "😨";
     // case "Disgusto":
     //   return "🤢";
     // case "Sorpresa":
     //   return "😮";
      default:
        return "🙂";
    }
  }

  Future<void> _registrarEmocion(String emoji, String label) async {
    bool hecho = await serviceController.hasTakenToday(studentID);
    if (hecho) {
      showDialog(
        context: context,
        builder: (_) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Theme(
            data: Theme.of(
              context,
            ).copyWith(textTheme: GoogleFonts.manropeTextTheme()),
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF2B2B2B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                "Aviso importante",
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              content: Text(
                "Ya realizaste el registro emocional rápido hoy.\nIntenta nuevamente mañana.",
                style: GoogleFonts.manrope(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Entendido",
                    style: GoogleFonts.manrope(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final ahora = DateTime.now().toUtc();
    final resultResponse = {
      "emotion": label,
      "fecha_hora": ahora.toIso8601String(),
      "student_id": studentID,
    };
    await serviceController.createRegister(resultResponse);

    serviceController.getLast8ByStudent(studentID).then((data) {
      setState(() {
        resultados = Future.value(data);
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Estado registrado: $label $emoji",
          style: GoogleFonts.manrope(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
      ),
    );
  }

  Widget _buildEmotionButton(String emoji, String label, bool isDark) {
    return GestureDetector(
      onTap: () => _onEmotionPressed(emoji, label),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: isDark
                ? AppColors.secundary.withOpacity(0.2)
                : AppColors.secundary.withOpacity(0.15),
            child: Text(emoji, style: const TextStyle(fontSize: 30)),
          ),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.manropeTextTheme(theme.textTheme),
        appBarTheme: theme.appBarTheme.copyWith(
          titleTextStyle: GoogleFonts.manrope(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("Registro Emocional Rápido"),
          centerTitle: true,
          backgroundColor: AppColors.primary,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "¿Cómo te sientes ahora?",
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // 🔹 Escala de emociones
              // 🔹 Escala de emociones básicas (Paul Ekman)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 25,
                  children: [
                    _buildEmotionButton("😀", "Alegría", isDark),
                    _buildEmotionButton("😢", "Tristeza", isDark),
                    _buildEmotionButton("😡", "Ira", isDark),
                    _buildEmotionButton("😨", "Miedo", isDark),
                    //_buildEmotionButton("🤢", "Disgusto", isDark),
                    //_buildEmotionButton("😮", "Sorpresa", isDark),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              Divider(
                color: isDark ? Colors.white24 : Colors.grey[300],
                thickness: 1,
              ),

              // 🔹 Lista de registros
              Expanded(
                child: FutureBuilder<List<EmotionalRegister>>(
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
                          "No hay registros emocionales aún.\nRealiza el primero 💭",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      );
                    }

                    final resultadosData = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: resultadosData.length,
                      itemBuilder: (context, index) {
                        final r = resultadosData[index];
                        return Card(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Text(
                              _getEmojiForEmotion(r.emotion),
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(
                              r.emotion ?? "",
                              style: GoogleFonts.manrope(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              "📅 ${r.fechaHora}",
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
