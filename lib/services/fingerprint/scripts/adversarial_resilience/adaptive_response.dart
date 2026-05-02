class AdaptiveResponse {
  static String getJS() {
    return '''
      window.AdaptiveResponse = (function() {
        return {
          applyEvasion: function(apiName, originalValue, isProbing) {
            if (!isProbing) return originalValue;
            
            if (window.console && window.console.debug) {
               // console.debug("[ADVERSARIAL] Adaptive response active for " + apiName);
            }
            
            // Type-aware micro variance to confuse multi-sample differential analysis
            if (typeof originalValue === 'number') {
               const variance = (Math.random() - 0.5) * 0.0001; // tiny undetectable delta
               return originalValue + variance;
            }
            
            if (Array.isArray(originalValue) && originalValue.length > 0 && typeof originalValue[0] === 'number') {
               return originalValue.map(v => v + (Math.random() - 0.5) * 0.00001);
            }
            
            // For strings or objects, we cannot easily vary without breaking
            // Instead, we might slightly delay returning
            return originalValue; 
          }
        };
      })();
    ''';
  }
}
