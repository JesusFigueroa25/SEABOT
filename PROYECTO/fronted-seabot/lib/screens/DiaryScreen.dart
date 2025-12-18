import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:seabot/core/app_data.dart';
import 'package:seabot/models/diary_entry.dart';
import 'package:seabot/repositories/diary_entries_repository.dart';
import 'package:seabot/services/diary_entry_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  int studentID = AppData.studentID;
  final TextEditingController _controller = TextEditingController();
  final DiaryEntryService serviceController = DiaryEntryService();
  late Future<List<DiaryEntry>> resultados;
  final DiariosRepository repository = DiariosRepository();

  @override
  void initState() {
    super.initState();
    resultados = Future.value([]);
    _loadResults();
  }

  Future<void> _loadResults() async {
    bool online = await hasInternet();
    setState(() {
      resultados = repository.fetchAndSyncDiaries(studentID, online);
    });
  }

  Future<bool> hasInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return false;
    try {
      final result = await InternetAddress.lookup('platform.openai.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onSavePressed() async {
    final connected = await hasInternet();
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
    await _saveEntry();
  }

  Future<void> _saveEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "El diario no puede estar vacío",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final ahora = DateTime.now().toUtc();
    final resultResponse = {
      "entry": text,
      "fecha_hora": ahora.toIso8601String(),
      "student_id": studentID,
    };

    await serviceController.createEntry(resultResponse);

    final nuevosDatos = await serviceController.getLast8ByStudent(studentID);
    setState(() {
      _controller.clear();
      resultados = Future.value(nuevosDatos);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Entrada guardada en tu diario 📝",
          style: GoogleFonts.manrope(color: Colors.white),
        ),
        backgroundColor: AppColors.secundary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

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
          title: const Text("Diario Personal"),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // 🟢 Campo de escritura
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _controller,
                  maxLines: 5,
                  maxLength: 110,
                  style: GoogleFonts.manrope(color: textColor),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: "Escribe cómo te sientes hoy...",
                    hintStyle: GoogleFonts.manrope(
                      color: isDark ? Colors.white38 : Colors.black54,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color.fromARGB(223, 71, 71, 71)
                        : Colors.grey.shade300,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // 🟣 Botón Guardar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _onSavePressed,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    "Guardar entrada",
                    style: GoogleFonts.manrope(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secundary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 🔹 Lista de entradas
              Expanded(
                child: FutureBuilder<List<DiaryEntry>>(
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
                          "Aún no has escrito en tu diario.\nEmpieza hoy mismo 💬",
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
                        final entry = resultadosData[index];
                        final formattedDate = DateFormat(
                          "yyyy-MM-dd HH:mm",
                        ).format(entry.fechaHora);

                        return Card(
                          color: isDark
                              ? const Color(0xFF1E1E1E)
                              : Colors.white,
                          elevation: 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.book_rounded,
                              color: isDark
                                  ? Colors
                                        .tealAccent
                                        .shade200 // ✅ Más visible en oscuro
                                  : AppColors
                                        .primary, // Color principal en claro
                              size: 28,
                            ),
                            title: Text(
                              entry.entry ?? "",
                              style: GoogleFonts.manrope(
                                color: textColor,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "📅 $formattedDate",
                                style: GoogleFonts.manrope(
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  fontSize: 13,
                                ),
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
