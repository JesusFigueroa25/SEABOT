import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:seabot/core/app_colors.dart';

class PDFViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const PDFViewerScreen({super.key, required this.url, required this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  String? localPath;
  bool _isDownloading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _downloadAndSavePDF();
  }

  Future<void> _downloadAndSavePDF() async {
    try {
      setState(() {
        _isDownloading = true;
        _hasError = false;
      });

      final response = await http.get(Uri.parse(widget.url));

      if (response.statusCode != 200) {
        if (!mounted) return;
        setState(() => _hasError = true);
        return;
      }

      final bytes = response.bodyBytes;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/temp.pdf');
      await file.writeAsBytes(bytes);

      if (!mounted) return; // ✅ Evita el error si el widget ya fue eliminado
      setState(() {
        localPath = file.path;
        _isDownloading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isDownloading = false;
      });
    }
  }

  @override
  void dispose() {
    // 🔹 Aquí podrías cancelar timers o streams si los tuvieras.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextStyle = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: baseTextStyle.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: _isDownloading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Text(
                    "❌ Error al cargar el PDF. Verifica tu conexión.",
                    style: baseTextStyle.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : (localPath != null
                  ? PDFView(filePath: localPath!)
                  : Center(
                      child: Text(
                        "No se pudo cargar el archivo.",
                        style: baseTextStyle.bodyMedium,
                      ),
                    )),
    );
  }
}
