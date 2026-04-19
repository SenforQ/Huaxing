import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/huaxing_theme.dart';

/// 顶部导航栏下方全宽 WebView：高度 = 屏幕高度 − 状态栏 − 导航栏，
/// WebView 纵向起点位于状态栏 + 导航栏之下（由 [Scaffold] body 保证）。
/// 左上角、右上角圆角 20。
class LegalWebViewPage extends StatefulWidget {
  const LegalWebViewPage({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<LegalWebViewPage> createState() => _LegalWebViewPageState();
}

class _LegalWebViewPageState extends State<LegalWebViewPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final uri = Uri.parse(widget.url);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            setState(() => _loading = true);
          },
          onPageFinished: (_) {
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double statusBarHeight = MediaQuery.paddingOf(context).top;
    const double appBarHeight = kToolbarHeight;
    final double computedWebHeight =
        screenSize.height - statusBarHeight - appBarHeight;

    return Scaffold(
      backgroundColor: kBackgroundBlack,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double h = constraints.maxHeight <= computedWebHeight
              ? constraints.maxHeight
              : computedWebHeight;
          final double w = constraints.maxWidth <= screenSize.width
              ? constraints.maxWidth
              : screenSize.width;
          return SizedBox(
            width: w,
            height: h,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    Container(
                      color: kBackgroundBlack.withOpacity(0.85),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: kAccentYellow,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
