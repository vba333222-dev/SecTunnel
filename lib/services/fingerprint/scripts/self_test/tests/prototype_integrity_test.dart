class PrototypeIntegrityTest {
  static String getJS() {
    return '''
      try {
        const navProto = Object.getPrototypeOf(navigator);
        if (navProto !== Navigator.prototype) {
          report('Prototype Integrity', false, 'navigator.__proto__ !== Navigator.prototype', 'stealth', 50);
        } else {
          // Check descriptor equality
          const desc = Object.getOwnPropertyDescriptor(Navigator.prototype, 'userAgent');
          if (!desc || typeof desc.get !== 'function') {
            report('Prototype Integrity', false, 'Invalid userAgent descriptor', 'stealth', 30);
          } else {
            report('Prototype Integrity', true, 'Prototype chain intact', 'stealth');
          }
        }
        
        if (!(navigator instanceof Navigator)) {
          report('Instanceof Behavior', false, 'navigator is not instance of Navigator', 'stealth', 40);
        } else {
          report('Instanceof Behavior', true, 'Instanceof behavior intact', 'stealth');
        }
      } catch(e) {
        report('Prototype Integrity', false, `Error: \${e.message}`, 'stealth', 20);
      }
    ''';
  }
}
