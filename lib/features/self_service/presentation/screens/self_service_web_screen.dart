import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/widgets/app_drawer.dart';

class SelfServiceWebScreen extends StatefulWidget {
  static const String nativePortalUrl =
      'https://erp.alsharqiholding.qa/self/service';

  final String initialUrl;

  const SelfServiceWebScreen({
    super.key,
    this.initialUrl = nativePortalUrl,
  });

  @override
  State<SelfServiceWebScreen> createState() => _SelfServiceWebScreenState();
}

class _SelfServiceWebScreenState extends State<SelfServiceWebScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final WebViewController _controller;
  int _progress = 0;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _pageError = null);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _progress = 100);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (kDebugMode) {
              debugPrint(
                '[SelfService] Portal error ${error.errorCode}: ${error.description}',
              );
            }
            if (mounted) {
              setState(() => _pageError = error.description);
            }
          },
          // Match the native WebViewClient: keep every redirect and page in
          // this WebView so the portal's authenticated session is preserved.
          onNavigationRequest: (_) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));

    if (Platform.isAndroid &&
        _controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController)
          .setOnShowFileSelector(_selectFiles);
    }
  }

  Future<List<String>> _selectFiles(FileSelectorParams params) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: params.mode == FileSelectorMode.openMultiple,
      type: FileType.any,
    );
    if (result == null) return const [];
    return result.files.map((file) => file.path).whereType<String>().toList();
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else if (mounted) {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            _buildHeader(),
            if (_progress < 100 && _pageError == null)
              LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                color: AppColors.primary,
              ),
            Expanded(
              child: _pageError == null
                  ? WebViewWidget(controller: _controller)
                  : _buildErrorState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Unable to load Self Service Portal. Please check your internet connection.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _pageError = null;
                  _progress = 0;
                });
                _controller.reload();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.splashGradientStart,
            AppColors.splashGradientMiddle,
            AppColors.splashGradientEnd,
          ],
          stops: [0, 0.5, 1],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 16,
                child: IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
              ),
              const Text(
                 'SELF SERVICE ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.68,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
