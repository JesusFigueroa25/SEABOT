import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:seabot/core/app_colors.dart';

class InfoDetailScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final bool isPdf;

  const InfoDetailScreen({
    super.key,
    required this.title,
    required this.assetPath,
    required this.isPdf,
  });

  @override
  State<InfoDetailScreen> createState() => _InfoDetailScreenState();
}

class _InfoDetailScreenState extends State<InfoDetailScreen> {
  String? localPath;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      if (widget.isPdf) {
        // 📄 Copiar PDF del asset a almacenamiento temporal
        final bytes = await rootBundle.load(widget.assetPath);
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/${widget.assetPath.split('/').last}");
        await file.writeAsBytes(bytes.buffer.asUint8List());
        setState(() {
          localPath = file.path;
          loading = false;
        });
      } else {
        // 🖼️ Imagen: no necesita escribir archivo
        setState(() => loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error al cargar archivo: $e",
            style: GoogleFonts.manrope(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
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
          title: Text(widget.title),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                color: isDark
                    ? const Color(0xFF121212)
                    : Colors.white, // fondo neutro
                child: widget.isPdf
                    ? PDFView(
                        filePath: localPath!,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: true,
                        pageFling: true,
                        nightMode: isDark,
                      )
                    : PhotoView(
                        imageProvider: AssetImage(widget.assetPath),
                        backgroundDecoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF121212)
                              : Colors.white,
                        ),
                        loadingBuilder: (context, event) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
      ),
    );
  }
}
