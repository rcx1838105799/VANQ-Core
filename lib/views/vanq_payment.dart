import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/features/vanq/vanq_api.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// VANQ Core embedded payment page: Xboard plan page inside a WebView.
///
/// The panel SPA exposes no per-plan deep link, so [planId] is accepted for
/// future use and the plan list page is always opened.
class VanqPaymentView extends ConsumerStatefulWidget {
  final int? planId;

  const VanqPaymentView({super.key, this.planId});

  @override
  ConsumerState<VanqPaymentView> createState() => _VanqPaymentViewState();
}

class _VanqPaymentViewState extends ConsumerState<VanqPaymentView> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  bool _refreshedOnSuccess = false;

  String get _initialUrl => '${VanqApi.baseUrl}/#/plan';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0B))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _loading = false);
            }
            if (!_refreshedOnSuccess && _looksLikePaymentDone(url)) {
              _refreshedOnSuccess = true;
              _refreshAccount();
            }
          },
          onProgress: (_) {},
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _loading = false;
                _error = error.description;
              });
            }
          },
          onSslAuthError: (error) {
            // The panel certificate chain is incomplete, so the platform
            // WebView would reject it. The panel is the user's own service,
            // so proceed past the error instead of showing a blank page.
            error.proceed();
          },
        ),
      )
      ..loadRequest(Uri.parse(_initialUrl));
  }

  bool _looksLikePaymentDone(String url) {
    final lower = url.toLowerCase();
    return lower.contains('success') ||
        lower.contains('/order') ||
        lower.contains('pay_success');
  }

  void _refreshAccount() {
    ref.read(vanqAccountProvider.notifier).refresh();
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _refreshAccount();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('套餐购买')),
        body: _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('加载失败: $_error'),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _retry, child: const Text('重试')),
                  ],
                ),
              )
            : Stack(
                children: [
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
      ),
    );
  }
}
