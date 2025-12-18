import 'package:flutter/material.dart';
import 'package:seabot/core/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebResourceViewer extends StatefulWidget {
  final String url;
  final String title;

  const WebResourceViewer({super.key, required this.url, required this.title});

  @override
  State<WebResourceViewer> createState() => _WebResourceViewerState();
}

class _WebResourceViewerState extends State<WebResourceViewer> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    final finalUrl = _formatUrl(widget.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(finalUrl));
  }

  // 🟣 Detecta el tipo de enlace y ajusta para vista embebida
  String _formatUrl(String url) {
    if (url.contains("drive.google.com")) {
      // Convierte enlace de Drive a preview embebido
      final fileId = url.split('/d/')[1].split('/')[0];
      return "https://drive.google.com/file/d/$fileId/preview";
    } else if (url.endsWith(".pdf")) {
      // Usa visor de Google Docs para PDFs directos
      return "https://docs.google.com/gview?embedded=true&url=$url";
    } else {
      // Cualquier otro enlace normal
      return url;
    }
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
