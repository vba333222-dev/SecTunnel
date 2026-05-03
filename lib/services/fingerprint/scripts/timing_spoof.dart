import 'package:sec_tunnel/models/fingerprint_config.dart';

class TimingSpoof {
  static String generate(FingerprintConfig config) {
    return '''
      // 6. TIMING IMPERFECTION
      (function() {
        const originalPerformanceNow = Performance.prototype.now;
        const originalDateNow = Date.now;

        EmulationEngine.patchMethod(Performance.prototype, 'now', function(...args) {
          const realTime = originalPerformanceNow.apply(this, args);
          return _imperfectionTimeDrift(realTime, _timingSeed);
        });

        EmulationEngine.patchMethod(Date, 'now', function(...args) {
          const realTime = originalDateNow.apply(this, args);
          return Math.floor(_imperfectionTimeDrift(realTime, _timingSeed));
        });
      })();
''';
  }
}
