import 'package:SecTunnel/models/fingerprint_config.dart';
import 'behavior_engine.dart';
import 'timing_patch.dart';
import 'scroll_model.dart';
import 'event_latency_patch.dart';

class BehaviorInjector {
  static String generate(FingerprintConfig config) {
    return '''
      (function() {
        try {
          ${BehaviorEngine.generate(config.sessionBoundSeed, config.hardwareConcurrency ?? 4, config.isMobile ?? false)}
          ${TimingPatch.jsCode}
          ${ScrollModel.jsCode}
          ${EventLatencyPatch.jsCode}
        } catch (e) {
          // Fail silently to prevent detection
        }
      })();
    ''';
  }
}
