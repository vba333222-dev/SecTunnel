import 'event_loop_engine.dart';
import 'background_activity.dart';
import 'system_rhythm.dart';
import 'passive_defense.dart';

class PassiveIntegration {
  static String getInjectionScript() {
    return '''
      // Passive Signal Stealth & Environmental Integration
      // Replaces deterministic spoofing with an integrated, environment-aware passive signature.
      
      \${${EventLoopEngine.getJS()}}
      \${${BackgroundActivity.getJS()}}
      \${${SystemRhythm.getJS()}}
      \${${PassiveDefense.getJS()}}
      
      // Override standard timing layers here with PassiveDefense.applyTimingDefense(t, originalValue)
      (function() {
         const originalRAF = window.requestAnimationFrame;
         if (originalRAF && window.PassiveDefense) {
            const newRAF = function(callback) {
               return originalRAF.call(this, function(time) {
                  const t = performance.now();
                  const delay = window.PassiveDefense.applyFrameDefense(t);
                  if (delay > 0) {
                     const end = performance.now() + delay;
                     while(performance.now() < end) {}
                  }
                  callback(time);
               });
            };
            window.requestAnimationFrame = newRAF;
            if (window.FunctionCloaker) {
              window.FunctionCloaker.cloak(newRAF, originalRAF);
            }
         }
      })();
    ''';
  }
}
