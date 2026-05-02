import 'scoring_system.dart';
import 'tests/cross_context_test.dart';
import 'tests/prototype_integrity_test.dart';
import 'tests/function_cloaking_test.dart';
import 'tests/timing_analysis_test.dart';
import 'tests/canvas_stability_test.dart';
import 'tests/webgl_consistency_test.dart';
import 'tests/audio_fingerprint_test.dart';
import 'tests/feature_presence_test.dart';
import 'tests/environment_coherence_test.dart';
import 'tests/statistical_anomaly_test.dart';
import 'tests/leak_detection_test.dart';

class SelfTestEngine {
  static String buildSelfTestPayload() {
    return '''
      (async function runFullAudit() {
        const results = [];
        const logs = [];
        let consistencyScore = 100;
        let realismScore = 100;
        let stealthScore = 100;

        function report(name, pass, message, category, scoreImpact = 10) {
          results.push({ name, pass, message });
          if (!pass) {
            logs.push(`[SELFTEST] FAIL: \${message}`);
            if (category === 'consistency') consistencyScore = Math.max(0, consistencyScore - scoreImpact);
            if (category === 'realism') realismScore = Math.max(0, realismScore - scoreImpact);
            if (category === 'stealth') stealthScore = Math.max(0, stealthScore - scoreImpact);
          } else {
            logs.push(`[SELFTEST] PASS: \${name}`);
          }
        }

        // Run cross-context tests
        \${${CrossContextTest.getJS()}}
        
        // Run prototype integrity tests
        \${${PrototypeIntegrityTest.getJS()}}
        
        // Run function cloaking tests
        \${${FunctionCloakingTest.getJS()}}
        
        // Run timing analysis
        \${await ${TimingAnalysisTest.getJS()}}
        
        // Run canvas stability
        \${${CanvasStabilityTest.getJS()}}
        
        // Run WebGL consistency
        \${${WebGLConsistencyTest.getJS()}}
        
        // Run audio fingerprint test
        \${await ${AudioFingerprintTest.getJS()}}
        
        // Run feature presence
        \${${FeaturePresenceTest.getJS()}}
        
        // Run environment coherence
        \${${EnvironmentCoherenceTest.getJS()}}
        
        // Run statistical anomaly
        \${${StatisticalAnomalyTest.getJS()}}
        
        // Run leak detection
        \${await ${LeakDetectionTest.getJS()}}

        \${${ScoringSystem.getJS()}}

        const finalScore = calculateFinalScore(consistencyScore, realismScore, stealthScore);

        return {
          score: finalScore,
          breakdown: { consistency: consistencyScore, realism: realismScore, stealth: stealthScore },
          logs: logs,
          results: results
        };
      })();
    ''';
  }
}
