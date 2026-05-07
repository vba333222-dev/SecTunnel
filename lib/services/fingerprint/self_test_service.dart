import 'dart:async';
import 'dart:collection';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:sec_tunnel/models/fingerprint_config.dart';
import 'package:sec_tunnel/services/fingerprint/fingerprint_injector.dart';
import 'package:sec_tunnel/services/fingerprint/scripts/self_test/self_test_engine.dart';

class SelfTestResult {
  final int score;
  final Map<String, int> breakdown;
  final List<String> logs;
  final List<Map<String, dynamic>> results;

  SelfTestResult({
    required this.score,
    required this.breakdown,
    required this.logs,
    required this.results,
  });

  factory SelfTestResult.fromJson(Map<String, dynamic> json) {
    return SelfTestResult(
      score: json['score'] ?? 0,
      breakdown: Map<String, int>.from(json['breakdown'] ?? {}),
      logs: List<String>.from(json['logs'] ?? []),
      results: List<Map<String, dynamic>>.from(json['results'] ?? []),
    );
  }
}

class SelfTestService {
  HeadlessInAppWebView? _headlessWebView;

  Future<SelfTestResult> runFullAudit(FingerprintConfig config) async {
    final completer = Completer<SelfTestResult>();
    
    final injector = FingerprintInjector(config);
    final fingerprintScript = injector.generateInjectionScript();
    final testPayload = SelfTestEngine.buildSelfTestPayload();

    _headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("about:blank")),
      initialUserScripts: UnmodifiableListView([
        UserScript(
          source: fingerprintScript,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      ]),
      onLoadStop: (controller, url) async {
        // Wait a bit for all async mocks to settle
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          final dynamic result = await controller.evaluateJavascript(source: testPayload);
          if (result != null) {
            completer.complete(SelfTestResult.fromJson(Map<String, dynamic>.from(result)));
          } else {
            completer.completeError("Self-test returned null");
          }
        } catch (e) {
          completer.completeError("Execution failed: $e");
        } finally {
          _disposeHeadless();
        }
      },
    );

    await _headlessWebView?.run();
    return completer.future;
  }

  void _disposeHeadless() {
    _headlessWebView?.dispose();
    _headlessWebView = null;
  }
}
