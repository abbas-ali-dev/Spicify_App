import 'package:Spicify/utilities/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: RepaintBoundary(
            child: const Text(
              "Spicify",
              style: AppTypography.appTitle,
            ),
          ),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
