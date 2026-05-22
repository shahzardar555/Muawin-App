import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SafepayWebViewScreen extends StatefulWidget {
  const SafepayWebViewScreen({
    super.key,
    required this.checkoutUrl,
    required this.onPaymentSuccess,
    required this.onPaymentFailed,
  });

  final String checkoutUrl;
  final VoidCallback onPaymentSuccess;
  final VoidCallback onPaymentFailed;

  @override
  State<SafepayWebViewScreen> createState() => _SafepayWebViewScreenState();
}

class _SafepayWebViewScreenState extends State<SafepayWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            debugPrint('Safepay loading: $url');
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            debugPrint('Safepay loaded: $url');
            if (url.contains('success') ||
                url.contains('paid') ||
                url.contains('complete')) {
              widget.onPaymentSuccess();
              Navigator.pop(context, true);
            } else if (url.contains('cancel') ||
                url.contains('failed') ||
                url.contains('error')) {
              widget.onPaymentFailed();
              Navigator.pop(context, false);
            }
          },
          onNavigationRequest: (request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF047A62),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          'Secure Payment',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Safepay',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF047A62),
              ),
            ),
        ],
      ),
    );
  }
}
