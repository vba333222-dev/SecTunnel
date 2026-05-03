// ignore_for_file: unused_local_variable
import 'self_test_engine.dart';

class SelfTestIntegrationExample {
  static void runSelfTest() {
    String jsPayload = SelfTestEngine.buildSelfTestPayload();
    
    // Example of injecting the self-test into a WebView or Puppeteer context:
    /*
      final result = await webView.evaluateJavascript(jsPayload);
      print("Self-Test Score: \${result['score']}");
      print("Consistency: \${result['breakdown']['consistency']}");
      print("Realism: \${result['breakdown']['realism']}");
      print("Stealth: \${result['breakdown']['stealth']}");
      
      for (var log in result['logs']) {
        print(log);
      }
    */
  }
}
