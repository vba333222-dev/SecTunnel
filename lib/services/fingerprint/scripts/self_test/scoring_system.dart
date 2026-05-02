class ScoringSystem {
  static String getJS() {
    return '''
      function calculateFinalScore(consistencyScore, realismScore, stealthScore) {
        // AntiDetectScore (0-100)
        // Stealth is weighted heavily because leaks are fatal.
        // Consistency prevents fingerprint mismatches across contexts.
        // Realism measures statistical belivability and timing.
        
        const weightConsistency = 0.35;
        const weightRealism = 0.25;
        const weightStealth = 0.40;
        
        const finalScore = (consistencyScore * weightConsistency) + 
                           (realismScore * weightRealism) + 
                           (stealthScore * weightStealth);
                           
        return Math.round(finalScore);
      }
    ''';
  }
}
