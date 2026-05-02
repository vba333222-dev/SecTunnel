class FunctionCloakingTest {
  static String getJS() {
    return '''
      try {
        const toStr = Function.prototype.toString;
        
        // Test navigator.plugins.item
        if (navigator.plugins && navigator.plugins.item) {
          const str = toStr.call(navigator.plugins.item);
          if (str !== "function item() { [native code] }") {
            report('Function Cloaking', false, `navigator.plugins.item.toString() returned injected code`, 'stealth', 50);
          } else {
            report('Function Cloaking', true, 'Native functions correctly cloaked', 'stealth');
          }
        }
        
        // Test patched getter
        const uaGetter = Object.getOwnPropertyDescriptor(Navigator.prototype, 'userAgent').get;
        if (uaGetter && toStr.call(uaGetter) !== "function get userAgent() { [native code] }") {
          report('Getter Cloaking', false, 'Patched getters are leaking source', 'stealth', 50);
        } else {
          report('Getter Cloaking', true, 'Patched getters correctly cloaked', 'stealth');
        }
      } catch(e) {
        report('Function Cloaking', false, `Error: \${e.message}`, 'stealth', 20);
      }
    ''';
  }
}
