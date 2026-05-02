class ConnectionPatch {
  static String getJS() {
    return '''
      try {
        if (!navigator.connection) return;

        // NetworkInformation API spoofing
        const newConnection = Object.create(NetworkInformation.prototype);
        
        // Reasonable desktop default values
        Object.defineProperty(newConnection, 'downlink', { value: 10.0, enumerable: true });
        Object.defineProperty(newConnection, 'effectiveType', { value: '4g', enumerable: true });
        Object.defineProperty(newConnection, 'rtt', { value: 50, enumerable: true });
        Object.defineProperty(newConnection, 'saveData', { value: false, enumerable: true });
        
        // Optionally bind events if needed
        newConnection.onchange = null;
        
        const connGetter = function get() { return newConnection; };
        
        Object.defineProperty(Navigator.prototype, 'connection', {
          get: connGetter,
          enumerable: true,
          configurable: true
        });

        if (window.FunctionCloaker) {
          window.FunctionCloaker.cloak(connGetter, function get() { [native code] });
        }
      } catch(e) {}
    ''';
  }
}
